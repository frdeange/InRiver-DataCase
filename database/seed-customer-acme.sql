-- =============================================================================
-- Seed Data: ACME Corp — Consumer Electronics
-- Run AFTER schema.sql
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Categories
-- ---------------------------------------------------------------------------
INSERT INTO Categories (category_code, category_name, parent_id, sort_order) VALUES
    ('electronics',          'Electronics',               NULL, 1),
    ('computers',            'Computers',                 NULL, 2),
    ('mobile',               'Mobile Devices',            NULL, 3),
    ('accessories',          'Accessories',               NULL, 4),
    ('laptops',              'Laptops',                   (SELECT category_id FROM Categories WHERE category_code='computers'), 1),
    ('desktops',             'Desktop Computers',         (SELECT category_id FROM Categories WHERE category_code='computers'), 2),
    ('tablets',              'Tablets',                   (SELECT category_id FROM Categories WHERE category_code='mobile'), 1),
    ('smartphones',          'Smartphones',               (SELECT category_id FROM Categories WHERE category_code='mobile'), 2),
    ('monitors',             'Monitors',                  (SELECT category_id FROM Categories WHERE category_code='electronics'), 1),
    ('audio',                'Audio',                     (SELECT category_id FROM Categories WHERE category_code='electronics'), 2),
    ('storage',              'Storage',                   (SELECT category_id FROM Categories WHERE category_code='accessories'), 1),
    ('peripherals',          'Peripherals',               (SELECT category_id FROM Categories WHERE category_code='accessories'), 2),
    ('chargers',             'Chargers & Cables',         (SELECT category_id FROM Categories WHERE category_code='accessories'), 3);

-- ---------------------------------------------------------------------------
-- Attributes
-- ---------------------------------------------------------------------------
INSERT INTO Attributes (attribute_code, attribute_name, data_type, unit, is_localizable, is_required) VALUES
    ('weight_kg',         'Weight',               'number',  'kg',   0, 0),
    ('width_mm',          'Width',                'number',  'mm',   0, 0),
    ('height_mm',         'Height',               'number',  'mm',   0, 0),
    ('depth_mm',          'Depth',                'number',  'mm',   0, 0),
    ('battery_life_h',    'Battery Life',         'number',  'h',    0, 0),
    ('ram_gb',            'RAM',                  'number',  'GB',   0, 0),
    ('storage_gb',        'Storage Capacity',     'number',  'GB',   0, 0),
    ('display_inch',      'Display Size',         'number',  'inch', 0, 0),
    ('processor',         'Processor',            'text',    NULL,   0, 0),
    ('color',             'Color',                'text',    NULL,   1, 0),
    ('description',       'Product Description',  'text',    NULL,   1, 1),
    ('short_description', 'Short Description',    'text',    NULL,   1, 0),
    ('warranty_years',    'Warranty',             'number',  'years',0, 0),
    ('is_refurbished',    'Refurbished',          'boolean', NULL,   0, 0),
    ('release_date',      'Release Date',         'date',    NULL,   0, 0),
    ('wattage',           'Power Consumption',    'number',  'W',    0, 0),
    ('resolution',        'Display Resolution',   'text',    NULL,   0, 0),
    ('connectivity',      'Connectivity',         'text',    NULL,   1, 0),
    ('operating_system',  'Operating System',     'text',    NULL,   1, 0),
    ('camera_mp',         'Camera Resolution',    'number',  'MP',   0, 0);

-- ---------------------------------------------------------------------------
-- Products
-- ---------------------------------------------------------------------------
INSERT INTO Products (sku, product_name, brand, status) VALUES
    ('ACME-LT-001', 'ProBook 15 Ultra',           'ACME', 'active'),
    ('ACME-LT-002', 'ProBook 13 Slim',            'ACME', 'active'),
    ('ACME-LT-003', 'WorkForce 17 Gaming',        'ACME', 'active'),
    ('ACME-LT-004', 'UltraEdge 14 Business',      'ACME', 'active'),
    ('ACME-SM-001', 'Pixel X1 Pro',               'ACME', 'active'),
    ('ACME-SM-002', 'Pixel X1 Standard',          'ACME', 'active'),
    ('ACME-SM-003', 'Pixel X1 Lite',              'ACME', 'active'),
    ('ACME-SM-004', 'Pixel X2 Ultra',             'ACME', 'active'),
    ('ACME-TB-001', 'SlateTab 10 Pro',            'ACME', 'active'),
    ('ACME-TB-002', 'SlateTab 12 Artist',         'ACME', 'active'),
    ('ACME-MN-001', '27" 4K HDR Monitor',         'ACME', 'active'),
    ('ACME-MN-002', '24" Full HD Monitor',        'ACME', 'active'),
    ('ACME-AU-001', 'SoundWave ANC Headphones',   'ACME', 'active'),
    ('ACME-AU-002', 'BassBoost Earbuds Pro',      'ACME', 'active'),
    ('ACME-ST-001', 'SecureDrive 1TB SSD',        'ACME', 'active'),
    ('ACME-ST-002', 'SecureDrive 2TB SSD',        'ACME', 'active'),
    ('ACME-AC-001', '65W GaN Charger',            'ACME', 'active'),
    ('ACME-AC-002', 'USB-C Hub 7-in-1',           'ACME', 'active'),
    ('ACME-AC-003', 'Wireless Charging Pad 15W',  'ACME', 'active'),
    ('ACME-LT-005', 'ProBook 15 Ultra (Refurb)',  'ACME', 'active'),
    ('ACME-SM-005', 'Pixel X0 (Discontinued)',    'ACME', 'discontinued'),
    ('ACME-KB-001', 'MechType Pro Keyboard',      'ACME', 'active'),
    ('ACME-MS-001', 'PrecisionClick Ergonomic Mouse', 'ACME', 'active');

-- ---------------------------------------------------------------------------
-- ProductCategories
-- ---------------------------------------------------------------------------
INSERT INTO ProductCategories (product_id, category_id, is_primary)
SELECT p.product_id, c.category_id, 1
FROM Products p CROSS JOIN Categories c
WHERE (p.sku='ACME-LT-001' AND c.category_code='laptops')
   OR (p.sku='ACME-LT-002' AND c.category_code='laptops')
   OR (p.sku='ACME-LT-003' AND c.category_code='laptops')
   OR (p.sku='ACME-LT-004' AND c.category_code='laptops')
   OR (p.sku='ACME-LT-005' AND c.category_code='laptops')
   OR (p.sku='ACME-SM-001' AND c.category_code='smartphones')
   OR (p.sku='ACME-SM-002' AND c.category_code='smartphones')
   OR (p.sku='ACME-SM-003' AND c.category_code='smartphones')
   OR (p.sku='ACME-SM-004' AND c.category_code='smartphones')
   OR (p.sku='ACME-SM-005' AND c.category_code='smartphones')
   OR (p.sku='ACME-TB-001' AND c.category_code='tablets')
   OR (p.sku='ACME-TB-002' AND c.category_code='tablets')
   OR (p.sku='ACME-MN-001' AND c.category_code='monitors')
   OR (p.sku='ACME-MN-002' AND c.category_code='monitors')
   OR (p.sku='ACME-AU-001' AND c.category_code='audio')
   OR (p.sku='ACME-AU-002' AND c.category_code='audio')
   OR (p.sku='ACME-ST-001' AND c.category_code='storage')
   OR (p.sku='ACME-ST-002' AND c.category_code='storage')
   OR (p.sku='ACME-AC-001' AND c.category_code='chargers')
   OR (p.sku='ACME-AC-002' AND c.category_code='peripherals')
   OR (p.sku='ACME-AC-003' AND c.category_code='chargers')
   OR (p.sku='ACME-KB-001' AND c.category_code='peripherals')
   OR (p.sku='ACME-MS-001' AND c.category_code='peripherals');

-- Also tag laptops into parent 'computers' and 'electronics'
INSERT INTO ProductCategories (product_id, category_id, is_primary)
SELECT p.product_id, c.category_id, 0
FROM Products p CROSS JOIN Categories c
WHERE p.sku IN ('ACME-LT-001','ACME-LT-002','ACME-LT-003','ACME-LT-004','ACME-LT-005')
  AND c.category_code IN ('computers','electronics');

-- ---------------------------------------------------------------------------
-- ProductAttributeValues — numeric / boolean / date (language_id = NULL)
-- ---------------------------------------------------------------------------
-- ACME-LT-001 ProBook 15 Ultra
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, number_value, bool_value, date_value)
SELECT p.product_id, a.attribute_id, NULL,
    CASE a.attribute_code
        WHEN 'weight_kg'      THEN 1.75
        WHEN 'width_mm'       THEN 356
        WHEN 'height_mm'      THEN 16
        WHEN 'depth_mm'       THEN 236
        WHEN 'battery_life_h' THEN 14
        WHEN 'ram_gb'         THEN 16
        WHEN 'storage_gb'     THEN 512
        WHEN 'display_inch'   THEN 15.6
        WHEN 'warranty_years' THEN 2
        WHEN 'wattage'        THEN 65
        WHEN 'camera_mp'      THEN 2
    END,
    CASE a.attribute_code WHEN 'is_refurbished' THEN 0 END,
    CASE a.attribute_code WHEN 'release_date'   THEN '2024-03-01' END
FROM Products p CROSS JOIN Attributes a
WHERE p.sku = 'ACME-LT-001'
  AND a.attribute_code IN ('weight_kg','width_mm','height_mm','depth_mm','battery_life_h',
                           'ram_gb','storage_gb','display_inch','warranty_years','wattage',
                           'camera_mp','is_refurbished','release_date');

-- ACME-LT-001 text attributes (English)
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE a.attribute_code
        WHEN 'processor'         THEN 'Intel Core Ultra 7 155H'
        WHEN 'color'             THEN 'Space Grey'
        WHEN 'description'       THEN 'The ProBook 15 Ultra is our flagship 15-inch laptop designed for professionals who demand performance without compromising portability. Featuring an Intel Core Ultra 7 processor, 16GB LPDDR5 RAM, and a stunning 4K OLED display, it handles any workload with ease.'
        WHEN 'short_description' THEN 'Flagship 15" laptop with Intel Core Ultra 7, 16GB RAM, 512GB SSD'
        WHEN 'resolution'        THEN '3840x2160'
        WHEN 'connectivity'      THEN 'WiFi 6E, Bluetooth 5.3, Thunderbolt 4 (x2), USB-A (x2), HDMI 2.1'
        WHEN 'operating_system'  THEN 'Windows 11 Pro'
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku = 'ACME-LT-001'
  AND a.attribute_code IN ('processor','color','description','short_description','resolution','connectivity','operating_system')
  AND l.language_code = 'en';

-- ACME-LT-001 French translations
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE a.attribute_code
        WHEN 'color'             THEN 'Gris sidéral'
        WHEN 'description'       THEN 'Le ProBook 15 Ultra est notre ordinateur portable 15 pouces phare conçu pour les professionnels qui exigent des performances sans compromettre la portabilité.'
        WHEN 'short_description' THEN 'Ordinateur portable phare 15" avec Intel Core Ultra 7, 16 Go de RAM, SSD 512 Go'
        WHEN 'connectivity'      THEN 'WiFi 6E, Bluetooth 5.3, Thunderbolt 4 (x2), USB-A (x2), HDMI 2.1'
        WHEN 'operating_system'  THEN 'Windows 11 Pro'
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku = 'ACME-LT-001'
  AND a.attribute_code IN ('color','description','short_description','connectivity','operating_system')
  AND l.language_code = 'fr';

-- ACME-LT-001 German translations
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE a.attribute_code
        WHEN 'color'             THEN 'Weltraum-Grau'
        WHEN 'description'       THEN 'Das ProBook 15 Ultra ist unser Flaggschiff-Laptop für 15 Zoll, das für Profis entwickelt wurde, die Leistung ohne Kompromisse bei der Tragbarkeit fordern.'
        WHEN 'short_description' THEN 'Flagship 15" Laptop mit Intel Core Ultra 7, 16 GB RAM, 512 GB SSD'
        WHEN 'operating_system'  THEN 'Windows 11 Pro'
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku = 'ACME-LT-001'
  AND a.attribute_code IN ('color','description','short_description','operating_system')
  AND l.language_code = 'de';

-- ACME-LT-002 ProBook 13 Slim
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, number_value, bool_value, date_value)
SELECT p.product_id, a.attribute_id, NULL,
    CASE a.attribute_code
        WHEN 'weight_kg'      THEN 1.19
        WHEN 'battery_life_h' THEN 18
        WHEN 'ram_gb'         THEN 16
        WHEN 'storage_gb'     THEN 256
        WHEN 'display_inch'   THEN 13.3
        WHEN 'warranty_years' THEN 2
        WHEN 'wattage'        THEN 45
    END,
    CASE a.attribute_code WHEN 'is_refurbished' THEN 0 END,
    CASE a.attribute_code WHEN 'release_date'   THEN '2024-05-15' END
FROM Products p CROSS JOIN Attributes a
WHERE p.sku = 'ACME-LT-002'
  AND a.attribute_code IN ('weight_kg','battery_life_h','ram_gb','storage_gb','display_inch',
                           'warranty_years','wattage','is_refurbished','release_date');

INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE a.attribute_code
        WHEN 'processor'         THEN 'Intel Core Ultra 5 125U'
        WHEN 'color'             THEN 'Platinum Silver'
        WHEN 'description'       THEN 'Weighing just 1.19 kg, the ProBook 13 Slim is engineered for travellers and remote workers. Its 18-hour battery life ensures a full workday — and then some.'
        WHEN 'short_description' THEN 'Ultra-light 13" laptop, 18h battery, 16GB RAM'
        WHEN 'operating_system'  THEN 'Windows 11 Home'
        WHEN 'connectivity'      THEN 'WiFi 6E, Bluetooth 5.3, USB-C (x2), USB-A'
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku = 'ACME-LT-002'
  AND a.attribute_code IN ('processor','color','description','short_description','operating_system','connectivity')
  AND l.language_code = 'en';

-- ACME-SM-001 Pixel X1 Pro
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, number_value, date_value)
SELECT p.product_id, a.attribute_id, NULL,
    CASE a.attribute_code
        WHEN 'weight_kg'      THEN 0.215
        WHEN 'display_inch'   THEN 6.7
        WHEN 'ram_gb'         THEN 12
        WHEN 'storage_gb'     THEN 256
        WHEN 'battery_life_h' THEN 30
        WHEN 'camera_mp'      THEN 108
        WHEN 'warranty_years' THEN 2
    END,
    CASE a.attribute_code WHEN 'release_date' THEN '2024-09-10' END
FROM Products p CROSS JOIN Attributes a
WHERE p.sku = 'ACME-SM-001'
  AND a.attribute_code IN ('weight_kg','display_inch','ram_gb','storage_gb','battery_life_h',
                           'camera_mp','warranty_years','release_date');

INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE a.attribute_code
        WHEN 'color'             THEN 'Obsidian Black'
        WHEN 'description'       THEN 'The Pixel X1 Pro pushes mobile photography to new heights with a 108MP triple-camera system. Powered by our custom AI chip, it delivers exceptional performance and a 30-hour battery.'
        WHEN 'short_description' THEN 'Flagship 6.7" smartphone, 108MP camera, 12GB RAM'
        WHEN 'operating_system'  THEN 'Android 15'
        WHEN 'connectivity'      THEN '5G, WiFi 7, Bluetooth 5.4, NFC, USB-C 3.2'
        WHEN 'processor'         THEN 'ACME AX1 Octa-core'
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku = 'ACME-SM-001'
  AND a.attribute_code IN ('color','description','short_description','operating_system','connectivity','processor')
  AND l.language_code = 'en';

-- ACME-SM-002 Pixel X1 Standard
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, number_value, date_value)
SELECT p.product_id, a.attribute_id, NULL,
    CASE a.attribute_code
        WHEN 'weight_kg'      THEN 0.187
        WHEN 'display_inch'   THEN 6.1
        WHEN 'ram_gb'         THEN 8
        WHEN 'storage_gb'     THEN 128
        WHEN 'battery_life_h' THEN 24
        WHEN 'camera_mp'      THEN 64
        WHEN 'warranty_years' THEN 2
    END,
    CASE a.attribute_code WHEN 'release_date' THEN '2024-09-10' END
FROM Products p CROSS JOIN Attributes a
WHERE p.sku = 'ACME-SM-002'
  AND a.attribute_code IN ('weight_kg','display_inch','ram_gb','storage_gb','battery_life_h','camera_mp','warranty_years','release_date');

INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE a.attribute_code
        WHEN 'color'             THEN 'Pearl White'
        WHEN 'description'       THEN 'The Pixel X1 Standard brings flagship features to a more accessible price point. Great camera, great performance, great battery life.'
        WHEN 'short_description' THEN 'Standard 6.1" smartphone, 64MP camera, 8GB RAM'
        WHEN 'operating_system'  THEN 'Android 15'
        WHEN 'processor'         THEN 'ACME AX1 Octa-core'
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku = 'ACME-SM-002'
  AND a.attribute_code IN ('color','description','short_description','operating_system','processor')
  AND l.language_code = 'en';

-- ACME-SM-003 Pixel X1 Lite
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, number_value, date_value)
SELECT p.product_id, a.attribute_id, NULL,
    CASE a.attribute_code
        WHEN 'display_inch'   THEN 5.8
        WHEN 'ram_gb'         THEN 6
        WHEN 'storage_gb'     THEN 64
        WHEN 'battery_life_h' THEN 20
        WHEN 'camera_mp'      THEN 48
    END, CASE a.attribute_code WHEN 'release_date' THEN '2024-09-10' END
FROM Products p CROSS JOIN Attributes a
WHERE p.sku = 'ACME-SM-003'
  AND a.attribute_code IN ('display_inch','ram_gb','storage_gb','battery_life_h','camera_mp','release_date');

INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE a.attribute_code
        WHEN 'color'             THEN 'Coral Pink'
        WHEN 'short_description' THEN 'Compact 5.8" smartphone, 48MP camera, budget-friendly'
        WHEN 'description'       THEN 'Great value in a compact form. The Pixel X1 Lite delivers solid performance for everyday tasks and a vibrant 48MP camera.'
        WHEN 'operating_system'  THEN 'Android 15'
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku = 'ACME-SM-003'
  AND a.attribute_code IN ('color','short_description','description','operating_system')
  AND l.language_code = 'en';

-- ACME-SM-004 Pixel X2 Ultra
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, number_value, date_value)
SELECT p.product_id, a.attribute_id, NULL,
    CASE a.attribute_code
        WHEN 'display_inch'   THEN 6.9
        WHEN 'ram_gb'         THEN 16
        WHEN 'storage_gb'     THEN 512
        WHEN 'battery_life_h' THEN 36
        WHEN 'camera_mp'      THEN 200
        WHEN 'weight_kg'      THEN 0.228
    END, CASE a.attribute_code WHEN 'release_date' THEN '2025-01-20' END
FROM Products p CROSS JOIN Attributes a
WHERE p.sku = 'ACME-SM-004'
  AND a.attribute_code IN ('display_inch','ram_gb','storage_gb','battery_life_h','camera_mp','weight_kg','release_date');

INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE a.attribute_code
        WHEN 'color'             THEN 'Titanium'
        WHEN 'short_description' THEN 'Next-gen 6.9" smartphone, 200MP camera, 16GB RAM'
        WHEN 'description'       THEN 'The Pixel X2 Ultra redefines what a smartphone can do. A 200MP periscope zoom camera, satellite connectivity, and a titanium frame.'
        WHEN 'operating_system'  THEN 'Android 15'
        WHEN 'processor'         THEN 'ACME AX2 Deca-core'
        WHEN 'connectivity'      THEN '5G SA/NSA, WiFi 7, Bluetooth 5.4, Satellite, NFC'
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku = 'ACME-SM-004'
  AND a.attribute_code IN ('color','short_description','description','operating_system','processor','connectivity')
  AND l.language_code = 'en';

-- Remaining products: quick attribute inserts
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE p.sku
        WHEN 'ACME-TB-001' THEN
            CASE a.attribute_code
                WHEN 'short_description' THEN '10" Pro tablet with stylus support, 8GB RAM'
                WHEN 'description'       THEN 'SlateTab 10 Pro — the ultimate productivity tablet. Pair it with the ACME Pencil for natural writing and drawing.'
                WHEN 'color'             THEN 'Midnight Blue'
                WHEN 'operating_system'  THEN 'ACME OS 3.0'
            END
        WHEN 'ACME-TB-002' THEN
            CASE a.attribute_code
                WHEN 'short_description' THEN '12" artist tablet, OLED display, 256GB'
                WHEN 'description'       THEN 'SlateTab 12 Artist features a stunning 12" OLED display with 120Hz refresh and precision stylus support for digital creators.'
                WHEN 'color'             THEN 'Brushed Aluminium'
                WHEN 'operating_system'  THEN 'ACME OS 3.0'
            END
        WHEN 'ACME-MN-001' THEN
            CASE a.attribute_code
                WHEN 'short_description' THEN '27" 4K HDR IPS monitor, 144Hz'
                WHEN 'description'       THEN 'Stunning 27-inch 4K HDR monitor with 144Hz refresh rate. Ideal for creative professionals and gamers alike.'
                WHEN 'color'             THEN 'Matte Black'
                WHEN 'resolution'        THEN '3840x2160'
            END
        WHEN 'ACME-MN-002' THEN
            CASE a.attribute_code
                WHEN 'short_description' THEN '24" Full HD IPS monitor, 75Hz'
                WHEN 'description'       THEN 'Reliable 24-inch Full HD monitor for everyday office and home use. IPS panel for wide viewing angles.'
                WHEN 'color'             THEN 'Matte Black'
                WHEN 'resolution'        THEN '1920x1080'
            END
        WHEN 'ACME-AU-001' THEN
            CASE a.attribute_code
                WHEN 'short_description' THEN 'Active Noise Cancelling over-ear headphones, 30h battery'
                WHEN 'description'       THEN 'SoundWave ANC Headphones deliver immersive audio with industry-leading noise cancellation and 30-hour battery life.'
                WHEN 'color'             THEN 'Carbon Black'
                WHEN 'connectivity'      THEN 'Bluetooth 5.2, 3.5mm jack, USB-C'
            END
        WHEN 'ACME-AU-002' THEN
            CASE a.attribute_code
                WHEN 'short_description' THEN 'True wireless earbuds with ANC, 8h + 24h case'
                WHEN 'description'       THEN 'BassBoost Earbuds Pro. Deep bass, clear highs, and all-day comfort.'
                WHEN 'color'             THEN 'Pearl White'
                WHEN 'connectivity'      THEN 'Bluetooth 5.3'
            END
        WHEN 'ACME-ST-001' THEN
            CASE a.attribute_code
                WHEN 'short_description' THEN 'Portable 1TB USB-C SSD, 1050 MB/s read'
                WHEN 'description'       THEN 'SecureDrive 1TB SSD. Pocket-sized speed for professionals on the move. Hardware AES-256 encryption.'
                WHEN 'color'             THEN 'Space Grey'
                WHEN 'connectivity'      THEN 'USB-C 3.2 Gen 2'
            END
        WHEN 'ACME-ST-002' THEN
            CASE a.attribute_code
                WHEN 'short_description' THEN 'Portable 2TB USB-C SSD, 1050 MB/s read'
                WHEN 'description'       THEN 'SecureDrive 2TB SSD. Double the space, same blazing speed. Hardware AES-256 encryption.'
                WHEN 'color'             THEN 'Space Grey'
                WHEN 'connectivity'      THEN 'USB-C 3.2 Gen 2'
            END
        WHEN 'ACME-AC-001' THEN
            CASE a.attribute_code
                WHEN 'short_description' THEN '65W GaN charger, folds flat, dual port'
                WHEN 'description'       THEN '65W GaN technology in a travel-friendly foldable form. Charge a laptop and phone simultaneously.'
                WHEN 'color'             THEN 'White'
            END
        WHEN 'ACME-AC-002' THEN
            CASE a.attribute_code
                WHEN 'short_description' THEN '7-in-1 USB-C hub: HDMI, USB-A x3, SD, MicroSD, PD'
                WHEN 'description'       THEN 'Expand your laptop ports with this sleek 7-in-1 hub. Supports 4K HDMI output and 100W Power Delivery.'
                WHEN 'color'             THEN 'Space Grey'
                WHEN 'connectivity'      THEN 'USB-C passthrough, HDMI 4K, USB-A 3.0 (x3), SD, MicroSD'
            END
        WHEN 'ACME-AC-003' THEN
            CASE a.attribute_code
                WHEN 'short_description' THEN '15W Qi2 wireless charging pad'
                WHEN 'description'       THEN 'Fast wireless charging for all Qi2-compatible devices. Non-slip surface and LED indicator.'
                WHEN 'color'             THEN 'Black'
            END
        WHEN 'ACME-KB-001' THEN
            CASE a.attribute_code
                WHEN 'short_description' THEN 'Full-size mechanical keyboard, hot-swap switches'
                WHEN 'description'       THEN 'MechType Pro: Customisable per-key RGB, hot-swappable Cherry MX-compatible switches, and aluminium frame.'
                WHEN 'color'             THEN 'Black/Silver'
                WHEN 'connectivity'      THEN 'USB-C, Bluetooth 5.0, 2.4GHz wireless'
            END
        WHEN 'ACME-MS-001' THEN
            CASE a.attribute_code
                WHEN 'short_description' THEN 'Ergonomic wireless mouse, 4000 DPI'
                WHEN 'description'       THEN 'PrecisionClick ergonomic mouse reduces wrist strain during long work sessions. 4000 DPI sensor, 3-month battery life.'
                WHEN 'color'             THEN 'Graphite'
                WHEN 'connectivity'      THEN 'Bluetooth 5.0, 2.4GHz nano-receiver'
            END
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku IN ('ACME-TB-001','ACME-TB-002','ACME-MN-001','ACME-MN-002',
                'ACME-AU-001','ACME-AU-002','ACME-ST-001','ACME-ST-002',
                'ACME-AC-001','ACME-AC-002','ACME-AC-003','ACME-KB-001','ACME-MS-001')
  AND a.attribute_code IN ('short_description','description','color','resolution','connectivity','operating_system')
  AND l.language_code = 'en'
  AND CASE p.sku
        WHEN 'ACME-TB-001' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'operating_system' THEN 1 ELSE 0 END
        WHEN 'ACME-TB-002' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'operating_system' THEN 1 ELSE 0 END
        WHEN 'ACME-MN-001' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'resolution' THEN 1 ELSE 0 END
        WHEN 'ACME-MN-002' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'resolution' THEN 1 ELSE 0 END
        WHEN 'ACME-AU-001' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'connectivity' THEN 1 ELSE 0 END
        WHEN 'ACME-AU-002' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'connectivity' THEN 1 ELSE 0 END
        WHEN 'ACME-ST-001' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'connectivity' THEN 1 ELSE 0 END
        WHEN 'ACME-ST-002' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'connectivity' THEN 1 ELSE 0 END
        WHEN 'ACME-AC-001' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 ELSE 0 END
        WHEN 'ACME-AC-002' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'connectivity' THEN 1 ELSE 0 END
        WHEN 'ACME-AC-003' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 ELSE 0 END
        WHEN 'ACME-KB-001' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'connectivity' THEN 1 ELSE 0 END
        WHEN 'ACME-MS-001' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'connectivity' THEN 1 ELSE 0 END
        ELSE 0
      END = 1;

-- Refurb flag for ACME-LT-005
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, bool_value)
SELECT p.product_id, a.attribute_id, NULL, 1
FROM Products p CROSS JOIN Attributes a
WHERE p.sku = 'ACME-LT-005' AND a.attribute_code = 'is_refurbished';

INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    'Certified refurbished ProBook 15 Ultra — same flagship specs at a reduced price. Includes 1-year warranty.'
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku = 'ACME-LT-005' AND a.attribute_code = 'description' AND l.language_code = 'en';

-- ---------------------------------------------------------------------------
-- ProductChannels
-- ---------------------------------------------------------------------------
INSERT INTO ProductChannels (product_id, channel_id, is_published, published_at)
SELECT p.product_id, c.channel_id, 1, SYSUTCDATETIME()
FROM Products p CROSS JOIN Channels c
WHERE p.sku IN ('ACME-LT-001','ACME-LT-002','ACME-LT-003','ACME-LT-004',
                'ACME-SM-001','ACME-SM-002','ACME-SM-003','ACME-SM-004',
                'ACME-TB-001','ACME-TB-002','ACME-MN-001','ACME-MN-002',
                'ACME-AU-001','ACME-AU-002','ACME-KB-001','ACME-MS-001')
  AND c.channel_code IN ('web','mobile');

INSERT INTO ProductChannels (product_id, channel_id, is_published, published_at)
SELECT p.product_id, c.channel_id, 1, SYSUTCDATETIME()
FROM Products p CROSS JOIN Channels c
WHERE p.sku IN ('ACME-LT-001','ACME-LT-002','ACME-LT-003','ACME-LT-004')
  AND c.channel_code = 'b2b';

INSERT INTO ProductChannels (product_id, channel_id, is_published, published_at)
SELECT p.product_id, c.channel_id, 1, SYSUTCDATETIME()
FROM Products p CROSS JOIN Channels c
WHERE p.sku IN ('ACME-ST-001','ACME-ST-002','ACME-AC-001','ACME-AC-002','ACME-AC-003')
  AND c.channel_code IN ('web','mobile','b2b');

INSERT INTO ProductChannels (product_id, channel_id, is_published, published_at)
SELECT p.product_id, c.channel_id, 1, SYSUTCDATETIME()
FROM Products p CROSS JOIN Channels c
WHERE p.sku = 'ACME-LT-005' AND c.channel_code IN ('web','outlet');

-- Discontinued product not published
INSERT INTO ProductChannels (product_id, channel_id, is_published)
SELECT p.product_id, c.channel_id, 0
FROM Products p CROSS JOIN Channels c
WHERE p.sku = 'ACME-SM-005' AND c.channel_code = 'web';

-- ---------------------------------------------------------------------------
-- MediaAssets
-- ---------------------------------------------------------------------------
INSERT INTO MediaAssets (product_id, asset_type, file_name, url, alt_text, sort_order)
SELECT p.product_id, 'image',
    p.sku + '-front.jpg',
    'https://cdn.acme-corp.example/products/' + p.sku + '-front.jpg',
    p.product_name + ' front view',
    1
FROM Products p WHERE p.sku != 'ACME-SM-005';

INSERT INTO MediaAssets (product_id, asset_type, file_name, url, alt_text, sort_order)
SELECT p.product_id, 'image',
    p.sku + '-side.jpg',
    'https://cdn.acme-corp.example/products/' + p.sku + '-side.jpg',
    p.product_name + ' side view',
    2
FROM Products p WHERE p.sku IN ('ACME-LT-001','ACME-LT-002','ACME-SM-001','ACME-SM-004','ACME-TB-002');

INSERT INTO MediaAssets (product_id, asset_type, file_name, url, alt_text, sort_order)
SELECT p.product_id, 'document',
    p.sku + '-datasheet-en.pdf',
    'https://cdn.acme-corp.example/docs/' + p.sku + '-datasheet-en.pdf',
    p.product_name + ' Datasheet (EN)',
    10
FROM Products p
INNER JOIN Languages l ON l.language_code = 'en'
WHERE p.sku IN ('ACME-LT-001','ACME-LT-002','ACME-SM-001','ACME-SM-004');
