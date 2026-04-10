-- ============================================================
-- Seed Data: Acme Corp (Tools & Hardware Manufacturer)
-- Target: db-acme
-- ============================================================

-- ---- Categories (15 total, 2-level hierarchy) ----
SET IDENTITY_INSERT Categories ON;

INSERT INTO Categories (CategoryId, CategoryName, ParentCategoryId, [Description], IsActive)
VALUES
    (1,  'Power Tools',       NULL, 'Electric and battery-powered tools',       1),
    (2,  'Hand Tools',        NULL, 'Manual tools for general use',             1),
    (3,  'Fasteners',         NULL, 'Screws, bolts, nails and anchors',         1),
    (4,  'Safety Equipment',  NULL, 'Personal protective equipment',            1),
    (5,  'Drills',            1,    'Corded and cordless drills',                1),
    (6,  'Saws',              1,    'Circular, jig and reciprocating saws',     1),
    (7,  'Grinders',          1,    'Angle and bench grinders',                 1),
    (8,  'Wrenches',          2,    'Adjustable and socket wrenches',           1),
    (9,  'Screwdrivers',      2,    'Flathead and Phillips screwdrivers',       1),
    (10, 'Pliers',            2,    'Combination, needle-nose and locking',     1),
    (11, 'Screws',            3,    'Wood, machine and self-tapping screws',    1),
    (12, 'Bolts',             3,    'Hex, carriage and anchor bolts',           1),
    (13, 'Helmets',           4,    'Hard hats and bump caps',                  1),
    (14, 'Gloves',            4,    'Cut-resistant and insulated gloves',       1),
    (15, 'Eyewear',           4,    'Safety glasses and goggles',               1);

SET IDENTITY_INSERT Categories OFF;

-- ---- Attributes (10) ----
SET IDENTITY_INSERT Attributes ON;

INSERT INTO Attributes (AttributeId, AttributeName, DataType, Unit, IsRequired)
VALUES
    (1,  'Weight',          'Number',  'kg',    1),
    (2,  'Color',           'Text',    NULL,    0),
    (3,  'Voltage',         'Number',  'V',     0),
    (4,  'Material',        'Text',    NULL,    1),
    (5,  'Warranty',        'Number',  'years', 0),
    (6,  'PowerSource',     'List',    NULL,    0),
    (7,  'MaxRPM',          'Number',  'rpm',   0),
    (8,  'LengthMM',        'Number',  'mm',    0),
    (9,  'Certification',   'Text',    NULL,    0),
    (10, 'CountryOfOrigin', 'Text',    NULL,    0);

SET IDENTITY_INSERT Attributes OFF;

-- ---- Products (20) ----
SET IDENTITY_INSERT Products ON;

INSERT INTO Products (ProductId, ProductNumber, ProductName, [Description], CategoryId, Brand, Status, ListPrice, Currency, SKU, IsActive)
VALUES
    (1,  'ACME-DRL-001', 'AcmePro 20V Cordless Drill',          'Compact 20V lithium-ion cordless drill with 2-speed gearbox',    5,  'AcmePro',   'Published', 129.99, 'USD', 'AP-DRL-20V',   1),
    (2,  'ACME-DRL-002', 'AcmePro Hammer Drill 18V',            '18V brushless hammer drill for masonry and concrete',            5,  'AcmePro',   'Published', 189.99, 'USD', 'AP-DRL-18VH',  1),
    (3,  'ACME-SAW-001', 'AcmeForge 7-1/4" Circular Saw',       'Lightweight circular saw with laser guide',                      6,  'AcmeForge', 'Published', 99.99,  'USD', 'AF-SAW-714',   1),
    (4,  'ACME-SAW-002', 'AcmeForge Jigsaw 6.5A',               'Variable speed jigsaw for curves and intricate cuts',            6,  'AcmeForge', 'Published', 79.99,  'USD', 'AF-SAW-JIG',   1),
    (5,  'ACME-GRD-001', 'AcmePro 4.5" Angle Grinder',          'Compact angle grinder 11000 RPM',                                7,  'AcmePro',   'Published', 64.99,  'USD', 'AP-GRD-45',    1),
    (6,  'ACME-WRN-001', 'AcmeFix Adjustable Wrench 12"',       'Chrome vanadium adjustable wrench with cushion grip',            8,  'AcmeFix',   'Published', 24.99,  'USD', 'AFX-WRN-12',   1),
    (7,  'ACME-WRN-002', 'AcmeFix Socket Set 40pc',             '40-piece 1/4" and 3/8" drive socket set',                       8,  'AcmeFix',   'Published', 49.99,  'USD', 'AFX-WRN-40S',  1),
    (8,  'ACME-SCR-001', 'AcmeFix 8pc Screwdriver Set',         'Magnetic tip screwdriver set — 4 flathead, 4 Phillips',          9,  'AcmeFix',   'Published', 19.99,  'USD', 'AFX-SCR-8S',   1),
    (9,  'ACME-PLR-001', 'AcmeFix Combination Pliers 8"',       'Drop-forged combination pliers with wire cutter',                10, 'AcmeFix',   'Published', 14.99,  'USD', 'AFX-PLR-8C',   1),
    (10, 'ACME-PLR-002', 'AcmeFix Locking Pliers 10"',          'Self-adjusting locking pliers with release lever',               10, 'AcmeFix',   'Published', 17.99,  'USD', 'AFX-PLR-10L',  1),
    (11, 'ACME-FST-001', 'AcmeForge Wood Screws #8 x 2" 100pk', 'Yellow zinc coated Phillips flat head wood screws',              11, 'AcmeForge', 'Published', 8.99,   'USD', 'AF-FST-WS82',  1),
    (12, 'ACME-FST-002', 'AcmeForge Machine Screws M5 50pk',    'Stainless steel pan head machine screws M5x20',                  11, 'AcmeForge', 'Published', 6.49,   'USD', 'AF-FST-MS5',   1),
    (13, 'ACME-FST-003', 'AcmeForge Hex Bolts M8 25pk',         'Grade 8.8 hex bolts M8x40 zinc plated',                         12, 'AcmeForge', 'Published', 11.99,  'USD', 'AF-FST-HB8',   1),
    (14, 'ACME-HLM-001', 'AcmeSafe Hard Hat Type I',             'ANSI Z89.1 compliant ratchet suspension hard hat',               13, 'AcmeSafe',  'Published', 29.99,  'USD', 'AS-HLM-T1',    1),
    (15, 'ACME-HLM-002', 'AcmeSafe Vented Hard Hat',             'Ventilated hard hat with 4-point suspension',                   13, 'AcmeSafe',  'Published', 34.99,  'USD', 'AS-HLM-V4',    1),
    (16, 'ACME-GLV-001', 'AcmeSafe Cut-Resistant Gloves L',      'ANSI A4 cut-resistant nitrile coated gloves',                   14, 'AcmeSafe',  'Published', 12.99,  'USD', 'AS-GLV-CRL',   1),
    (17, 'ACME-GLV-002', 'AcmeSafe Insulated Gloves XL',         'Thinsulate-lined winter work gloves',                           14, 'AcmeSafe',  'Published', 22.99,  'USD', 'AS-GLV-IXL',   1),
    (18, 'ACME-EYE-001', 'AcmeSafe Safety Glasses Clear',        'Anti-fog polycarbonate safety glasses',                         15, 'AcmeSafe',  'Published', 9.99,   'USD', 'AS-EYE-CLR',   1),
    (19, 'ACME-EYE-002', 'AcmeSafe Safety Goggles Splash',       'Chemical splash-proof safety goggles',                          15, 'AcmeSafe',  'Published', 15.99,  'USD', 'AS-EYE-SPL',   1),
    (20, 'ACME-DRL-003', 'AcmePro Impact Driver 20V',            '20V 1/4" hex impact driver 1800 in-lbs torque',                 5,  'AcmePro',   'Approved',  149.99, 'USD', 'AP-DRL-20VI',  1);

SET IDENTITY_INSERT Products OFF;

-- ---- ProductAttributes (selected attributes per product) ----
INSERT INTO ProductAttributes (ProductId, AttributeId, [Value])
VALUES
    -- AcmePro 20V Cordless Drill
    (1, 1, '1.8'),    (1, 2, 'Yellow'),    (1, 3, '20'),    (1, 4, 'ABS/Metal'),    (1, 5, '3'),    (1, 6, 'Battery'),
    -- AcmePro Hammer Drill 18V
    (2, 1, '2.3'),    (2, 3, '18'),    (2, 4, 'Metal'),    (2, 7, '2100'),
    -- AcmeForge 7-1/4" Circular Saw
    (3, 1, '3.6'),    (3, 3, '120'),    (3, 4, 'Aluminum/Steel'),    (3, 6, 'Corded'),    (3, 7, '5800'),
    -- AcmeForge Jigsaw
    (4, 1, '2.1'),    (4, 4, 'Metal'),    (4, 6, 'Corded'),
    -- AcmePro Angle Grinder
    (5, 1, '2.0'),    (5, 3, '120'),    (5, 7, '11000'),    (5, 4, 'Metal'),
    -- AcmeFix Adjustable Wrench
    (6, 1, '0.45'),   (6, 4, 'Chrome Vanadium'),    (6, 8, '305'),
    -- AcmeFix Socket Set
    (7, 1, '2.8'),    (7, 4, 'Chrome Vanadium Steel'),    (7, 5, '5'),
    -- AcmeFix Screwdriver Set
    (8, 1, '0.9'),    (8, 4, 'CR-V Steel'),    (8, 2, 'Black/Orange'),
    -- AcmeFix Combination Pliers
    (9, 1, '0.28'),   (9, 4, 'Drop-Forged Steel'),    (9, 8, '200'),
    -- AcmeSafe Hard Hat
    (14, 1, '0.37'),   (14, 2, 'White'),    (14, 9, 'ANSI Z89.1'),    (14, 10, 'USA'),
    -- AcmeSafe Safety Glasses
    (18, 1, '0.03'),   (18, 4, 'Polycarbonate'),    (18, 9, 'ANSI Z87.1'),
    -- AcmePro Impact Driver
    (20, 1, '1.5'),    (20, 3, '20'),    (20, 4, 'Metal/Composite'),    (20, 6, 'Battery'),    (20, 7, '2900');

-- ---- Customers (10) ----
SET IDENTITY_INSERT Customers ON;

INSERT INTO Customers (CustomerId, CustomerName, ContactEmail, Country, Segment, IsActive)
VALUES
    (1,  'BuildRight Hardware',          'orders@buildright.com',         'United States', 'Retail',        1),
    (2,  'ToolStation UK',               'procurement@toolstation.co.uk', 'United Kingdom','Retail',        1),
    (3,  'Bauhaus GmbH',                 'einkauf@bauhaus.de',            'Germany',       'Retail',        1),
    (4,  'Ferreteria Nacional',           'compras@ferreteria.mx',         'Mexico',        'Distributor',   1),
    (5,  'ProBuild Contractors',          'supply@probuild.com.au',        'Australia',     'Contractor',    1),
    (6,  'Osaka Tool Trading Co.',        'info@osakatool.jp',             'Japan',         'Distributor',   1),
    (7,  'Nordic Bygg AS',               'innkjop@nordicbygg.no',         'Norway',        'Contractor',    1),
    (8,  'ConstructionPro Canada',        'orders@constructpro.ca',        'Canada',        'Contractor',    1),
    (9,  'Bricolage Plus',               'achats@bricolageplus.fr',       'France',        'Retail',        1),
    (10, 'Ferragem Brasil Ltda',         'compras@ferragem.com.br',       'Brazil',        'Distributor',   1);

SET IDENTITY_INSERT Customers OFF;

-- ---- Orders (15) ----
SET IDENTITY_INSERT Orders ON;

INSERT INTO Orders (OrderId, OrderNumber, CustomerId, ProductId, Quantity, UnitPrice, OrderDate, [Status])
VALUES
    (1,  'ACME-ORD-0001', 1,  1,  50,  129.99, '2026-01-15', 'Delivered'),
    (2,  'ACME-ORD-0002', 1,  3,  30,  99.99,  '2026-01-20', 'Delivered'),
    (3,  'ACME-ORD-0003', 2,  6,  200, 24.99,  '2026-02-03', 'Shipped'),
    (4,  'ACME-ORD-0004', 3,  14, 100, 29.99,  '2026-02-10', 'Shipped'),
    (5,  'ACME-ORD-0005', 4,  11, 500, 8.99,   '2026-02-14', 'Confirmed'),
    (6,  'ACME-ORD-0006', 5,  2,  25,  189.99, '2026-02-20', 'Confirmed'),
    (7,  'ACME-ORD-0007', 6,  7,  40,  49.99,  '2026-03-01', 'Pending'),
    (8,  'ACME-ORD-0008', 7,  16, 150, 12.99,  '2026-03-05', 'Pending'),
    (9,  'ACME-ORD-0009', 2,  18, 300, 9.99,   '2026-03-08', 'Confirmed'),
    (10, 'ACME-ORD-0010', 8,  5,  15,  64.99,  '2026-03-10', 'Pending'),
    (11, 'ACME-ORD-0011', 9,  8,  80,  19.99,  '2026-03-12', 'Confirmed'),
    (12, 'ACME-ORD-0012', 10, 13, 200, 11.99,  '2026-03-15', 'Pending'),
    (13, 'ACME-ORD-0013', 3,  20, 10,  149.99, '2026-03-18', 'Pending'),
    (14, 'ACME-ORD-0014', 5,  4,  20,  79.99,  '2026-03-20', 'Pending'),
    (15, 'ACME-ORD-0015', 4,  19, 100, 15.99,  '2026-03-25', 'Pending');

SET IDENTITY_INSERT Orders OFF;
