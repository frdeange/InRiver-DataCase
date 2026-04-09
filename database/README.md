# database/

SQL scripts for the InRiver Agentic SQL PoC — schema definition and seed data.

## Files

```
database/
├── schema.sql         # CREATE TABLE DDL — applied identically to all 3 databases
├── seed-alpha.sql     # Seed data for pim-alpha (Tenant: "Alpha Corp" — electronics)
├── seed-beta.sql      # Seed data for pim-beta  (Tenant: "Beta Ltd"  — fashion)
├── seed-gamma.sql     # Seed data for pim-gamma (Tenant: "Gamma Inc" — food)
└── readonly-user.sql  # Creates pim_reader login with SELECT-only grants
```

## Schema Overview

The schema models a simplified PIM (Product Information Management) system:

- **Products** — core product entity (SKU, name, status, category)
- **Categories** — hierarchical product categorisation
- **Attributes** — attribute definitions (e.g., "Color", "Weight", "Material")
- **AttributeValues** — product-attribute values (EAV pattern)
- **Images** — product image references (URL, alt text, sort order)
- **Languages** — supported languages for multilingual attribute values
- **LocalisedValues** — language-specific attribute values

This schema is intentionally realistic enough to generate interesting natural-language queries (e.g., "products with no images", "top categories by product count", "products missing German translations").

## Apply Schema

```bash
# Using sqlcmd (available in devcontainer)
sqlcmd -S sql-inriver-poc.database.windows.net -d pim-alpha -U pim_admin -P $SQL_ADMIN_PASSWORD -i database/schema.sql
sqlcmd -S sql-inriver-poc.database.windows.net -d pim-beta  -U pim_admin -P $SQL_ADMIN_PASSWORD -i database/schema.sql
sqlcmd -S sql-inriver-poc.database.windows.net -d pim-gamma -U pim_admin -P $SQL_ADMIN_PASSWORD -i database/schema.sql
```

## Apply Seed Data

```bash
sqlcmd -S sql-inriver-poc.database.windows.net -d pim-alpha -U pim_admin -P $SQL_ADMIN_PASSWORD -i database/seed-alpha.sql
sqlcmd -S sql-inriver-poc.database.windows.net -d pim-beta  -U pim_admin -P $SQL_ADMIN_PASSWORD -i database/seed-beta.sql
sqlcmd -S sql-inriver-poc.database.windows.net -d pim-gamma -U pim_admin -P $SQL_ADMIN_PASSWORD -i database/seed-gamma.sql
```

## Create Read-Only User

```bash
# Run once per database after schema is applied
sqlcmd -S sql-inriver-poc.database.windows.net -d pim-alpha -U pim_admin -P $SQL_ADMIN_PASSWORD -i database/readonly-user.sql
sqlcmd -S sql-inriver-poc.database.windows.net -d pim-beta  -U pim_admin -P $SQL_ADMIN_PASSWORD -i database/readonly-user.sql
sqlcmd -S sql-inriver-poc.database.windows.net -d pim-gamma -U pim_admin -P $SQL_ADMIN_PASSWORD -i database/readonly-user.sql
```

## Schema Governance

**Rule:** `schema.sql` is the single source of truth. All 3 databases must have identical schema at all times. If schema changes are needed, update `schema.sql` and re-apply to all databases. Do not apply ad-hoc changes directly to individual databases — this breaks the AI's schema prompt and the multi-tenancy story.
