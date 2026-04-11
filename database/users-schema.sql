-- ============================================================
-- InRiver-DataCase: Users & Authorization Schema
-- Applied to: db-users
-- ============================================================

-- Users table for custom email/password authentication
CREATE TABLE Users (
    Id              INT             PRIMARY KEY IDENTITY(1,1),
    Email           NVARCHAR(256)   NOT NULL UNIQUE,
    PasswordHash    NVARCHAR(256)   NOT NULL,
    FullName        NVARCHAR(200)   NOT NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,
    CreatedAt       DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME()
);

-- Domain-to-database mapping for tenant isolation
CREATE TABLE DomainDatabaseMap (
    Id              INT             PRIMARY KEY IDENTITY(1,1),
    EmailDomain     NVARCHAR(256)   NOT NULL,
    DatabaseName    NVARCHAR(128)   NOT NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,
    CONSTRAINT UQ_DomainDatabase UNIQUE (EmailDomain, DatabaseName)
);

CREATE INDEX IX_Users_Email ON Users(Email);
CREATE INDEX IX_DomainDatabaseMap_Domain ON DomainDatabaseMap(EmailDomain);
