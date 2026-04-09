# InRiver DataCase — Infrastructure

Bicep templates for deploying the InRiver DataCase PoC environment to **RG-InRiver** on Azure.

## Resources Deployed

| Resource | Module | Notes |
|---|---|---|
| Azure Key Vault | `modules/keyvault.bicep` | Standard SKU, RBAC auth, stores all secrets |
| SQL Server (logical) | `modules/sql.bicep` | Azure SQL, TLS 1.2, Azure services firewall |
| 3× Azure SQL Databases | `modules/sql.bicep` | `db-acme`, `db-nova`, `db-apex` — serverless GP_S_Gen5_1, auto-pause 60 min |
| Container Apps Environment | `modules/container-apps.bicep` | Consumption plan, linked Log Analytics workspace |
| Backend Container App | `modules/container-apps.bicep` | FastAPI placeholder image, external HTTPS ingress |
| Frontend Container App | `modules/container-apps.bicep` | React/Vite placeholder image, external HTTPS ingress |
| User-Assigned Managed Identity | `modules/container-apps.bicep` | Granted Key Vault Secrets User role |

---

## Prerequisites

1. **Azure CLI** installed and authenticated:
   ```bash
   az login
   az account set --subscription <YOUR_SUBSCRIPTION_ID>
   ```

2. **Bicep CLI** (bundled with Azure CLI — no separate install needed):
   ```bash
   az bicep version
   ```

3. **Resource group** `RG-InRiver` already exists with:
   - Azure AI Foundry (GPT-4.1 deployed)
   - Application Insights + Log Analytics workspace
   - Storage Account

---

## Step 1 — Create Parameters File

Copy the example and fill in your values:

```bash
cp infra/parameters.demo.json.example infra/parameters.demo.json
```

Edit `infra/parameters.demo.json`:

| Parameter | Where to find it |
|---|---|
| `sqlAdminPassword` | Choose a strong password (≥12 chars, upper/lower/digit/symbol) |
| `appInsightsConnectionString` | Azure Portal → Application Insights resource → **Overview** → *Connection String* |
| `openAiEndpoint` | Azure AI Foundry portal → your project → **Deployments** → endpoint URL |
| `openAiKey` | Azure AI Foundry portal → your project → **Deployments** → API keys |

> ⚠️ **Never commit** `parameters.demo.json` — it contains secrets. It is listed in `.gitignore`.

---

## Step 2 — Preview Changes (optional)

```bash
chmod +x infra/deploy.sh
./infra/deploy.sh --what-if
```

This runs `az deployment group create --what-if` and shows you what will be created without actually deploying.

---

## Step 3 — Deploy

```bash
./infra/deploy.sh
```

The script targets resource group `RG-InRiver` and streams deployment progress. Typical deploy time: **5–10 minutes**.

---

## Step 4 — Post-Deployment: Database Initialization

After the SQL databases are provisioned, run the schema and seed scripts:

```bash
# Get the SQL Server FQDN from deployment outputs
SQL_FQDN=$(az deployment group show \
  --resource-group RG-InRiver \
  --name <deployment-name> \
  --query properties.outputs.sqlServerFqdn.value -o tsv)

# Run init script against each database (requires sqlcmd or pyodbc)
for DB in db-acme db-nova db-apex; do
  sqlcmd -S "${SQL_FQDN}" -d "${DB}" -U sqladmin -P '<password>' \
    -i database/init-schema.sql
done
```

After schema init, create the read-only `ai_agent_ro` SQL login in each database and update the Key Vault secrets (`sql-connstr-acme`, `sql-connstr-nova`, `sql-connstr-apex`) to use that login instead of the admin credentials.

---

## Step 5 — Post-Deployment: Entra ID App Registration

The Entra ID App Registration for MSAL authentication is not automated in Bicep (requires Azure AD Graph permissions). Create it manually:

```bash
az ad app create \
  --display-name "InRiver DataCase" \
  --sign-in-audience AzureADMyOrg \
  --web-redirect-uris "https://<frontend-url>/auth/callback" "http://localhost:3000/auth/callback"
```

Store the resulting `clientId` and `tenantId` in Key Vault or as environment variables for the frontend build.

---

## Tear-Down

Since purge protection is **disabled** on the Key Vault (demo setting), you can fully delete all resources:

```bash
az group delete --name RG-InRiver --yes --no-wait
```

> ⚠️ This deletes **all** resources in the group, including the existing AI Foundry instance.
> To remove only the DataCase resources, delete them individually by name.
