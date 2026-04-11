"""Shared Azure credential helper.

Provides a configured DefaultAzureCredential that works both
in local dev (az login) and in Container Apps (managed identity).
"""

from __future__ import annotations

from azure.identity import DefaultAzureCredential, ManagedIdentityCredential
from app.config import settings


def get_azure_credential() -> DefaultAzureCredential | ManagedIdentityCredential:
    """Return the appropriate Azure credential.

    - In Container Apps: uses User-Assigned Managed Identity (via AZURE_MI_CLIENT_ID).
    - In local dev: falls back to DefaultAzureCredential (az login).
    """
    if settings.azure_mi_client_id:
        # In Container Apps, use the specific managed identity
        return ManagedIdentityCredential(client_id=settings.azure_mi_client_id)
    # Local dev — DefaultAzureCredential picks up az login
    return DefaultAzureCredential()
