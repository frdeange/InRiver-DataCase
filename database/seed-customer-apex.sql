-- =============================================================================
-- Seed Data: Apex Distribution — Wholesale / Distribution
-- Run AFTER schema.sql
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Categories
-- ---------------------------------------------------------------------------
INSERT INTO Categories (category_code, category_name, parent_id, sort_order) VALUES
    ('industrial-equipment',  'Industrial Equipment',    NULL, 1),
    ('safety-ppe',            'Safety & PPE',            NULL, 2),
    ('packaging-materials',   'Packaging Materials',     NULL, 3),
    ('logistics-supplies',    'Logistics Supplies',      NULL, 4),
    ('electrical-components', 'Electrical Components',   NULL, 5);

INSERT INTO Categories (category_code, category_name, parent_id, sort_order) VALUES
    ('heavy-machinery',       'Heavy Machinery',         (SELECT category_id FROM Categories WHERE category_code='industrial-equipment'), 1),
    ('hand-tools',            'Hand Tools',              (SELECT category_id FROM Categories WHERE category_code='industrial-equipment'), 2),
    ('power-tools',           'Power Tools',             (SELECT category_id FROM Categories WHERE category_code='industrial-equipment'), 3),
    ('head-protection',       'Head Protection',         (SELECT category_id FROM Categories WHERE category_code='safety-ppe'), 1),
    ('eye-protection',        'Eye & Face Protection',   (SELECT category_id FROM Categories WHERE category_code='safety-ppe'), 2),
    ('protective-clothing',   'Protective Clothing',     (SELECT category_id FROM Categories WHERE category_code='safety-ppe'), 3),
    ('corrugated-boxes',      'Corrugated Boxes',        (SELECT category_id FROM Categories WHERE category_code='packaging-materials'), 1),
    ('stretch-wrap',          'Stretch Wrap & Film',     (SELECT category_id FROM Categories WHERE category_code='packaging-materials'), 2),
    ('pallet-handling',       'Pallet Handling',         (SELECT category_id FROM Categories WHERE category_code='logistics-supplies'), 1),
    ('labels-marking',        'Labels & Marking',        (SELECT category_id FROM Categories WHERE category_code='logistics-supplies'), 2),
    ('cable-management',      'Cable Management',        (SELECT category_id FROM Categories WHERE category_code='electrical-components'), 1),
    ('circuit-protection',    'Circuit Protection',      (SELECT category_id FROM Categories WHERE category_code='electrical-components'), 2);

-- ---------------------------------------------------------------------------
-- Attributes
-- ---------------------------------------------------------------------------
INSERT INTO Attributes (attribute_code, attribute_name, data_type, unit, is_localizable, is_required) VALUES
    ('weight_kg',            'Weight',                    'number',  'kg',    0, 0),
    ('width_mm',             'Width',                     'number',  'mm',    0, 0),
    ('height_mm',            'Height',                    'number',  'mm',    0, 0),
    ('depth_mm',             'Depth',                     'number',  'mm',    0, 0),
    ('description',          'Product Description',       'text',    NULL,    1, 1),
    ('short_description',    'Short Description',         'text',    NULL,    1, 0),
    ('load_capacity_kg',     'Load Capacity',             'number',  'kg',    0, 0),
    ('voltage_v',            'Voltage',                   'number',  'V',     0, 0),
    ('current_rating_a',     'Current Rating',            'number',  'A',     0, 0),
    ('ip_rating',            'IP Rating',                 'text',    NULL,    0, 0),
    ('material',             'Material',                  'text',    NULL,    1, 0),
    ('color',                'Color',                     'text',    NULL,    1, 0),
    ('compliance_standards', 'Compliance / Standards',    'text',    NULL,    1, 0),
    ('pack_quantity',        'Pack Quantity',             'number',  'units', 0, 0),
    ('warranty_years',       'Warranty',                  'number',  'years', 0, 0),
    ('is_hazmat',            'Hazardous Material',        'boolean', NULL,    0, 0),
    ('release_date',         'Release Date',              'date',    NULL,    0, 0),
    ('unit_price_usd',       'Unit Price (USD)',          'number',  'USD',   0, 0),
    ('min_order_qty',        'Minimum Order Quantity',    'number',  'units', 0, 0),
    ('lead_time_days',       'Lead Time',                 'number',  'days',  0, 0);

-- ---------------------------------------------------------------------------
-- Products
-- ---------------------------------------------------------------------------
INSERT INTO Products (sku, product_name, brand, status) VALUES
    -- Industrial Equipment
    ('APEX-DIST-IE-001', 'TorqueMaster 1/2" Drive Impact Wrench',         'Apex Distribution', 'active'),
    ('APEX-DIST-IE-002', 'HeavyLift Hydraulic Pallet Jack 3000kg',        'Apex Distribution', 'active'),
    ('APEX-DIST-IE-003', 'ProCut 14" Angle Grinder 2400W',               'Apex Distribution', 'active'),
    ('APEX-DIST-IE-004', 'VertiDrill Industrial Pillar Drill Press',      'Apex Distribution', 'active'),
    -- Safety & PPE
    ('APEX-DIST-PP-001', 'SafeGuard EN397 Industrial Hard Hat',           'Apex Distribution', 'active'),
    ('APEX-DIST-PP-002', 'ClearView Anti-Fog Safety Goggles EN166',       'Apex Distribution', 'active'),
    ('APEX-DIST-PP-003', 'FlexShield Hi-Vis Class 3 Safety Vest',         'Apex Distribution', 'active'),
    ('APEX-DIST-PP-004', 'DuraGrip Cut-Resistant Gloves Level D',         'Apex Distribution', 'active'),
    ('APEX-DIST-PP-005', 'SteelToe S3 Safety Boot',                      'Apex Distribution', 'active'),
    -- Packaging Materials
    ('APEX-DIST-PM-001', 'CorruPak Double-Wall Box 600x400x400mm',        'Apex Distribution', 'active'),
    ('APEX-DIST-PM-002', 'CorruPak Triple-Wall Export Box 800x600x600mm', 'Apex Distribution', 'active'),
    ('APEX-DIST-PM-003', 'XtendWrap 23-Micron Stretch Film 500mm Roll',  'Apex Distribution', 'active'),
    ('APEX-DIST-PM-004', 'BubblePro 100m Bubble Wrap Roll 600mm',        'Apex Distribution', 'active'),
    -- Logistics Supplies
    ('APEX-DIST-LS-001', 'EuroPal 1200x1000mm Hardwood Pallet',          'Apex Distribution', 'active'),
    ('APEX-DIST-LS-002', 'ThermalPrint 100x150mm Shipping Labels x1000',  'Apex Distribution', 'active'),
    ('APEX-DIST-LS-003', 'StrapMate 19mm Polypropylene Banding Kit',     'Apex Distribution', 'active'),
    -- Electrical Components
    ('APEX-DIST-EC-001', 'CableArm 32A 3-Phase Cable Tray Busbar',       'Apex Distribution', 'active'),
    ('APEX-DIST-EC-002', 'CircuitShield 63A 3-Pole MCB Type C',          'Apex Distribution', 'active'),
    ('APEX-DIST-EC-003', 'FlexDuct 25mm Cable Management Trunking 2m',   'Apex Distribution', 'active'),
    -- Discontinued
    ('APEX-DIST-IE-005', 'LegacyLift Manual Chain Hoist 1000kg (v1)',    'Apex Distribution', 'discontinued');

-- ---------------------------------------------------------------------------
-- ProductCategories
-- ---------------------------------------------------------------------------
INSERT INTO ProductCategories (product_id, category_id, is_primary)
SELECT p.product_id, c.category_id, 1
FROM Products p CROSS JOIN Categories c
WHERE (p.sku='APEX-DIST-IE-001' AND c.category_code='power-tools')
   OR (p.sku='APEX-DIST-IE-002' AND c.category_code='heavy-machinery')
   OR (p.sku='APEX-DIST-IE-003' AND c.category_code='power-tools')
   OR (p.sku='APEX-DIST-IE-004' AND c.category_code='heavy-machinery')
   OR (p.sku='APEX-DIST-IE-005' AND c.category_code='heavy-machinery')
   OR (p.sku='APEX-DIST-PP-001' AND c.category_code='head-protection')
   OR (p.sku='APEX-DIST-PP-002' AND c.category_code='eye-protection')
   OR (p.sku='APEX-DIST-PP-003' AND c.category_code='protective-clothing')
   OR (p.sku='APEX-DIST-PP-004' AND c.category_code='protective-clothing')
   OR (p.sku='APEX-DIST-PP-005' AND c.category_code='protective-clothing')
   OR (p.sku='APEX-DIST-PM-001' AND c.category_code='corrugated-boxes')
   OR (p.sku='APEX-DIST-PM-002' AND c.category_code='corrugated-boxes')
   OR (p.sku='APEX-DIST-PM-003' AND c.category_code='stretch-wrap')
   OR (p.sku='APEX-DIST-PM-004' AND c.category_code='packaging-materials')
   OR (p.sku='APEX-DIST-LS-001' AND c.category_code='pallet-handling')
   OR (p.sku='APEX-DIST-LS-002' AND c.category_code='labels-marking')
   OR (p.sku='APEX-DIST-LS-003' AND c.category_code='logistics-supplies')
   OR (p.sku='APEX-DIST-EC-001' AND c.category_code='cable-management')
   OR (p.sku='APEX-DIST-EC-002' AND c.category_code='circuit-protection')
   OR (p.sku='APEX-DIST-EC-003' AND c.category_code='cable-management');

-- Tag tools/machinery into parent 'industrial-equipment'
INSERT INTO ProductCategories (product_id, category_id, is_primary)
SELECT p.product_id, c.category_id, 0
FROM Products p CROSS JOIN Categories c
WHERE p.sku IN ('APEX-DIST-IE-001','APEX-DIST-IE-002','APEX-DIST-IE-003',
                'APEX-DIST-IE-004','APEX-DIST-IE-005')
  AND c.category_code = 'industrial-equipment';

-- Tag PPE into parent 'safety-ppe'
INSERT INTO ProductCategories (product_id, category_id, is_primary)
SELECT p.product_id, c.category_id, 0
FROM Products p CROSS JOIN Categories c
WHERE p.sku IN ('APEX-DIST-PP-001','APEX-DIST-PP-002','APEX-DIST-PP-003',
                'APEX-DIST-PP-004','APEX-DIST-PP-005')
  AND c.category_code = 'safety-ppe';

-- Tag electrical items into parent 'electrical-components'
INSERT INTO ProductCategories (product_id, category_id, is_primary)
SELECT p.product_id, c.category_id, 0
FROM Products p CROSS JOIN Categories c
WHERE p.sku IN ('APEX-DIST-EC-001','APEX-DIST-EC-002','APEX-DIST-EC-003')
  AND c.category_code = 'electrical-components';

-- ---------------------------------------------------------------------------
-- ProductAttributeValues — APEX-DIST-IE-001 TorqueMaster Impact Wrench
-- ---------------------------------------------------------------------------
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, number_value, bool_value, date_value)
SELECT p.product_id, a.attribute_id, NULL,
    CASE a.attribute_code
        WHEN 'weight_kg'        THEN 4.20
        WHEN 'width_mm'         THEN 220
        WHEN 'height_mm'        THEN 310
        WHEN 'depth_mm'         THEN 90
        WHEN 'voltage_v'        THEN 230
        WHEN 'current_rating_a' THEN 12
        WHEN 'warranty_years'   THEN 2
        WHEN 'unit_price_usd'   THEN 285.00
        WHEN 'min_order_qty'    THEN 5
        WHEN 'lead_time_days'   THEN 3
    END,
    CASE a.attribute_code WHEN 'is_hazmat' THEN 0 END,
    CASE a.attribute_code WHEN 'release_date' THEN '2023-06-01' END
FROM Products p CROSS JOIN Attributes a
WHERE p.sku = 'APEX-DIST-IE-001'
  AND a.attribute_code IN ('weight_kg','width_mm','height_mm','depth_mm','voltage_v',
                           'current_rating_a','warranty_years','unit_price_usd',
                           'min_order_qty','lead_time_days','is_hazmat','release_date');

INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE a.attribute_code
        WHEN 'color'                THEN 'Yellow/Black'
        WHEN 'material'             THEN 'Glass-filled Nylon Housing, Steel Anvil'
        WHEN 'ip_rating'            THEN 'IP54'
        WHEN 'compliance_standards' THEN 'CE, EN 60745-1, RoHS'
        WHEN 'short_description'    THEN '1/2" drive electric impact wrench, 900 Nm torque, IP54'
        WHEN 'description'          THEN 'The TorqueMaster 1/2" Drive Impact Wrench delivers 900 Nm of fastening torque in a compact, ergonomic package. Ideal for automotive workshops, assembly lines, and heavy maintenance. Features variable speed trigger, electronic torque control, and an IP54-rated housing for dust and splash resistance. Sold in bulk packs of 5 for distribution to trade customers.'
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku = 'APEX-DIST-IE-001'
  AND a.attribute_code IN ('color','material','ip_rating','compliance_standards','short_description','description')
  AND l.language_code = 'en';

INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE a.attribute_code
        WHEN 'color'             THEN 'Jaune/Noir'
        WHEN 'short_description' THEN 'Cle a chocs electrique 1/2" 900 Nm, IP54'
        WHEN 'description'       THEN 'La cle a chocs TorqueMaster 1/2" delivre 900 Nm en format compact et ergonomique. Ideale pour les ateliers automobiles, lignes d''assemblage et maintenance lourde. Homologuee CE, IP54.'
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku = 'APEX-DIST-IE-001'
  AND a.attribute_code IN ('color','short_description','description')
  AND l.language_code = 'fr';

INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE a.attribute_code
        WHEN 'color'             THEN 'Gelb/Schwarz'
        WHEN 'short_description' THEN 'Elektro-Schlagschrauber 1/2" 900 Nm, IP54'
        WHEN 'description'       THEN 'Der TorqueMaster Schlagschrauber 1/2" liefert 900 Nm Anzugsmoment im kompakten ergonomischen Design. Ideal fur Kfz-Werkstatten, Montagebaender und schwere Wartung. CE-zertifiziert, IP54-Schutz.'
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku = 'APEX-DIST-IE-001'
  AND a.attribute_code IN ('color','short_description','description')
  AND l.language_code = 'de';

-- ---------------------------------------------------------------------------
-- ProductAttributeValues — APEX-DIST-IE-002 HeavyLift Pallet Jack
-- ---------------------------------------------------------------------------
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, number_value, bool_value, date_value)
SELECT p.product_id, a.attribute_id, NULL,
    CASE a.attribute_code
        WHEN 'weight_kg'        THEN 68.00
        WHEN 'width_mm'         THEN 540
        WHEN 'height_mm'        THEN 1250
        WHEN 'depth_mm'         THEN 850
        WHEN 'load_capacity_kg' THEN 3000
        WHEN 'warranty_years'   THEN 3
        WHEN 'unit_price_usd'   THEN 620.00
        WHEN 'min_order_qty'    THEN 2
        WHEN 'lead_time_days'   THEN 5
    END,
    CASE a.attribute_code WHEN 'is_hazmat' THEN 0 END,
    CASE a.attribute_code WHEN 'release_date' THEN '2022-09-01' END
FROM Products p CROSS JOIN Attributes a
WHERE p.sku = 'APEX-DIST-IE-002'
  AND a.attribute_code IN ('weight_kg','width_mm','height_mm','depth_mm','load_capacity_kg',
                           'warranty_years','unit_price_usd','min_order_qty','lead_time_days',
                           'is_hazmat','release_date');

INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE a.attribute_code
        WHEN 'color'                THEN 'Orange/Black'
        WHEN 'material'             THEN 'Reinforced Steel Frame, Polyurethane Wheels'
        WHEN 'compliance_standards' THEN 'EN 1757-2, CE, FEM 1.001'
        WHEN 'short_description'    THEN 'Manual hydraulic pallet jack, 3000 kg capacity, 1200x800mm forks'
        WHEN 'description'          THEN 'The HeavyLift Hydraulic Pallet Jack is engineered for intensive warehouse and distribution centre use. Rated at 3000 kg, it features a low-profile entry height of 85mm and polyurethane wheels for smooth movement on warehouse floors. Compliant with EN 1757-2. Ideal for loading bays and cross-docking operations. MOQ of 2 units for B2B orders.'
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku = 'APEX-DIST-IE-002'
  AND a.attribute_code IN ('color','material','compliance_standards','short_description','description')
  AND l.language_code = 'en';

-- ---------------------------------------------------------------------------
-- ProductAttributeValues — remaining products (bulk insert)
-- ---------------------------------------------------------------------------
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, number_value, bool_value, date_value)
SELECT p.product_id, a.attribute_id, NULL,
    CASE p.sku
        WHEN 'APEX-DIST-IE-003' THEN CASE a.attribute_code
            WHEN 'weight_kg'        THEN 6.10
            WHEN 'width_mm'         THEN 175
            WHEN 'height_mm'        THEN 360
            WHEN 'depth_mm'         THEN 120
            WHEN 'voltage_v'        THEN 230
            WHEN 'current_rating_a' THEN 12
            WHEN 'warranty_years'   THEN 2
            WHEN 'unit_price_usd'   THEN 195.00
            WHEN 'min_order_qty'    THEN 5
            WHEN 'lead_time_days'   THEN 3
            ELSE NULL END
        WHEN 'APEX-DIST-IE-004' THEN CASE a.attribute_code
            WHEN 'weight_kg'        THEN 92.00
            WHEN 'voltage_v'        THEN 400
            WHEN 'current_rating_a' THEN 16
            WHEN 'warranty_years'   THEN 3
            WHEN 'unit_price_usd'   THEN 1450.00
            WHEN 'min_order_qty'    THEN 1
            WHEN 'lead_time_days'   THEN 10
            ELSE NULL END
        WHEN 'APEX-DIST-PP-001' THEN CASE a.attribute_code
            WHEN 'weight_kg'      THEN 0.35
            WHEN 'warranty_years' THEN 1
            WHEN 'unit_price_usd' THEN 12.50
            WHEN 'min_order_qty'  THEN 50
            WHEN 'pack_quantity'  THEN 50
            WHEN 'lead_time_days' THEN 2
            ELSE NULL END
        WHEN 'APEX-DIST-PP-002' THEN CASE a.attribute_code
            WHEN 'weight_kg'      THEN 0.18
            WHEN 'warranty_years' THEN 1
            WHEN 'unit_price_usd' THEN 9.80
            WHEN 'min_order_qty'  THEN 100
            WHEN 'pack_quantity'  THEN 100
            WHEN 'lead_time_days' THEN 2
            ELSE NULL END
        WHEN 'APEX-DIST-PP-003' THEN CASE a.attribute_code
            WHEN 'weight_kg'      THEN 0.25
            WHEN 'warranty_years' THEN 1
            WHEN 'unit_price_usd' THEN 18.00
            WHEN 'min_order_qty'  THEN 25
            WHEN 'pack_quantity'  THEN 25
            WHEN 'lead_time_days' THEN 2
            ELSE NULL END
        WHEN 'APEX-DIST-PP-004' THEN CASE a.attribute_code
            WHEN 'weight_kg'      THEN 0.22
            WHEN 'unit_price_usd' THEN 22.00
            WHEN 'min_order_qty'  THEN 24
            WHEN 'pack_quantity'  THEN 12
            WHEN 'lead_time_days' THEN 3
            ELSE NULL END
        WHEN 'APEX-DIST-PP-005' THEN CASE a.attribute_code
            WHEN 'weight_kg'      THEN 1.45
            WHEN 'warranty_years' THEN 1
            WHEN 'unit_price_usd' THEN 68.00
            WHEN 'min_order_qty'  THEN 12
            WHEN 'lead_time_days' THEN 5
            ELSE NULL END
        WHEN 'APEX-DIST-PM-001' THEN CASE a.attribute_code
            WHEN 'weight_kg'      THEN 0.72
            WHEN 'width_mm'       THEN 600
            WHEN 'height_mm'      THEN 400
            WHEN 'depth_mm'       THEN 400
            WHEN 'unit_price_usd' THEN 3.20
            WHEN 'min_order_qty'  THEN 50
            WHEN 'pack_quantity'  THEN 25
            WHEN 'lead_time_days' THEN 2
            ELSE NULL END
        WHEN 'APEX-DIST-PM-002' THEN CASE a.attribute_code
            WHEN 'weight_kg'      THEN 1.40
            WHEN 'width_mm'       THEN 800
            WHEN 'height_mm'      THEN 600
            WHEN 'depth_mm'       THEN 600
            WHEN 'unit_price_usd' THEN 6.90
            WHEN 'min_order_qty'  THEN 25
            WHEN 'pack_quantity'  THEN 10
            WHEN 'lead_time_days' THEN 3
            ELSE NULL END
        WHEN 'APEX-DIST-PM-003' THEN CASE a.attribute_code
            WHEN 'weight_kg'      THEN 2.90
            WHEN 'unit_price_usd' THEN 14.50
            WHEN 'min_order_qty'  THEN 36
            WHEN 'pack_quantity'  THEN 6
            WHEN 'lead_time_days' THEN 2
            ELSE NULL END
        WHEN 'APEX-DIST-PM-004' THEN CASE a.attribute_code
            WHEN 'weight_kg'      THEN 3.10
            WHEN 'unit_price_usd' THEN 28.00
            WHEN 'min_order_qty'  THEN 12
            WHEN 'lead_time_days' THEN 3
            ELSE NULL END
        WHEN 'APEX-DIST-LS-001' THEN CASE a.attribute_code
            WHEN 'weight_kg'        THEN 22.00
            WHEN 'width_mm'         THEN 1200
            WHEN 'depth_mm'         THEN 1000
            WHEN 'load_capacity_kg' THEN 1500
            WHEN 'unit_price_usd'   THEN 14.00
            WHEN 'min_order_qty'    THEN 10
            WHEN 'lead_time_days'   THEN 5
            ELSE NULL END
        WHEN 'APEX-DIST-LS-002' THEN CASE a.attribute_code
            WHEN 'weight_kg'      THEN 1.80
            WHEN 'pack_quantity'  THEN 1000
            WHEN 'unit_price_usd' THEN 38.00
            WHEN 'min_order_qty'  THEN 5
            WHEN 'lead_time_days' THEN 2
            ELSE NULL END
        WHEN 'APEX-DIST-LS-003' THEN CASE a.attribute_code
            WHEN 'weight_kg'      THEN 4.50
            WHEN 'unit_price_usd' THEN 52.00
            WHEN 'min_order_qty'  THEN 10
            WHEN 'lead_time_days' THEN 3
            ELSE NULL END
        WHEN 'APEX-DIST-EC-001' THEN CASE a.attribute_code
            WHEN 'weight_kg'        THEN 3.60
            WHEN 'voltage_v'        THEN 400
            WHEN 'current_rating_a' THEN 32
            WHEN 'warranty_years'   THEN 5
            WHEN 'unit_price_usd'   THEN 185.00
            WHEN 'min_order_qty'    THEN 2
            WHEN 'lead_time_days'   THEN 7
            ELSE NULL END
        WHEN 'APEX-DIST-EC-002' THEN CASE a.attribute_code
            WHEN 'weight_kg'        THEN 0.45
            WHEN 'voltage_v'        THEN 400
            WHEN 'current_rating_a' THEN 63
            WHEN 'warranty_years'   THEN 5
            WHEN 'unit_price_usd'   THEN 48.00
            WHEN 'min_order_qty'    THEN 10
            WHEN 'pack_quantity'    THEN 10
            WHEN 'lead_time_days'   THEN 5
            ELSE NULL END
        WHEN 'APEX-DIST-EC-003' THEN CASE a.attribute_code
            WHEN 'weight_kg'      THEN 1.20
            WHEN 'width_mm'       THEN 25
            WHEN 'height_mm'      THEN 25
            WHEN 'depth_mm'       THEN 2000
            WHEN 'unit_price_usd' THEN 7.50
            WHEN 'min_order_qty'  THEN 20
            WHEN 'lead_time_days' THEN 3
            ELSE NULL END
        ELSE NULL
    END,
    CASE a.attribute_code WHEN 'is_hazmat' THEN 0 END,
    CASE p.sku
        WHEN 'APEX-DIST-IE-003' THEN CASE a.attribute_code WHEN 'release_date' THEN '2023-01-15' END
        WHEN 'APEX-DIST-IE-004' THEN CASE a.attribute_code WHEN 'release_date' THEN '2022-06-01' END
        ELSE NULL
    END
FROM Products p CROSS JOIN Attributes a
WHERE p.sku IN ('APEX-DIST-IE-003','APEX-DIST-IE-004',
                'APEX-DIST-PP-001','APEX-DIST-PP-002','APEX-DIST-PP-003',
                'APEX-DIST-PP-004','APEX-DIST-PP-005',
                'APEX-DIST-PM-001','APEX-DIST-PM-002','APEX-DIST-PM-003','APEX-DIST-PM-004',
                'APEX-DIST-LS-001','APEX-DIST-LS-002','APEX-DIST-LS-003',
                'APEX-DIST-EC-001','APEX-DIST-EC-002','APEX-DIST-EC-003')
  AND a.attribute_code IN ('weight_kg','width_mm','height_mm','depth_mm','load_capacity_kg',
                           'voltage_v','current_rating_a','warranty_years','unit_price_usd',
                           'min_order_qty','pack_quantity','lead_time_days','is_hazmat','release_date')
  AND CASE p.sku
        WHEN 'APEX-DIST-IE-003' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 1 WHEN 'width_mm' THEN 1 WHEN 'height_mm' THEN 1 WHEN 'depth_mm' THEN 1 WHEN 'voltage_v' THEN 1 WHEN 'current_rating_a' THEN 1 WHEN 'warranty_years' THEN 1 WHEN 'unit_price_usd' THEN 1 WHEN 'min_order_qty' THEN 1 WHEN 'lead_time_days' THEN 1 WHEN 'is_hazmat' THEN 1 WHEN 'release_date' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-IE-004' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 1 WHEN 'voltage_v' THEN 1 WHEN 'current_rating_a' THEN 1 WHEN 'warranty_years' THEN 1 WHEN 'unit_price_usd' THEN 1 WHEN 'min_order_qty' THEN 1 WHEN 'lead_time_days' THEN 1 WHEN 'is_hazmat' THEN 1 WHEN 'release_date' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-PP-001' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 1 WHEN 'warranty_years' THEN 1 WHEN 'unit_price_usd' THEN 1 WHEN 'min_order_qty' THEN 1 WHEN 'pack_quantity' THEN 1 WHEN 'lead_time_days' THEN 1 WHEN 'is_hazmat' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-PP-002' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 1 WHEN 'warranty_years' THEN 1 WHEN 'unit_price_usd' THEN 1 WHEN 'min_order_qty' THEN 1 WHEN 'pack_quantity' THEN 1 WHEN 'lead_time_days' THEN 1 WHEN 'is_hazmat' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-PP-003' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 1 WHEN 'warranty_years' THEN 1 WHEN 'unit_price_usd' THEN 1 WHEN 'min_order_qty' THEN 1 WHEN 'pack_quantity' THEN 1 WHEN 'lead_time_days' THEN 1 WHEN 'is_hazmat' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-PP-004' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 1 WHEN 'unit_price_usd' THEN 1 WHEN 'min_order_qty' THEN 1 WHEN 'pack_quantity' THEN 1 WHEN 'lead_time_days' THEN 1 WHEN 'is_hazmat' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-PP-005' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 1 WHEN 'warranty_years' THEN 1 WHEN 'unit_price_usd' THEN 1 WHEN 'min_order_qty' THEN 1 WHEN 'lead_time_days' THEN 1 WHEN 'is_hazmat' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-PM-001' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 1 WHEN 'width_mm' THEN 1 WHEN 'height_mm' THEN 1 WHEN 'depth_mm' THEN 1 WHEN 'unit_price_usd' THEN 1 WHEN 'min_order_qty' THEN 1 WHEN 'pack_quantity' THEN 1 WHEN 'lead_time_days' THEN 1 WHEN 'is_hazmat' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-PM-002' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 1 WHEN 'width_mm' THEN 1 WHEN 'height_mm' THEN 1 WHEN 'depth_mm' THEN 1 WHEN 'unit_price_usd' THEN 1 WHEN 'min_order_qty' THEN 1 WHEN 'pack_quantity' THEN 1 WHEN 'lead_time_days' THEN 1 WHEN 'is_hazmat' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-PM-003' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 1 WHEN 'unit_price_usd' THEN 1 WHEN 'min_order_qty' THEN 1 WHEN 'pack_quantity' THEN 1 WHEN 'lead_time_days' THEN 1 WHEN 'is_hazmat' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-PM-004' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 1 WHEN 'unit_price_usd' THEN 1 WHEN 'min_order_qty' THEN 1 WHEN 'lead_time_days' THEN 1 WHEN 'is_hazmat' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-LS-001' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 1 WHEN 'width_mm' THEN 1 WHEN 'depth_mm' THEN 1 WHEN 'load_capacity_kg' THEN 1 WHEN 'unit_price_usd' THEN 1 WHEN 'min_order_qty' THEN 1 WHEN 'lead_time_days' THEN 1 WHEN 'is_hazmat' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-LS-002' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 1 WHEN 'pack_quantity' THEN 1 WHEN 'unit_price_usd' THEN 1 WHEN 'min_order_qty' THEN 1 WHEN 'lead_time_days' THEN 1 WHEN 'is_hazmat' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-LS-003' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 1 WHEN 'unit_price_usd' THEN 1 WHEN 'min_order_qty' THEN 1 WHEN 'lead_time_days' THEN 1 WHEN 'is_hazmat' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-EC-001' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 1 WHEN 'voltage_v' THEN 1 WHEN 'current_rating_a' THEN 1 WHEN 'warranty_years' THEN 1 WHEN 'unit_price_usd' THEN 1 WHEN 'min_order_qty' THEN 1 WHEN 'lead_time_days' THEN 1 WHEN 'is_hazmat' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-EC-002' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 1 WHEN 'voltage_v' THEN 1 WHEN 'current_rating_a' THEN 1 WHEN 'warranty_years' THEN 1 WHEN 'unit_price_usd' THEN 1 WHEN 'min_order_qty' THEN 1 WHEN 'pack_quantity' THEN 1 WHEN 'lead_time_days' THEN 1 WHEN 'is_hazmat' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-EC-003' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 1 WHEN 'width_mm' THEN 1 WHEN 'height_mm' THEN 1 WHEN 'depth_mm' THEN 1 WHEN 'unit_price_usd' THEN 1 WHEN 'min_order_qty' THEN 1 WHEN 'lead_time_days' THEN 1 WHEN 'is_hazmat' THEN 1 ELSE 0 END
        ELSE 0
      END = 1;

-- Text attributes (English) for remaining products
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE p.sku
      WHEN 'APEX-DIST-IE-003' THEN CASE a.attribute_code
        WHEN 'short_description'    THEN '14" angle grinder, 2400W, 6600 rpm, disc spindle lock'
        WHEN 'description'          THEN 'The ProCut 14" Angle Grinder is built for continuous heavy-duty cutting and grinding in fabrication and construction environments. 2400W motor with soft-start and electronic overload protection. Includes side handle, flange set, and grinding disc. CE and EN 60745-2-3 compliant.'
        WHEN 'color'                THEN 'Red/Black'
        WHEN 'material'             THEN 'Die-cast Aluminium Gearbox, Reinforced Plastic Housing'
        WHEN 'compliance_standards' THEN 'CE, EN 60745-2-3, RoHS'
        ELSE NULL END
      WHEN 'APEX-DIST-IE-004' THEN CASE a.attribute_code
        WHEN 'short_description'    THEN 'Industrial pillar drill press, 400V 3-phase, 16-speed, 1500W'
        WHEN 'description'          THEN 'The VertiDrill Industrial Pillar Drill Press offers 16 spindle speeds for precision drilling in metal, wood, and plastics. 400V 3-phase motor, laser cross-hair guide, and cast-iron worktable with T-slots. Suitable for workshop and manufacturing facility use.'
        WHEN 'color'                THEN 'Green/Grey'
        WHEN 'material'             THEN 'Cast Iron Table and Column, Steel Spindle'
        WHEN 'compliance_standards' THEN 'CE, EN 12717, Machinery Directive 2006/42/EC'
        ELSE NULL END
      WHEN 'APEX-DIST-PP-001' THEN CASE a.attribute_code
        WHEN 'short_description'    THEN 'EN397 industrial hard hat, 6-point suspension, HDPE shell, pack of 50'
        WHEN 'description'          THEN 'SafeGuard EN397 Hard Hat provides certified head protection for construction, warehousing, and utilities. High-density polyethylene shell with 6-point polyester suspension and ratchet adjustment. Rated for lateral deformation, penetration, and flammability. Sold in packs of 50.'
        WHEN 'color'                THEN 'Hi-Vis Yellow'
        WHEN 'material'             THEN 'HDPE Shell, Polyester Suspension'
        WHEN 'compliance_standards' THEN 'EN 397:2012+A1:2012, CE'
        ELSE NULL END
      WHEN 'APEX-DIST-PP-002' THEN CASE a.attribute_code
        WHEN 'short_description'    THEN 'EN166 anti-fog safety goggles, indirect ventilation, UV400, pack of 100'
        WHEN 'description'          THEN 'ClearView Anti-Fog Goggles provide reliable eye protection against dust, liquid splashes, and UV radiation. Indirect ventilation prevents fogging. Soft PVC frame for all-day comfort. Certified to EN 166:2002. Sold in packs of 100.'
        WHEN 'color'                THEN 'Clear/Grey'
        WHEN 'material'             THEN 'Polycarbonate Lens, PVC Frame'
        WHEN 'compliance_standards' THEN 'EN 166:2002, EN 170:2002, CE'
        ELSE NULL END
      WHEN 'APEX-DIST-PP-003' THEN CASE a.attribute_code
        WHEN 'short_description'    THEN 'EN ISO 20471 Class 3 hi-vis safety vest, fluorescent yellow, pack of 25'
        WHEN 'description'          THEN 'FlexShield Hi-Vis Class 3 Safety Vest meets the highest EN ISO 20471 visibility rating. 3M Scotchlite reflective tape on shoulders and waist. Lightweight polyester mesh for breathability. Adjustable Velcro side panels. Sold in packs of 25 for site issue.'
        WHEN 'color'                THEN 'Fluorescent Yellow'
        WHEN 'material'             THEN '100% Polyester Mesh, 3M Scotchlite Tape'
        WHEN 'compliance_standards' THEN 'EN ISO 20471:2013+A1:2016 Class 3, CE'
        ELSE NULL END
      WHEN 'APEX-DIST-PP-004' THEN CASE a.attribute_code
        WHEN 'short_description'    THEN 'Level D cut-resistant gloves EN388 4544D, palm-coated nitrile, dozen pairs'
        WHEN 'description'          THEN 'DuraGrip Cut-Resistant Gloves provide Level D cut protection (EN388:2016) for metal fabrication, glass handling, and sheet metal work. HPPE liner with palm-coated sandy nitrile for excellent grip in wet and oily conditions. Sold in dozens.'
        WHEN 'color'                THEN 'Grey/Black'
        WHEN 'material'             THEN 'HPPE Liner, Sandy Nitrile Palm Coating'
        WHEN 'compliance_standards' THEN 'EN 388:2016+A1:2018 (4544D), CE Category II'
        ELSE NULL END
      WHEN 'APEX-DIST-PP-005' THEN CASE a.attribute_code
        WHEN 'short_description'    THEN 'S3 SRC steel-toe safety boot, composite midsole, ESD'
        WHEN 'description'          THEN 'SteelToe S3 Safety Boot delivers full S3 protection: steel toecap, steel midsole, antistatic (ESD), water-resistant upper, and energy-absorbing heel. Slip-resistant SRC-rated outsole. Suitable for construction, logistics, and manufacturing environments.'
        WHEN 'color'                THEN 'Black'
        WHEN 'material'             THEN 'Full-grain Leather Upper, Steel Toecap, PU/Rubber Outsole'
        WHEN 'compliance_standards' THEN 'EN ISO 20345:2011 S3 SRC ESD, CE'
        ELSE NULL END
      WHEN 'APEX-DIST-PM-001' THEN CASE a.attribute_code
        WHEN 'short_description'    THEN 'Double-wall corrugated box 600x400x400mm, pack of 25'
        WHEN 'description'          THEN 'CorruPak Double-Wall Boxes are manufactured from BC-flute corrugated board for heavy-duty shipping and storage. Capacity up to 30 kg. Pre-scored and flat-packed for efficient storage. Ideal for auto parts, hardware, and industrial component distribution.'
        WHEN 'color'                THEN 'Brown'
        WHEN 'material'             THEN 'BC-flute Double-Wall Corrugated Board'
        ELSE NULL END
      WHEN 'APEX-DIST-PM-002' THEN CASE a.attribute_code
        WHEN 'short_description'    THEN 'Triple-wall export box 800x600x600mm, pack of 10'
        WHEN 'description'          THEN 'CorruPak Triple-Wall Export Boxes are built for international freight requiring maximum protection. ECT 44 edge crush test rating. Suitable for machinery parts and bulk industrial goods. Pack of 10 flat-packed boxes.'
        WHEN 'color'                THEN 'Brown'
        WHEN 'material'             THEN 'AAA-flute Triple-Wall Corrugated Board'
        ELSE NULL END
      WHEN 'APEX-DIST-PM-003' THEN CASE a.attribute_code
        WHEN 'short_description'    THEN '23-micron cast stretch film, 500mm x 300m, 6-roll pack'
        WHEN 'description'          THEN 'XtendWrap 23-Micron Stretch Film offers excellent load containment for pallet wrapping in warehouses and distribution centres. Cast film for consistent thickness, low noise, and clear visibility. 300m per roll, 6 rolls per pack.'
        WHEN 'material'             THEN 'Linear Low-Density Polyethylene (LLDPE)'
        ELSE NULL END
      WHEN 'APEX-DIST-PM-004' THEN CASE a.attribute_code
        WHEN 'short_description'    THEN '600mm wide bubble wrap roll, 100m, large 25mm bubbles'
        WHEN 'description'          THEN 'BubblePro 100m Bubble Wrap provides superior cushioning for fragile industrial components, glassware, and electronics in transit. Large 25mm bubbles for maximum shock absorption. 600mm wide, perforated every 300mm.'
        WHEN 'material'             THEN 'Low-Density Polyethylene (LDPE)'
        ELSE NULL END
      WHEN 'APEX-DIST-LS-001' THEN CASE a.attribute_code
        WHEN 'short_description'    THEN 'EUR/EPAL 1200x1000mm hardwood pallet, 1500 kg capacity, ISPM 15'
        WHEN 'description'          THEN 'EuroPal EPAL-certified hardwood pallets conform to EUR1 specifications (1200x1000mm). Heat-treated to ISPM 15 for international shipment. Load capacity 1500 kg static. Suitable for racking and floor storage. Supplied in packs of 10.'
        WHEN 'material'             THEN 'Heat-treated European Hardwood'
        WHEN 'compliance_standards' THEN 'EPAL, ISPM 15, EUR1'
        ELSE NULL END
      WHEN 'APEX-DIST-LS-002' THEN CASE a.attribute_code
        WHEN 'short_description'    THEN 'Direct thermal shipping labels 100x150mm, 1000/roll, 25mm core'
        WHEN 'description'          THEN 'ThermalPrint Labels are compatible with Zebra, Honeywell, TSC, and all standard direct thermal label printers. Permanent acrylic adhesive on white gloss face. 1000 labels per roll, 25mm core. Suitable for parcel, carrier, and warehouse logistics labelling.'
        WHEN 'material'             THEN 'Direct Thermal Paper, Permanent Acrylic Adhesive'
        ELSE NULL END
      WHEN 'APEX-DIST-LS-003' THEN CASE a.attribute_code
        WHEN 'short_description'    THEN '19mm polypropylene banding kit, tensioner, sealer, 1000m coil'
        WHEN 'description'          THEN 'StrapMate PP Banding Kit includes a 1000m coil of 19mm polypropylene strapping, a manual tensioner, a friction-weld sealer, and 1000 metal seals. Tensile strength 430 kg. Ideal for securing boxes, cartons, and pallets for transport.'
        WHEN 'material'             THEN 'Polypropylene Strapping, Steel Seals'
        ELSE NULL END
      WHEN 'APEX-DIST-EC-001' THEN CASE a.attribute_code
        WHEN 'short_description'    THEN '3-phase 32A cable tray busbar, 400V, 2m section, IP2X'
        WHEN 'description'          THEN 'CableArm 32A Busbar System provides a modular, low-impedance power distribution solution for industrial panels and distribution boards. Pre-assembled 3-phase + neutral copper busbar with IP2X touch-safe covers. 2-metre sections, rated at 400V AC.'
        WHEN 'color'                THEN 'Grey'
        WHEN 'material'             THEN 'Copper Busbars, Glass-filled Polyamide Housing'
        WHEN 'ip_rating'            THEN 'IP2X'
        WHEN 'compliance_standards' THEN 'IEC 60439-1, CE'
        ELSE NULL END
      WHEN 'APEX-DIST-EC-002' THEN CASE a.attribute_code
        WHEN 'short_description'    THEN '63A 3-pole Type C MCB, 400V AC, 10 kA, pack of 10'
        WHEN 'description'          THEN 'CircuitShield 63A Type C MCBs protect circuits from overloads and short circuits in industrial and commercial electrical installations. DIN rail mount. Breaking capacity 10 kA at 400V AC. Compliant with IEC 60898-1. Sold in packs of 10.'
        WHEN 'color'                THEN 'Black'
        WHEN 'material'             THEN 'Thermoplastic Housing, Silver Alloy Contacts'
        WHEN 'compliance_standards' THEN 'IEC 60898-1, CE, RoHS'
        ELSE NULL END
      WHEN 'APEX-DIST-EC-003' THEN CASE a.attribute_code
        WHEN 'short_description'    THEN '25x25mm PVC cable trunking, 2m snap-lid section, flame-retardant'
        WHEN 'description'          THEN 'FlexDuct 25mm PVC Trunking provides a neat and secure routing solution for electrical cables in control panels and equipment enclosures. Slot-wall design for easy wire exit. Snap-fit removable lid. Flame-retardant to UL94-V0. Supplied in 2-metre lengths.'
        WHEN 'color'                THEN 'White'
        WHEN 'material'             THEN 'Flame-retardant PVC'
        WHEN 'compliance_standards' THEN 'UL94-V0, IEC 60670, CE'
        ELSE NULL END
      ELSE NULL
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE l.language_code = 'en'
  AND p.sku IN ('APEX-DIST-IE-003','APEX-DIST-IE-004',
                'APEX-DIST-PP-001','APEX-DIST-PP-002','APEX-DIST-PP-003',
                'APEX-DIST-PP-004','APEX-DIST-PP-005',
                'APEX-DIST-PM-001','APEX-DIST-PM-002','APEX-DIST-PM-003','APEX-DIST-PM-004',
                'APEX-DIST-LS-001','APEX-DIST-LS-002','APEX-DIST-LS-003',
                'APEX-DIST-EC-001','APEX-DIST-EC-002','APEX-DIST-EC-003')
  AND a.attribute_code IN ('short_description','description','color','material',
                           'ip_rating','compliance_standards')
  AND CASE p.sku
        WHEN 'APEX-DIST-IE-003' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'material' THEN 1 WHEN 'compliance_standards' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-IE-004' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'material' THEN 1 WHEN 'compliance_standards' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-PP-001' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'material' THEN 1 WHEN 'compliance_standards' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-PP-002' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'material' THEN 1 WHEN 'compliance_standards' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-PP-003' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'material' THEN 1 WHEN 'compliance_standards' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-PP-004' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'material' THEN 1 WHEN 'compliance_standards' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-PP-005' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'material' THEN 1 WHEN 'compliance_standards' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-PM-001' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'material' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-PM-002' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'material' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-PM-003' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'material' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-PM-004' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'material' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-LS-001' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'material' THEN 1 WHEN 'compliance_standards' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-LS-002' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'material' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-LS-003' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'material' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-EC-001' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'material' THEN 1 WHEN 'ip_rating' THEN 1 WHEN 'compliance_standards' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-EC-002' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'material' THEN 1 WHEN 'compliance_standards' THEN 1 ELSE 0 END
        WHEN 'APEX-DIST-EC-003' THEN CASE a.attribute_code WHEN 'short_description' THEN 1 WHEN 'description' THEN 1 WHEN 'color' THEN 1 WHEN 'material' THEN 1 WHEN 'compliance_standards' THEN 1 ELSE 0 END
        ELSE 0
      END = 1;

-- Discontinued product attributes
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, number_value)
SELECT p.product_id, a.attribute_id, NULL,
    CASE a.attribute_code
        WHEN 'weight_kg'        THEN 48.00
        WHEN 'load_capacity_kg' THEN 1000
        WHEN 'unit_price_usd'   THEN 0
        WHEN 'min_order_qty'    THEN 1
    END
FROM Products p CROSS JOIN Attributes a
WHERE p.sku = 'APEX-DIST-IE-005'
  AND a.attribute_code IN ('weight_kg','load_capacity_kg','unit_price_usd','min_order_qty');

INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE a.attribute_code
        WHEN 'short_description' THEN 'Discontinued — replaced by LegacyLift v2'
        WHEN 'description'       THEN 'LegacyLift Manual Chain Hoist v1 — discontinued. Replaced by the updated LegacyLift v2 with EN 13157 compliance. Final stock may be available through the outlet channel.'
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku = 'APEX-DIST-IE-005'
  AND a.attribute_code IN ('short_description','description')
  AND l.language_code = 'en';

-- ---------------------------------------------------------------------------
-- ProductChannels
-- ---------------------------------------------------------------------------
-- B2B and wholesale for all active products
INSERT INTO ProductChannels (product_id, channel_id, is_published, published_at)
SELECT p.product_id, c.channel_id, 1, SYSUTCDATETIME()
FROM Products p CROSS JOIN Channels c
WHERE p.status = 'active'
  AND c.channel_code IN ('b2b','wholesale');

-- Web channel for consumable/smaller items
INSERT INTO ProductChannels (product_id, channel_id, is_published, published_at)
SELECT p.product_id, c.channel_id, 1, SYSUTCDATETIME()
FROM Products p CROSS JOIN Channels c
WHERE p.sku IN ('APEX-DIST-PP-001','APEX-DIST-PP-002','APEX-DIST-PP-003',
                'APEX-DIST-PP-004','APEX-DIST-PP-005',
                'APEX-DIST-PM-001','APEX-DIST-PM-002','APEX-DIST-PM-003','APEX-DIST-PM-004',
                'APEX-DIST-LS-002','APEX-DIST-LS-003',
                'APEX-DIST-EC-002','APEX-DIST-EC-003')
  AND c.channel_code = 'web';

-- OEM channel for heavy industrial and electrical equipment
INSERT INTO ProductChannels (product_id, channel_id, is_published, published_at)
SELECT p.product_id, c.channel_id, 1, SYSUTCDATETIME()
FROM Products p CROSS JOIN Channels c
WHERE p.sku IN ('APEX-DIST-IE-001','APEX-DIST-IE-002','APEX-DIST-IE-003','APEX-DIST-IE-004',
                'APEX-DIST-EC-001','APEX-DIST-EC-002')
  AND c.channel_code = 'oem';

-- Discontinued product on outlet, not published
INSERT INTO ProductChannels (product_id, channel_id, is_published)
SELECT p.product_id, c.channel_id, 0
FROM Products p CROSS JOIN Channels c
WHERE p.sku = 'APEX-DIST-IE-005' AND c.channel_code = 'outlet';

-- ---------------------------------------------------------------------------
-- MediaAssets
-- ---------------------------------------------------------------------------
-- Front image for all active products
INSERT INTO MediaAssets (product_id, asset_type, file_name, url, alt_text, sort_order)
SELECT p.product_id, 'image',
    p.sku + '-front.jpg',
    'https://cdn.apex-dist.example/products/' + p.sku + '-front.jpg',
    p.product_name + ' front view',
    1
FROM Products p WHERE p.status = 'active';

-- Detail/close-up shots for key products
INSERT INTO MediaAssets (product_id, asset_type, file_name, url, alt_text, sort_order)
SELECT p.product_id, 'image',
    p.sku + '-detail.jpg',
    'https://cdn.apex-dist.example/products/' + p.sku + '-detail.jpg',
    p.product_name + ' detail view',
    2
FROM Products p
WHERE p.sku IN ('APEX-DIST-IE-001','APEX-DIST-IE-002','APEX-DIST-IE-003','APEX-DIST-IE-004',
                'APEX-DIST-PP-004','APEX-DIST-PP-005','APEX-DIST-EC-001','APEX-DIST-EC-002');

-- In-use/site shots for PPE and tools
INSERT INTO MediaAssets (product_id, asset_type, file_name, url, alt_text, sort_order)
SELECT p.product_id, 'image',
    p.sku + '-inuse.jpg',
    'https://cdn.apex-dist.example/products/' + p.sku + '-inuse.jpg',
    p.product_name + ' in use on site',
    3
FROM Products p
WHERE p.sku IN ('APEX-DIST-PP-001','APEX-DIST-PP-002','APEX-DIST-PP-003',
                'APEX-DIST-IE-001','APEX-DIST-IE-002');

-- English technical datasheets for regulated/certified products
INSERT INTO MediaAssets (product_id, asset_type, file_name, url, alt_text, sort_order, language_id)
SELECT p.product_id, 'document',
    p.sku + '-datasheet-en.pdf',
    'https://cdn.apex-dist.example/docs/' + p.sku + '-datasheet-en.pdf',
    p.product_name + ' Datasheet (EN)',
    10,
    l.language_id
FROM Products p CROSS JOIN Languages l
WHERE l.language_code = 'en'
  AND p.sku IN ('APEX-DIST-IE-001','APEX-DIST-IE-002','APEX-DIST-IE-003','APEX-DIST-IE-004',
                'APEX-DIST-PP-001','APEX-DIST-PP-002','APEX-DIST-PP-003',
                'APEX-DIST-PP-004','APEX-DIST-PP-005',
                'APEX-DIST-EC-001','APEX-DIST-EC-002');

-- French datasheets for products sold in French-speaking markets
INSERT INTO MediaAssets (product_id, asset_type, file_name, url, alt_text, sort_order, language_id)
SELECT p.product_id, 'document',
    p.sku + '-datasheet-fr.pdf',
    'https://cdn.apex-dist.example/docs/' + p.sku + '-datasheet-fr.pdf',
    p.product_name + ' Fiche technique (FR)',
    11,
    l.language_id
FROM Products p CROSS JOIN Languages l
WHERE l.language_code = 'fr'
  AND p.sku IN ('APEX-DIST-IE-001','APEX-DIST-PP-001','APEX-DIST-PP-003');
