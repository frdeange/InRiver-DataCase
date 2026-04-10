-- ============================================================
-- InRiver-DataCase: PIM Schema
-- Applied to: db-acme, db-nova, db-apex
-- ============================================================

-- Categories (hierarchical product classification)
CREATE TABLE Categories (
    CategoryId      INT             PRIMARY KEY IDENTITY(1,1),
    CategoryName    NVARCHAR(200)   NOT NULL,
    ParentCategoryId INT            NULL,
    [Description]   NVARCHAR(1000)  NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,
    CreatedDate     DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    ModifiedDate    DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Categories_Parent FOREIGN KEY (ParentCategoryId) REFERENCES Categories(CategoryId)
);

-- Products
CREATE TABLE Products (
    ProductId       INT             PRIMARY KEY IDENTITY(1,1),
    ProductNumber   NVARCHAR(50)    NOT NULL UNIQUE,
    ProductName     NVARCHAR(300)   NOT NULL,
    [Description]   NVARCHAR(4000)  NULL,
    CategoryId      INT             NOT NULL,
    Brand           NVARCHAR(200)   NULL,
    Status          NVARCHAR(50)    NOT NULL DEFAULT 'Draft',
    ListPrice       DECIMAL(18,2)   NULL,
    Currency        NVARCHAR(3)     NOT NULL DEFAULT 'USD',
    SKU             NVARCHAR(100)   NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,
    CreatedDate     DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    ModifiedDate    DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Products_Category FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId),
    CONSTRAINT CK_Products_Status CHECK (Status IN ('Draft','Review','Approved','Published','Archived'))
);

-- Attributes
CREATE TABLE Attributes (
    AttributeId     INT             PRIMARY KEY IDENTITY(1,1),
    AttributeName   NVARCHAR(200)   NOT NULL UNIQUE,
    DataType        NVARCHAR(50)    NOT NULL,
    Unit            NVARCHAR(50)    NULL,
    IsRequired      BIT             NOT NULL DEFAULT 0,
    CONSTRAINT CK_Attributes_DataType CHECK (DataType IN ('Text','Number','Boolean','Date','List'))
);

-- Product-Attribute junction
CREATE TABLE ProductAttributes (
    ProductAttributeId  INT             PRIMARY KEY IDENTITY(1,1),
    ProductId           INT             NOT NULL,
    AttributeId         INT             NOT NULL,
    [Value]             NVARCHAR(2000)  NOT NULL,
    CONSTRAINT FK_PA_Product FOREIGN KEY (ProductId) REFERENCES Products(ProductId) ON DELETE CASCADE,
    CONSTRAINT FK_PA_Attribute FOREIGN KEY (AttributeId) REFERENCES Attributes(AttributeId),
    CONSTRAINT UQ_PA_ProductAttribute UNIQUE (ProductId, AttributeId)
);

-- Customers
CREATE TABLE Customers (
    CustomerId      INT             PRIMARY KEY IDENTITY(1,1),
    CustomerName    NVARCHAR(300)   NOT NULL,
    ContactEmail    NVARCHAR(256)   NULL,
    Country         NVARCHAR(100)   NOT NULL,
    Segment         NVARCHAR(100)   NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,
    CreatedDate     DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
);

-- Orders
CREATE TABLE Orders (
    OrderId         INT             PRIMARY KEY IDENTITY(1,1),
    OrderNumber     NVARCHAR(50)    NOT NULL UNIQUE,
    CustomerId      INT             NOT NULL,
    ProductId       INT             NOT NULL,
    Quantity        INT             NOT NULL,
    UnitPrice       DECIMAL(18,2)   NOT NULL,
    TotalAmount     AS (Quantity * UnitPrice) PERSISTED,
    OrderDate       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    [Status]        NVARCHAR(50)    NOT NULL DEFAULT 'Pending',
    CONSTRAINT FK_Orders_Customer FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId),
    CONSTRAINT FK_Orders_Product FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
    CONSTRAINT CK_Orders_Status CHECK ([Status] IN ('Pending','Confirmed','Shipped','Delivered','Cancelled')),
    CONSTRAINT CK_Orders_Quantity CHECK (Quantity > 0)
);

-- Indexes
CREATE INDEX IX_Products_CategoryId ON Products(CategoryId);
CREATE INDEX IX_Products_Status ON Products(Status);
CREATE INDEX IX_Products_Brand ON Products(Brand);
CREATE INDEX IX_ProductAttributes_ProductId ON ProductAttributes(ProductId);
CREATE INDEX IX_Orders_CustomerId ON Orders(CustomerId);
CREATE INDEX IX_Orders_ProductId ON Orders(ProductId);
CREATE INDEX IX_Orders_OrderDate ON Orders(OrderDate);
