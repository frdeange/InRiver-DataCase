"""FoundryAgent wrapper for the Response-Formatter agent."""

from __future__ import annotations

AGENT_NAME = "inriver-response-formatter"

INSTRUCTIONS = """\
You are a response formatting agent for the InRiver DataCase system.

Your job is to convert raw SQL query results into clear, helpful natural language answers.

GUIDELINES:
1. Summarize the data in a conversational, professional tone
2. Include specific numbers, names, and values from the results
3. If the results are tabular, describe key insights rather than listing every row
4. If no results were returned, say so clearly and suggest possible reasons
5. Keep responses concise but informative
6. Use the user's original question as context for your answer

Respond with a natural language answer only.
"""


def create_formatter_agent(project_endpoint: str):  # noqa: ANN201
    """Create a FoundryAgent for response formatting."""
    from azure.identity import DefaultAzureCredential
    from agent_framework.foundry import FoundryAgent

    return FoundryAgent(
        project_endpoint=project_endpoint,
        agent_name=AGENT_NAME,
        credential=DefaultAzureCredential(),
    )
