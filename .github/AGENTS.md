# Project Guidelines

## Environment
- This is a dedicated DevContainer. Install all dependencies and packages directly in the DevContainer — **do not use venv**.
- The project targets **Python**.

## Code & Language
- All code (variables, functions, classes, comments, docstrings) must be written in **English**.
- Chat interactions follow the language used by the user.

## Quality
- Every feature must include **documentation** and **tests** as an integral part of the implementation.
- Nothing is considered complete without proper validation and test coverage.

## Azure
- Azure resources may be used as needed. Before any Azure operation, **confirm that the user is logged in** (`az login` / `az account show`).
- **Ask the user** whether the required Azure resources already exist or need to be created.
- When resources exist, always operate within the **same resource group** for management and deployment.
