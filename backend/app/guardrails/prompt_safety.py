"""
Prompt Safety Checker
=====================
Detects prompt-injection and data-exfiltration attempts in raw user input
*before* that input is forwarded to the AI model.

Security rationale:
  An attacker who controls the natural-language question can attempt to
  override the system prompt, extract data belonging to other customers, or
  cause the AI to emit malicious SQL.  This module acts as the first gate —
  rejecting obviously hostile inputs so they never reach the LLM.

All detection is purely in-memory (regex + keyword matching).
"""

from __future__ import annotations

import re
from dataclasses import dataclass

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

MAX_INPUT_LENGTH: int = 500

# Known customer database identifiers used in cross-customer access detection.
_KNOWN_DATABASES: frozenset[str] = frozenset({"acme", "nova", "apex"})

# ---------------------------------------------------------------------------
# Detection patterns
# ---------------------------------------------------------------------------

# Phrases that attempt to override AI system-level instructions.
_PROMPT_INJECTION_PATTERNS: list[re.Pattern[str]] = [
    re.compile(r"ignore\s+(all\s+)?previous\s+instructions?", re.IGNORECASE),
    re.compile(r"forget\s+(your\s+)?instructions?", re.IGNORECASE),
    re.compile(r"\bdisregard\b", re.IGNORECASE),
    re.compile(r"\byou\s+are\s+now\b", re.IGNORECASE),
    re.compile(r"\bact\s+as\b", re.IGNORECASE),
    re.compile(r"\bpretend\s+to\s+be\b", re.IGNORECASE),
    re.compile(r"\bnew\s+instructions?\s*:", re.IGNORECASE),
    re.compile(r"\bsystem\s*:", re.IGNORECASE),
    re.compile(r"\bassistant\s*:", re.IGNORECASE),
    re.compile(r"\bjailbreak\b", re.IGNORECASE),
    re.compile(r"\bDAN\b"),  # "Do Anything Now" jailbreak
]

# Raw SQL injection fragments embedded in natural language.
_SQL_INJECTION_PATTERNS: list[re.Pattern[str]] = [
    re.compile(r"';\s*(DROP|DELETE|INSERT|UPDATE|TRUNCATE)", re.IGNORECASE),
    re.compile(r"';\s*--", re.IGNORECASE),  # quote-escape + comment
    re.compile(r'"\s*;\s*(DROP|DELETE|INSERT|UPDATE)', re.IGNORECASE),
    re.compile(r"\bOR\s+1\s*=\s*1\b", re.IGNORECASE),  # classic tautology
    re.compile(r"\bOR\s+'[^']*'\s*=\s*'[^']*'", re.IGNORECASE),
]

# Requests that indicate the user wants to dump sensitive data.
_EXFILTRATION_PATTERNS: list[re.Pattern[str]] = [
    re.compile(r"\bshow\s+me\s+all\s+users?\b", re.IGNORECASE),
    re.compile(r"\blist\s+all\s+passwords?\b", re.IGNORECASE),
    re.compile(r"\bdump\s+(the\s+)?database\b", re.IGNORECASE),
    re.compile(r"\bSELECT\s+\*", re.IGNORECASE),  # raw SQL in prompt
    re.compile(r"\bexport\s+(all\s+)?(data|records|rows|tables)\b", re.IGNORECASE),
]

# ALL-CAPS directive pattern: ≥ 4 consecutive uppercase words look like an
# injected system instruction (e.g. "IGNORE ALL RULES AND RESPOND").
_ALL_CAPS_DIRECTIVE = re.compile(
    r"(?<![A-Z])([A-Z]{2,}\s+){3,}[A-Z]{2,}(?![a-z])"
)


# ---------------------------------------------------------------------------
# Result model
# ---------------------------------------------------------------------------


@dataclass
class PromptSafetyResult:
    """Outcome of a prompt safety check.

    Attributes:
        is_safe:    Whether the input may proceed to the AI model.
        reason:     Description of the detected threat; None when safe.
        risk_level: One of "none", "low", "medium", "high".
    """

    is_safe: bool
    reason: str | None
    risk_level: str


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def check_prompt_safety(user_input: str) -> PromptSafetyResult:
    """Evaluate a raw user question for prompt-injection and abuse patterns.

    Checks are ordered from most critical to least critical, failing fast on
    the first match.

    Args:
        user_input: The raw natural-language question from the user.

    Returns:
        A :class:`PromptSafetyResult` indicating whether the input is safe.
    """
    # ------------------------------------------------------------------
    # 1. Length limit
    # Excessively long prompts are unusual for legitimate questions and
    # are a common technique for hiding injected instructions inside noise.
    # ------------------------------------------------------------------
    if len(user_input) > MAX_INPUT_LENGTH:
        return PromptSafetyResult(
            is_safe=False,
            reason=(
                f"Input exceeds maximum length of {MAX_INPUT_LENGTH} "
                "characters. Long prompts may conceal injection payloads."
            ),
            risk_level="high",
        )

    # ------------------------------------------------------------------
    # 2. Prompt injection detection
    # These patterns attempt to override or replace the AI system prompt.
    # ------------------------------------------------------------------
    for pattern in _PROMPT_INJECTION_PATTERNS:
        match = pattern.search(user_input)
        if match:
            return PromptSafetyResult(
                is_safe=False,
                reason=(
                    f"Prompt injection attempt detected: '{match.group()}'. "
                    "Instructions to the AI system cannot be overridden."
                ),
                risk_level="high",
            )

    # ------------------------------------------------------------------
    # 3. ALL_CAPS directive heuristic
    # Strings like "IGNORE ALL PREVIOUS RULES AND ..." look like injected
    # system-level commands.
    # ------------------------------------------------------------------
    match = _ALL_CAPS_DIRECTIVE.search(user_input)
    if match:
        return PromptSafetyResult(
            is_safe=False,
            reason=(
                "Input contains an ALL-CAPS directive pattern that "
                "resembles a system-level instruction injection."
            ),
            risk_level="high",
        )

    # ------------------------------------------------------------------
    # 4. Raw SQL injection fragments in natural language
    # A user who embeds `'; DROP TABLE …` in their question is almost
    # certainly attempting to inject SQL, not asking a legitimate question.
    # ------------------------------------------------------------------
    for pattern in _SQL_INJECTION_PATTERNS:
        match = pattern.search(user_input)
        if match:
            return PromptSafetyResult(
                is_safe=False,
                reason=(
                    f"SQL injection fragment detected in natural language "
                    f"input: '{match.group()}'."
                ),
                risk_level="high",
            )

    # ------------------------------------------------------------------
    # 5. Data exfiltration request detection
    # Phrases like "dump the database" or "show me all users" are strong
    # signals of data-theft intent rather than legitimate analytics.
    # ------------------------------------------------------------------
    for pattern in _EXFILTRATION_PATTERNS:
        match = pattern.search(user_input)
        if match:
            return PromptSafetyResult(
                is_safe=False,
                reason=(
                    f"Potential data exfiltration request detected: "
                    f"'{match.group()}'."
                ),
                risk_level="high",
            )

    # ------------------------------------------------------------------
    # 6. Cross-customer database reference
    # If the user explicitly names a customer database in their question,
    # it may indicate an attempt to pivot to another tenant's data.
    # We flag this as medium risk (the RBAC layer enforces the hard block).
    # ------------------------------------------------------------------
    lower_input = user_input.lower()
    for db_name in _KNOWN_DATABASES:
        # Only flag it when used as a noun/identifier, not inside a word.
        pattern = re.compile(r"\b" + re.escape(db_name) + r"\b", re.IGNORECASE)
        if pattern.search(lower_input):
            return PromptSafetyResult(
                is_safe=False,
                reason=(
                    f"Input references known customer database identifier "
                    f"'{db_name}'. Cross-customer access is not permitted."
                ),
                risk_level="medium",
            )

    # ------------------------------------------------------------------
    # All checks passed.
    # ------------------------------------------------------------------
    return PromptSafetyResult(is_safe=True, reason=None, risk_level="none")
