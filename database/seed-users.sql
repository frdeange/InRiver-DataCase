-- ============================================================
-- InRiver-DataCase: Seed Users & Domain Mappings
-- Applied to: db-users
-- ============================================================

-- Test users (passwords hashed with bcrypt)
INSERT INTO Users (Email, PasswordHash, FullName) VALUES
    ('alice@acme.com',      '$2b$12$hxpXvAGW3iONuS2cX9Eft.0IssclhTYom1esha5xIb8OdXN7g2HhG', 'Alice Johnson'),
    ('bob@nova.com',        '$2b$12$ubuSzS3JCJbKJL5Kcn98G.X5zhZ2/ykvbN0.e8lp.l9DE/A5hRpcG', 'Bob Smith'),
    ('carol@apex.com',      '$2b$12$5qm4MzrmNhu03UZzLGjWnuwweKpCLnp8Z9WVmGiqAgmlAMueXws3q', 'Carol Martinez'),
    ('admin@inriver.com',   '$2b$12$v4Crz8c9FymN/EIk6tGII.HvC40o/K.T1TdixCbFLRygHibFANsNe', 'Admin User');

-- Domain-to-database mappings
INSERT INTO DomainDatabaseMap (EmailDomain, DatabaseName) VALUES
    ('acme.com',     'db-acme'),
    ('nova.com',     'db-nova'),
    ('apex.com',     'db-apex'),
    ('inriver.com',  'db-acme'),
    ('inriver.com',  'db-nova'),
    ('inriver.com',  'db-apex');
