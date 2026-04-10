#!/usr/bin/env bash
# ============================================================
# InRiver-DataCase: Teardown Script
# Cleanly removes PoC resources while optionally preserving
# shared/pre-existing resources (Log Analytics, App Insights,
# Storage, AI Foundry).
#
# Usage: ./scripts/teardown.sh -g <resource-group> [options]
# ============================================================
set -euo pipefail

# ── Colours & Symbols ──────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Defaults ───────────────────────────────────────────────
RESOURCE_GROUP=""
ENV_NAME="dev"
KEEP_SHARED=true
YES=false

# ── Usage ──────────────────────────────────────────────────
usage() {
    cat <<EOF
${BOLD}InRiver-DataCase — Teardown${NC}

Usage: $(basename "$0") [OPTIONS]

Required:
  -g, --resource-group NAME   Target Azure resource group

Options:
  -e, --env ENV               Environment name (default: dev)
  --keep-shared               Keep shared resources: Log Analytics, App Insights,
                              Storage, AI Foundry (default: true)
  --no-keep-shared            Remove ALL resources in the resource group
  -y, --yes                   Skip confirmation prompt
  -h, --help                  Show this help message

Examples:
  $(basename "$0") -g RG-InRiver                  # Remove PoC resources, keep shared
  $(basename "$0") -g RG-InRiver --no-keep-shared  # Remove everything
  $(basename "$0") -g RG-InRiver -y                # No confirmation prompt
EOF
    exit 0
}

# ── Parse Arguments ────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        -g|--resource-group) RESOURCE_GROUP="$2"; shift 2 ;;
        -e|--env)            ENV_NAME="$2"; shift 2 ;;
        --keep-shared)       KEEP_SHARED=true; shift ;;
        --no-keep-shared)    KEEP_SHARED=false; shift ;;
        -y|--yes)            YES=true; shift ;;
        -h|--help)           usage ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}" >&2
            usage
            ;;
    esac
done

if [[ -z "${RESOURCE_GROUP}" ]]; then
    echo -e "${RED}Error: --resource-group (-g) is required.${NC}" >&2
    usage
fi

RESOURCE_PREFIX="inriver-${ENV_NAME}"

# ── Pre-checks ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════${NC}"
echo -e "${BOLD} InRiver-DataCase — Teardown${NC}"
echo -e " Resource Group: ${BOLD}${RESOURCE_GROUP}${NC}"
echo -e " Environment:    ${BOLD}${ENV_NAME}${NC}"
echo -e " Keep shared:    ${BOLD}${KEEP_SHARED}${NC}"
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════${NC}"
echo ""

if ! az account show &>/dev/null; then
    echo -e "${RED}Error: Not logged in to Azure. Run: az login${NC}"
    exit 1
fi

if ! az group show --name "${RESOURCE_GROUP}" &>/dev/null; then
    echo -e "${YELLOW}Resource group '${RESOURCE_GROUP}' does not exist. Nothing to tear down.${NC}"
    exit 0
fi

# ── Full teardown (no-keep-shared) ─────────────────────────
if [[ "${KEEP_SHARED}" == "false" ]]; then
    echo -e "${RED}${BOLD}WARNING: This will DELETE the entire resource group '${RESOURCE_GROUP}' and ALL resources within it.${NC}"
    echo ""

    if [[ "${YES}" != "true" ]]; then
        echo -ne "Type the resource group name to confirm: "
        read -r confirmation
        if [[ "${confirmation}" != "${RESOURCE_GROUP}" ]]; then
            echo -e "${YELLOW}Aborted. Name did not match.${NC}"
            exit 1
        fi
    fi

    echo -e "${BLUE}Deleting resource group ${BOLD}${RESOURCE_GROUP}${NC}${BLUE}...${NC}"
    az group delete --name "${RESOURCE_GROUP}" --yes --no-wait
    echo -e "${GREEN}Resource group deletion initiated (async). It may take a few minutes to complete.${NC}"
    exit 0
fi

# ── Selective teardown (keep-shared, default) ──────────────
echo -e "${BLUE}Scanning for InRiver PoC resources (prefix: ${BOLD}${RESOURCE_PREFIX}${NC}${BLUE})...${NC}"
echo ""

# Resources to DELETE (PoC-specific, identified by prefix)
declare -a DELETE_TARGETS=()
declare -a DELETE_DESCRIPTIONS=()

# Helper: find resources matching our prefix and queue for deletion
scan_resource() {
    local type_label="$1"
    local resource_id="$2"
    local resource_name="$3"

    if [[ -z "$resource_id" ]]; then
        return
    fi

    DELETE_TARGETS+=("$resource_id")
    DELETE_DESCRIPTIONS+=("$type_label: $resource_name")
}

# Container Apps (delete first — depend on other resources)
while IFS=$'\t' read -r id name; do
    [[ -z "$id" ]] && continue
    scan_resource "Container App" "$id" "$name"
done < <(az containerapp list -g "${RESOURCE_GROUP}" --query "[?starts_with(name, '${RESOURCE_PREFIX}')].[id, name]" -o tsv 2>/dev/null || true)

# Container Apps Environment
while IFS=$'\t' read -r id name; do
    [[ -z "$id" ]] && continue
    scan_resource "Container Apps Environment" "$id" "$name"
done < <(az containerapp env list -g "${RESOURCE_GROUP}" --query "[?starts_with(name, '${RESOURCE_PREFIX}')].[id, name]" -o tsv 2>/dev/null || true)

# Key Vault
while IFS=$'\t' read -r id name; do
    [[ -z "$id" ]] && continue
    scan_resource "Key Vault" "$id" "$name"
done < <(az keyvault list -g "${RESOURCE_GROUP}" --query "[?starts_with(name, '${RESOURCE_PREFIX//-/}')].[id, name]" -o tsv 2>/dev/null || true)

# SQL Server (cascades to databases)
while IFS=$'\t' read -r id name; do
    [[ -z "$id" ]] && continue
    scan_resource "SQL Server" "$id" "$name"
done < <(az sql server list -g "${RESOURCE_GROUP}" --query "[?starts_with(name, '${RESOURCE_PREFIX}')].[id, name]" -o tsv 2>/dev/null || true)

# Container Registry
while IFS=$'\t' read -r id name; do
    [[ -z "$id" ]] && continue
    scan_resource "Container Registry" "$id" "$name"
done < <(az acr list -g "${RESOURCE_GROUP}" --query "[?starts_with(name, '${RESOURCE_PREFIX//-/}')].[id, name]" -o tsv 2>/dev/null || true)

# Managed Identity
while IFS=$'\t' read -r id name; do
    [[ -z "$id" ]] && continue
    scan_resource "Managed Identity" "$id" "$name"
done < <(az identity list -g "${RESOURCE_GROUP}" --query "[?starts_with(name, '${RESOURCE_PREFIX}')].[id, name]" -o tsv 2>/dev/null || true)

# ── Display plan ───────────────────────────────────────────
if [[ ${#DELETE_TARGETS[@]} -eq 0 ]]; then
    echo -e "${GREEN}No InRiver PoC resources found with prefix '${RESOURCE_PREFIX}'. Nothing to delete.${NC}"
    exit 0
fi

echo -e "${BOLD}Resources to DELETE:${NC}"
for i in "${!DELETE_DESCRIPTIONS[@]}"; do
    echo -e "  ${RED}✖${NC}  ${DELETE_DESCRIPTIONS[$i]}"
done

echo ""
echo -e "${BOLD}Resources to KEEP (shared):${NC}"

# Show what's being preserved
kept=0
for label_cmd in \
    "Log Analytics Workspace|az monitor log-analytics workspace list -g ${RESOURCE_GROUP} --query [].name -o tsv" \
    "Application Insights|az monitor app-insights component list -g ${RESOURCE_GROUP} --query [].name -o tsv" \
    "Storage Account|az storage account list -g ${RESOURCE_GROUP} --query [].name -o tsv" \
    "AI Foundry Project|az ml workspace list -g ${RESOURCE_GROUP} --query [?kind==\\'Project\\'].name -o tsv" \
    "AI Services|az cognitiveservices account list -g ${RESOURCE_GROUP} --query [].name -o tsv"; do
    label="${label_cmd%%|*}"
    cmd="${label_cmd##*|}"
    names=$(eval "$cmd" 2>/dev/null || true)
    if [[ -n "$names" ]]; then
        while IFS= read -r name; do
            echo -e "  ${GREEN}✔${NC}  ${label}: ${name}"
            kept=$((kept + 1))
        done <<< "$names"
    fi
done

if [[ "${kept}" -eq 0 ]]; then
    echo -e "  ${YELLOW}(no shared resources found)${NC}"
fi

echo ""
echo -e "${YELLOW}${BOLD}${#DELETE_TARGETS[@]} resource(s) will be deleted.${NC}"

# ── Confirm ────────────────────────────────────────────────
if [[ "${YES}" != "true" ]]; then
    echo -ne "Proceed? [y/N] "
    read -r answer
    if [[ "${answer}" != "y" && "${answer}" != "Y" ]]; then
        echo -e "${YELLOW}Aborted.${NC}"
        exit 1
    fi
fi

# ── Execute Deletions ──────────────────────────────────────
echo ""
echo -e "${BLUE}Deleting resources...${NC}"

failed=0
for i in "${!DELETE_TARGETS[@]}"; do
    rid="${DELETE_TARGETS[$i]}"
    desc="${DELETE_DESCRIPTIONS[$i]}"
    echo -ne "  Deleting ${desc}... "

    if az resource delete --ids "$rid" --no-wait 2>/dev/null; then
        echo -e "${GREEN}queued${NC}"
    else
        echo -e "${RED}failed${NC}"
        failed=$((failed + 1))
    fi
done

echo ""
if [[ "${failed}" -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}Teardown complete.${NC} All ${#DELETE_TARGETS[@]} PoC resource(s) queued for deletion."
else
    echo -e "${YELLOW}${BOLD}Teardown finished with ${failed} error(s).${NC} Some resources may need manual cleanup."
fi

echo -e "${BLUE}Tip: Run ${BOLD}az resource list -g ${RESOURCE_GROUP} -o table${NC}${BLUE} to verify remaining resources.${NC}"
