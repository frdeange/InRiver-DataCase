-- ============================================================
-- Seed Data: Apex Solutions (Fashion & Apparel)
-- Target: db-apex
-- ============================================================

-- ---- Categories (15 total, 2-level hierarchy) ----
SET IDENTITY_INSERT Categories ON;

INSERT INTO Categories (CategoryId, CategoryName, ParentCategoryId, [Description], IsActive)
VALUES
    (1,  'Menswear',       NULL, 'Clothing for men',                   1),
    (2,  'Womenswear',     NULL, 'Clothing for women',                 1),
    (3,  'Footwear',       NULL, 'Shoes, boots and sandals',           1),
    (4,  'Accessories',    NULL, 'Bags, belts, hats and jewelry',      1),
    (5,  'T-Shirts',       1,   'Casual and graphic tees',             1),
    (6,  'Jackets',        1,   'Outerwear and blazers',               1),
    (7,  'Trousers',       1,   'Formal and casual pants',             1),
    (8,  'Dresses',        2,   'Casual, cocktail and formal dresses', 1),
    (9,  'Blouses',        2,   'Shirts and blouses',                  1),
    (10, 'Skirts',         2,   'Mini, midi and maxi skirts',          1),
    (11, 'Sneakers',       3,   'Casual and athletic sneakers',        1),
    (12, 'Boots',          3,   'Ankle, knee and hiking boots',        1),
    (13, 'Bags',           4,   'Handbags, backpacks and totes',       1),
    (14, 'Belts',          4,   'Leather and fabric belts',            1),
    (15, 'Hats',           4,   'Caps, beanies and sun hats',          1);

SET IDENTITY_INSERT Categories OFF;

-- ---- Attributes (10) ----
SET IDENTITY_INSERT Attributes ON;

INSERT INTO Attributes (AttributeId, AttributeName, DataType, Unit, IsRequired)
VALUES
    (1,  'Weight',       'Number',  'g',    0),
    (2,  'Color',        'Text',    NULL,   1),
    (3,  'Size',         'List',    NULL,   1),
    (4,  'Material',     'Text',    NULL,   1),
    (5,  'Season',       'List',    NULL,   0),
    (6,  'Gender',       'List',    NULL,   1),
    (7,  'CareInstr',    'Text',    NULL,   0),
    (8,  'FitType',      'List',    NULL,   0),
    (9,  'Pattern',      'Text',    NULL,   0),
    (10, 'Sustainable',  'Boolean', NULL,   0);

SET IDENTITY_INSERT Attributes OFF;

-- ---- Products (20) ----
SET IDENTITY_INSERT Products ON;

INSERT INTO Products (ProductId, ProductNumber, ProductName, [Description], CategoryId, Brand, Status, ListPrice, Currency, SKU, IsActive)
VALUES
    (1,  'APEX-TSH-001', 'ApexBasics Classic Crew Tee',          'Essential cotton crew-neck t-shirt',                      5,  'ApexBasics',    'Published', 29.99,  'USD', 'AB-TSH-CRW',  1),
    (2,  'APEX-TSH-002', 'ApexBasics V-Neck Tee',               'Soft cotton V-neck tee relaxed fit',                      5,  'ApexBasics',    'Published', 32.99,  'USD', 'AB-TSH-VNK',  1),
    (3,  'APEX-TSH-003', 'ApexStreet Graphic Tee Urban',         'Bold graphic print oversized t-shirt',                    5,  'ApexStreet',    'Published', 39.99,  'USD', 'AS-TSH-GFX',  1),
    (4,  'APEX-JKT-001', 'ApexStreet Bomber Jacket',             'Classic MA-1 bomber jacket with patch details',           6,  'ApexStreet',    'Published', 129.99, 'USD', 'AS-JKT-BMB',  1),
    (5,  'APEX-JKT-002', 'ApexElegance Wool Blazer',             'Single-breasted Italian wool blazer slim fit',            6,  'ApexElegance',  'Published', 249.99, 'USD', 'AE-JKT-BLZ',  1),
    (6,  'APEX-TRS-001', 'ApexBasics Chino Pants',               'Classic straight-leg chino pants',                        7,  'ApexBasics',    'Published', 59.99,  'USD', 'AB-TRS-CHN',  1),
    (7,  'APEX-DRS-001', 'ApexElegance Midi Wrap Dress',         'Floral print wrap dress with tie waist',                  8,  'ApexElegance',  'Published', 89.99,  'USD', 'AE-DRS-WRP',  1),
    (8,  'APEX-DRS-002', 'ApexElegance Cocktail Dress',          'Sleeveless A-line cocktail dress',                        8,  'ApexElegance',  'Published', 149.99, 'USD', 'AE-DRS-CTL',  1),
    (9,  'APEX-BLS-001', 'ApexElegance Silk Blouse',             'Long-sleeve silk blouse with bow collar',                 9,  'ApexElegance',  'Published', 119.99, 'USD', 'AE-BLS-SLK',  1),
    (10, 'APEX-SKT-001', 'ApexBasics A-Line Skirt',              'Knee-length A-line skirt in stretch cotton',              10, 'ApexBasics',    'Published', 49.99,  'USD', 'AB-SKT-ALN',  1),
    (11, 'APEX-SNK-001', 'ApexMove Classic Runner',              'Lightweight mesh running sneakers',                       11, 'ApexMove',      'Published', 89.99,  'USD', 'AM-SNK-RUN',  1),
    (12, 'APEX-SNK-002', 'ApexStreet High-Top Sneaker',          'Canvas high-top street sneaker',                          11, 'ApexStreet',    'Published', 74.99,  'USD', 'AS-SNK-HTP',  1),
    (13, 'APEX-BTS-001', 'ApexMove Hiking Boot',                 'Waterproof mid-cut hiking boot with Vibram sole',         12, 'ApexMove',      'Published', 159.99, 'USD', 'AM-BTS-HIK',  1),
    (14, 'APEX-BTS-002', 'ApexElegance Chelsea Boot',            'Leather Chelsea boot with elastic side panels',           12, 'ApexElegance',  'Published', 189.99, 'USD', 'AE-BTS-CHL',  1),
    (15, 'APEX-BAG-001', 'ApexStreet Canvas Backpack',           'Waxed canvas backpack with leather trim 25L',             13, 'ApexStreet',    'Published', 79.99,  'USD', 'AS-BAG-CNV',  1),
    (16, 'APEX-BAG-002', 'ApexElegance Leather Tote',            'Full-grain leather tote bag with zip closure',            13, 'ApexElegance',  'Published', 199.99, 'USD', 'AE-BAG-TOT',  1),
    (17, 'APEX-BLT-001', 'ApexBasics Leather Belt',              'Full-grain leather belt with brushed nickel buckle',      14, 'ApexBasics',    'Published', 39.99,  'USD', 'AB-BLT-LTH',  1),
    (18, 'APEX-BLT-002', 'ApexStreet Woven Belt',                'Elastic woven belt with pin buckle',                      14, 'ApexStreet',    'Published', 24.99,  'USD', 'AS-BLT-WVN',  1),
    (19, 'APEX-HAT-001', 'ApexStreet Snapback Cap',              'Flat-brim snapback cap with embroidered logo',            15, 'ApexStreet',    'Published', 29.99,  'USD', 'AS-HAT-SNP',  1),
    (20, 'APEX-HAT-002', 'ApexMove Performance Beanie',          'Merino wool blend performance beanie',                    15, 'ApexMove',      'Approved',  34.99,  'USD', 'AM-HAT-BNE',  1);

SET IDENTITY_INSERT Products OFF;

-- ---- ProductAttributes ----
INSERT INTO ProductAttributes (ProductId, AttributeId, [Value])
VALUES
    -- ApexBasics Classic Crew Tee
    (1, 1, '180'),   (1, 2, 'White'),   (1, 3, 'S,M,L,XL'),   (1, 4, '100% Organic Cotton'),   (1, 5, 'All Season'), (1, 6, 'Unisex'),  (1, 8, 'Regular'),   (1, 10, 'true'),
    -- ApexBasics V-Neck Tee
    (2, 2, 'Black'),  (2, 3, 'S,M,L,XL'),  (2, 4, 'Cotton/Modal Blend'),   (2, 6, 'Unisex'),   (2, 8, 'Relaxed'),
    -- ApexStreet Graphic Tee
    (3, 2, 'Charcoal'),  (3, 3, 'M,L,XL,XXL'),  (3, 4, '100% Cotton'),   (3, 6, 'Unisex'),  (3, 9, 'Graphic Print'),   (3, 8, 'Oversized'),
    -- ApexStreet Bomber Jacket
    (4, 1, '650'),  (4, 2, 'Olive Green'),   (4, 3, 'S,M,L,XL'),   (4, 4, 'Nylon'),   (4, 5, 'Fall/Winter'),   (4, 6, 'Male'),   (4, 8, 'Regular'),
    -- ApexElegance Wool Blazer
    (5, 1, '820'),   (5, 2, 'Navy'),   (5, 3, 'S,M,L'),   (5, 4, 'Italian Wool'),   (5, 5, 'Fall/Winter'),   (5, 6, 'Male'),   (5, 8, 'Slim'),
    -- ApexElegance Midi Wrap Dress
    (7, 2, 'Floral Blue'),   (7, 3, 'XS,S,M,L'),   (7, 4, 'Viscose'),   (7, 5, 'Spring/Summer'),   (7, 6, 'Female'),   (7, 9, 'Floral'),
    -- ApexElegance Cocktail Dress
    (8, 2, 'Black'),   (8, 3, 'XS,S,M,L'),   (8, 4, 'Crepe'),   (8, 5, 'All Season'),   (8, 6, 'Female'),   (8, 8, 'Fitted'),
    -- ApexElegance Silk Blouse
    (9, 2, 'Ivory'),   (9, 3, 'XS,S,M,L'),   (9, 4, '100% Silk'),   (9, 6, 'Female'),   (9, 7, 'Dry Clean Only'),
    -- ApexMove Classic Runner
    (11, 1, '280'),   (11, 2, 'Grey/Neon'),   (11, 3, '7,8,9,10,11,12'),   (11, 4, 'Mesh/TPU'),   (11, 6, 'Unisex'),
    -- ApexStreet High-Top Sneaker
    (12, 1, '410'),   (12, 2, 'White'),   (12, 3, '6,7,8,9,10,11'),   (12, 4, 'Canvas'),   (12, 6, 'Unisex'),
    -- ApexMove Hiking Boot
    (13, 1, '780'),   (13, 2, 'Brown/Green'),   (13, 3, '7,8,9,10,11,12'),   (13, 4, 'Leather/Gore-Tex'),   (13, 5, 'Fall/Winter'),   (13, 6, 'Unisex'),
    -- ApexElegance Chelsea Boot
    (14, 1, '620'),   (14, 2, 'Black'),   (14, 3, '7,8,9,10,11'),   (14, 4, 'Full-Grain Leather'),   (14, 6, 'Male'),
    -- ApexStreet Canvas Backpack
    (15, 1, '850'),   (15, 2, 'Olive'),   (15, 4, 'Waxed Canvas/Leather'),   (15, 6, 'Unisex'),   (15, 10, 'true'),
    -- ApexElegance Leather Tote
    (16, 1, '950'),   (16, 2, 'Cognac'),   (16, 4, 'Full-Grain Leather'),   (16, 6, 'Female'),
    -- ApexBasics Leather Belt
    (17, 2, 'Brown'),   (17, 3, '30,32,34,36,38'),   (17, 4, 'Full-Grain Leather'),   (17, 6, 'Male'),
    -- ApexStreet Snapback Cap
    (19, 2, 'Black'),   (19, 4, 'Cotton Twill'),   (19, 6, 'Unisex'),   (19, 9, 'Embroidered Logo'),
    -- ApexMove Performance Beanie
    (20, 1, '65'),   (20, 2, 'Heather Grey'),   (20, 4, 'Merino Wool Blend'),   (20, 5, 'Fall/Winter'),   (20, 6, 'Unisex');

-- ---- Customers (10) ----
SET IDENTITY_INSERT Customers ON;

INSERT INTO Customers (CustomerId, CustomerName, ContactEmail, Country, Segment, IsActive)
VALUES
    (1,  'Nordstrom Inc.',              'buyers@nordstrom.com',          'United States', 'Department Store', 1),
    (2,  'ASOS Marketplace',            'wholesale@asos.com',            'United Kingdom', 'E-Commerce',      1),
    (3,  'Zalando SE',                  'einkauf@zalando.de',            'Germany',        'E-Commerce',      1),
    (4,  'El Palacio de Hierro',        'compras@palaciodehierro.mx',    'Mexico',         'Department Store', 1),
    (5,  'David Jones Pty Ltd',         'buying@davidjones.com.au',      'Australia',      'Department Store', 1),
    (6,  'Galeries Lafayette',          'achats@galerieslafayette.fr',   'France',         'Department Store', 1),
    (7,  'Isetan Mitsukoshi',           'procurement@isetan.co.jp',      'Japan',          'Department Store', 1),
    (8,  'Farfetch Ltd',                'brands@farfetch.com',           'Portugal',       'E-Commerce',      1),
    (9,  'Lotte Shopping',              'buyer@lotteshopping.kr',        'South Korea',    'Department Store', 1),
    (10, 'Myntra Fashion Pvt Ltd',      'sourcing@myntra.in',            'India',          'E-Commerce',      1);

SET IDENTITY_INSERT Customers OFF;

-- ---- Orders (14) ----
SET IDENTITY_INSERT Orders ON;

INSERT INTO Orders (OrderId, OrderNumber, CustomerId, ProductId, Quantity, UnitPrice, OrderDate, [Status])
VALUES
    (1,  'APEX-ORD-0001', 1,  1,  500,  29.99,  '2026-01-08', 'Delivered'),
    (2,  'APEX-ORD-0002', 1,  5,  100,  249.99, '2026-01-08', 'Delivered'),
    (3,  'APEX-ORD-0003', 2,  3,  800,  39.99,  '2026-01-20', 'Shipped'),
    (4,  'APEX-ORD-0004', 3,  7,  300,  89.99,  '2026-02-01', 'Shipped'),
    (5,  'APEX-ORD-0005', 4,  8,  150,  149.99, '2026-02-10', 'Confirmed'),
    (6,  'APEX-ORD-0006', 5,  11, 400,  89.99,  '2026-02-15', 'Confirmed'),
    (7,  'APEX-ORD-0007', 6,  9,  200,  119.99, '2026-02-25', 'Confirmed'),
    (8,  'APEX-ORD-0008', 7,  14, 80,   189.99, '2026-03-02', 'Pending'),
    (9,  'APEX-ORD-0009', 2,  12, 600,  74.99,  '2026-03-05', 'Pending'),
    (10, 'APEX-ORD-0010', 8,  16, 120,  199.99, '2026-03-10', 'Pending'),
    (11, 'APEX-ORD-0011', 9,  4,  250,  129.99, '2026-03-14', 'Pending'),
    (12, 'APEX-ORD-0012', 10, 2,  1000, 32.99,  '2026-03-18', 'Pending'),
    (13, 'APEX-ORD-0013', 3,  15, 350,  79.99,  '2026-03-22', 'Pending'),
    (14, 'APEX-ORD-0014', 6,  17, 200,  39.99,  '2026-03-25', 'Pending');

SET IDENTITY_INSERT Orders OFF;
