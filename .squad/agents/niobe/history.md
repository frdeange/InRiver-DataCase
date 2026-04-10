# Niobe — History

## Learnings

- Project: InRiver-DataCase — secure multi-tenant AI-powered SQL query system
- User: Kiko de Angel
- Auth: Microsoft Entra ID with MSAL
- Must prevent: SQL injection, prompt injection, cross-tenant data leaks
- User identity must be enforced at every layer including database
- 3 customer environments require strict tenant isolation
