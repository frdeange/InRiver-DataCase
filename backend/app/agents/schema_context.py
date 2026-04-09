from __future__ import annotations

# Static schema description injected into the AI system prompt.
# Each entry describes the table and its columns so the model can generate
# accurate T-SQL SELECT queries without live DB introspection.

SCHEMA_CONTEXT: dict[str, dict] = {
    "Languages": {
        "description": "Reference table of supported locale codes (e.g. 'en', 'fr', 'de').",
        "columns": {
            "language_id":   "INT — primary key",
            "language_code": "NVARCHAR(10) — ISO locale code, e.g. 'en', 'fr', 'de'",
            "language_name": "NVARCHAR(100) — human-readable name, e.g. 'English'",
            "is_default":    "BIT — 1 if this is the default language",
            "created_at":    "DATETIME2",
            "updated_at":    "DATETIME2",
        },
    },
    "Channels": {
        "description": "Sales/distribution channels a product can be published to.",
        "columns": {
            "channel_id":   "INT — primary key",
            "channel_code": "NVARCHAR(50) — e.g. 'web', 'mobile', 'b2b', 'wholesale', 'retail', 'oem', 'outlet', 'summer', 'winter'",
            "channel_name": "NVARCHAR(200) — display name",
            "is_active":    "BIT — 1 if channel is active",
            "created_at":   "DATETIME2",
            "updated_at":   "DATETIME2",
        },
    },
    "Categories": {
        "description": "Hierarchical product taxonomy. parent_id is NULL for root categories.",
        "columns": {
            "category_id":   "INT — primary key",
            "parent_id":     "INT — FK to Categories.category_id, NULL for top-level",
            "category_code": "NVARCHAR(100) — unique slug, e.g. 'laptops', 'electronics'",
            "category_name": "NVARCHAR(200) — display name",
            "sort_order":    "INT — display ordering within parent",
            "created_at":    "DATETIME2",
            "updated_at":    "DATETIME2",
        },
    },
    "Products": {
        "description": "Core product entity. One row per product regardless of language or channel.",
        "columns": {
            "product_id":   "INT — primary key",
            "sku":          "NVARCHAR(100) — unique stock keeping unit code",
            "product_name": "NVARCHAR(500) — primary display name",
            "brand":        "NVARCHAR(200) — brand name",
            "status":       "NVARCHAR(20) — one of: 'draft', 'active', 'discontinued', 'archived'",
            "created_at":   "DATETIME2",
            "updated_at":   "DATETIME2",
        },
    },
    "ProductCategories": {
        "description": "Many-to-many join between Products and Categories.",
        "columns": {
            "product_id":  "INT — FK to Products.product_id",
            "category_id": "INT — FK to Categories.category_id",
            "is_primary":  "BIT — 1 if this is the product's primary category",
        },
    },
    "Attributes": {
        "description": "Typed attribute definitions. data_type determines which value column to read in ProductAttributeValues.",
        "columns": {
            "attribute_id":   "INT — primary key",
            "attribute_code": "NVARCHAR(100) — unique slug, e.g. 'weight_kg', 'color', 'description'",
            "attribute_name": "NVARCHAR(200) — display name",
            "data_type":      "NVARCHAR(20) — one of: 'text', 'number', 'boolean', 'date'",
            "unit":           "NVARCHAR(50) — optional unit label, e.g. 'kg', 'mm', 'W', 'h'",
            "is_localizable": "BIT — 1 if values are stored per language",
            "is_required":    "BIT — 1 if attribute is required on all products",
            "created_at":     "DATETIME2",
            "updated_at":     "DATETIME2",
        },
    },
    "ProductAttributeValues": {
        "description": (
            "Stores the actual attribute values per product. "
            "For text/number/boolean/date attributes use the corresponding typed column. "
            "language_id is NULL for locale-neutral attributes (numbers, booleans, dates). "
            "For localised text attributes, join to Languages to filter by locale."
        ),
        "columns": {
            "value_id":     "INT — primary key",
            "product_id":   "INT — FK to Products.product_id",
            "attribute_id": "INT — FK to Attributes.attribute_id",
            "language_id":  "INT — FK to Languages.language_id, NULL for non-localised attributes",
            "text_value":   "NVARCHAR(MAX) — value when Attributes.data_type = 'text'",
            "number_value": "DECIMAL(18,4) — value when Attributes.data_type = 'number'",
            "bool_value":   "BIT — value when Attributes.data_type = 'boolean'",
            "date_value":   "DATE — value when Attributes.data_type = 'date'",
            "created_at":   "DATETIME2",
            "updated_at":   "DATETIME2",
        },
    },
    "ProductChannels": {
        "description": "Records which channels each product is published to.",
        "columns": {
            "product_id":    "INT — FK to Products.product_id",
            "channel_id":    "INT — FK to Channels.channel_id",
            "is_published":  "BIT — 1 if currently published to this channel",
            "published_at":  "DATETIME2 — timestamp of publication, NULL if not yet published",
        },
    },
    "MediaAssets": {
        "description": "Images, documents, and other media linked to products.",
        "columns": {
            "asset_id":   "INT — primary key",
            "product_id": "INT — FK to Products.product_id",
            "asset_type": "NVARCHAR(20) — one of: 'image', 'document', 'video', 'other'",
            "file_name":  "NVARCHAR(500) — original file name",
            "url":        "NVARCHAR(2000) — CDN or storage URL",
            "alt_text":   "NVARCHAR(500) — accessibility description",
            "sort_order": "INT — ordering within a product's asset list",
            "language_id":"INT — FK to Languages.language_id, NULL for language-neutral assets",
            "created_at": "DATETIME2",
            "updated_at": "DATETIME2",
        },
    },
}


def build_schema_string() -> str:
    """Render SCHEMA_CONTEXT as a human-readable string for injection into the AI system prompt."""
    lines: list[str] = []
    for table_name, meta in SCHEMA_CONTEXT.items():
        lines.append(f"Table: {table_name}")
        lines.append(f"  Description: {meta['description']}")
        lines.append("  Columns:")
        for col, desc in meta["columns"].items():
            lines.append(f"    - {col}: {desc}")
        lines.append("")
    return "\n".join(lines)
