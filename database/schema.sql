-- =============================================================================
-- InRiver PIM Database Schema (Azure SQL / T-SQL)
-- =============================================================================
-- Inspired by InRiver's data model. Supports multilingual content,
-- hierarchical categories, typed attributes, sales channels, and media assets.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Languages: reference table for supported locale codes
-- ---------------------------------------------------------------------------
CREATE TABLE Languages (
    language_id   INT           IDENTITY(1,1) PRIMARY KEY,
    language_code NVARCHAR(10)  NOT NULL UNIQUE,   -- e.g. 'en', 'fr', 'de'
    language_name NVARCHAR(100) NOT NULL,
    is_default    BIT           NOT NULL DEFAULT 0,
    created_at    DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at    DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME()
);

-- ---------------------------------------------------------------------------
-- Channels: sales / distribution channels a product can be published to
-- ---------------------------------------------------------------------------
CREATE TABLE Channels (
    channel_id   INT            IDENTITY(1,1) PRIMARY KEY,
    channel_code NVARCHAR(50)   NOT NULL UNIQUE,
    channel_name NVARCHAR(200)  NOT NULL,
    is_active    BIT            NOT NULL DEFAULT 1,
    created_at   DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at   DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);

-- ---------------------------------------------------------------------------
-- Categories: hierarchical product taxonomy (self-referencing)
-- ---------------------------------------------------------------------------
CREATE TABLE Categories (
    category_id   INT            IDENTITY(1,1) PRIMARY KEY,
    parent_id     INT            NULL REFERENCES Categories(category_id),
    category_code NVARCHAR(100)  NOT NULL UNIQUE,
    category_name NVARCHAR(200)  NOT NULL,
    sort_order    INT            NOT NULL DEFAULT 0,
    created_at    DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at    DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_Categories_ParentId ON Categories(parent_id);

-- ---------------------------------------------------------------------------
-- Products: core product entity
-- ---------------------------------------------------------------------------
CREATE TABLE Products (
    product_id    INT            IDENTITY(1,1) PRIMARY KEY,
    sku           NVARCHAR(100)  NOT NULL UNIQUE,
    product_name  NVARCHAR(500)  NOT NULL,
    brand         NVARCHAR(200)  NULL,
    status        NVARCHAR(20)   NOT NULL DEFAULT 'draft'
                                 CONSTRAINT CK_Products_Status
                                 CHECK (status IN ('draft','active','discontinued','archived')),
    created_at    DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at    DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_Products_SKU        ON Products(sku);
CREATE INDEX IX_Products_Status     ON Products(status);
CREATE INDEX IX_Products_Brand      ON Products(brand);

-- ---------------------------------------------------------------------------
-- ProductCategories: many-to-many Products <-> Categories
-- ---------------------------------------------------------------------------
CREATE TABLE ProductCategories (
    product_id  INT NOT NULL REFERENCES Products(product_id),
    category_id INT NOT NULL REFERENCES Categories(category_id),
    is_primary  BIT NOT NULL DEFAULT 0,
    CONSTRAINT PK_ProductCategories PRIMARY KEY (product_id, category_id)
);

CREATE INDEX IX_ProductCategories_Category ON ProductCategories(category_id);

-- ---------------------------------------------------------------------------
-- Attributes: typed attribute definitions (text, number, boolean, date)
-- ---------------------------------------------------------------------------
CREATE TABLE Attributes (
    attribute_id   INT            IDENTITY(1,1) PRIMARY KEY,
    attribute_code NVARCHAR(100)  NOT NULL UNIQUE,
    attribute_name NVARCHAR(200)  NOT NULL,
    data_type      NVARCHAR(20)   NOT NULL
                                  CONSTRAINT CK_Attributes_DataType
                                  CHECK (data_type IN ('text','number','boolean','date')),
    unit           NVARCHAR(50)   NULL,   -- e.g. 'kg', 'mm', 'W'
    is_localizable BIT            NOT NULL DEFAULT 0,
    is_required    BIT            NOT NULL DEFAULT 0,
    created_at     DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at     DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_Attributes_DataType ON Attributes(data_type);

-- ---------------------------------------------------------------------------
-- ProductAttributeValues: stores actual attribute values per product (+ locale)
-- Locale-neutral attributes store language_id = NULL.
-- ---------------------------------------------------------------------------
CREATE TABLE ProductAttributeValues (
    value_id     INT            IDENTITY(1,1) PRIMARY KEY,
    product_id   INT            NOT NULL REFERENCES Products(product_id),
    attribute_id INT            NOT NULL REFERENCES Attributes(attribute_id),
    language_id  INT            NULL     REFERENCES Languages(language_id),
    text_value   NVARCHAR(MAX)  NULL,
    number_value DECIMAL(18,4)  NULL,
    bool_value   BIT            NULL,
    date_value   DATE           NULL,
    created_at   DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at   DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_PAV_Product_Attr_Lang UNIQUE (product_id, attribute_id, language_id)
);

CREATE INDEX IX_PAV_ProductId   ON ProductAttributeValues(product_id);
CREATE INDEX IX_PAV_AttributeId ON ProductAttributeValues(attribute_id);
CREATE INDEX IX_PAV_LanguageId  ON ProductAttributeValues(language_id);

-- ---------------------------------------------------------------------------
-- ProductChannels: which channels each product is published to
-- ---------------------------------------------------------------------------
CREATE TABLE ProductChannels (
    product_id   INT       NOT NULL REFERENCES Products(product_id),
    channel_id   INT       NOT NULL REFERENCES Channels(channel_id),
    is_published BIT       NOT NULL DEFAULT 0,
    published_at DATETIME2 NULL,
    CONSTRAINT PK_ProductChannels PRIMARY KEY (product_id, channel_id)
);

CREATE INDEX IX_ProductChannels_Channel ON ProductChannels(channel_id);

-- ---------------------------------------------------------------------------
-- MediaAssets: images and documents linked to products
-- ---------------------------------------------------------------------------
CREATE TABLE MediaAssets (
    asset_id    INT            IDENTITY(1,1) PRIMARY KEY,
    product_id  INT            NOT NULL REFERENCES Products(product_id),
    asset_type  NVARCHAR(20)   NOT NULL
                               CONSTRAINT CK_MediaAssets_Type
                               CHECK (asset_type IN ('image','document','video','other')),
    file_name   NVARCHAR(500)  NOT NULL,
    url         NVARCHAR(2000) NOT NULL,
    alt_text    NVARCHAR(500)  NULL,
    sort_order  INT            NOT NULL DEFAULT 0,
    language_id INT            NULL REFERENCES Languages(language_id),
    created_at  DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at  DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE INDEX IX_MediaAssets_ProductId ON MediaAssets(product_id);
CREATE INDEX IX_MediaAssets_AssetType ON MediaAssets(asset_type);

-- =============================================================================
-- Reference Data: Languages
-- =============================================================================
MERGE Languages AS tgt
USING (VALUES
    ('en', 'English',  1),
    ('fr', 'French',   0),
    ('de', 'German',   0),
    ('nl', 'Dutch',    0),
    ('es', 'Spanish',  0),
    ('sv', 'Swedish',  0)
) AS src(language_code, language_name, is_default)
ON tgt.language_code = src.language_code
WHEN NOT MATCHED THEN
    INSERT (language_code, language_name, is_default)
    VALUES (src.language_code, src.language_name, src.is_default);

-- =============================================================================
-- Reference Data: Channels
-- =============================================================================
MERGE Channels AS tgt
USING (VALUES
    ('web',      'Web Store',      1),
    ('mobile',   'Mobile App',     1),
    ('b2b',      'B2B Portal',     1),
    ('wholesale','Wholesale',      1),
    ('retail',   'Retail',         1),
    ('oem',      'OEM',            1),
    ('outlet',   'Outlet',         1),
    ('summer',   'Summer Collection', 1),
    ('winter',   'Winter Collection', 1)
) AS src(channel_code, channel_name, is_active)
ON tgt.channel_code = src.channel_code
WHEN NOT MATCHED THEN
    INSERT (channel_code, channel_name, is_active)
    VALUES (src.channel_code, src.channel_name, src.is_active);
