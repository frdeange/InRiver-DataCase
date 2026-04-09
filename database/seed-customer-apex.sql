-- =============================================================================
-- Seed Data: Apex Distribution — Industrial Parts
-- Run AFTER schema.sql
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Categories
-- ---------------------------------------------------------------------------
INSERT INTO Categories (category_code, category_name, parent_id, sort_order) VALUES
    ('fasteners',        'Fasteners',             NULL, 1),
    ('power-tools',      'Power Tools',           NULL, 2),
    ('hand-tools',       'Hand Tools',            NULL, 3),
    ('safety-gear',      'Safety Equipment',      NULL, 4),
    ('hydraulics',       'Hydraulics & Pneumatics',NULL, 5),
    ('electrical',       'Electrical Components', NULL, 6),
    ('bolts',            'Bolts & Screws',        (SELECT category_id FROM Categories WHERE category_code='fasteners'), 1),
    ('nuts-washers',     'Nuts & Washers',        (SELECT category_id FROM Categories WHERE category_code='fasteners'), 2),
    ('anchors',          'Anchors & Fixings',     (SELECT category_id FROM Categories WHERE category_code='fasteners'), 3),
    ('drills',           'Drills',                (SELECT category_id FROM Categories WHERE category_code='power-tools'), 1),
    ('grinders',         'Angle Grinders',        (SELECT category_id FROM Categories WHERE category_code='power-tools'), 2),
    ('saws',             'Saws',                  (SELECT category_id FROM Categories WHERE category_code='power-tools'), 3),
    ('spanners',         'Spanners & Wrenches',   (SELECT category_id FROM Categories WHERE category_code='hand-tools'), 1),
    ('measuring-tools',  'Measuring Tools',       (SELECT category_id FROM Categories WHERE category_code='hand-tools'), 2),
    ('head-protection',  'Head Protection',       (SELECT category_id FROM Categories WHERE category_code='safety-gear'), 1),
    ('eye-protection',   'Eye & Face Protection', (SELECT category_id FROM Categories WHERE category_code='safety-gear'), 2),
    ('respiratory',      'Respiratory Protection',(SELECT category_id FROM Categories WHERE category_code='safety-gear'), 3),
    ('gloves',           'Work Gloves',           (SELECT category_id FROM Categories WHERE category_code='safety-gear'), 4),
    ('valves',           'Valves & Actuators',    (SELECT category_id FROM Categories WHERE category_code='hydraulics'), 1),
    ('couplings',        'Hose Couplings',        (SELECT category_id FROM Categories WHERE category_code='hydraulics'), 2);

-- ---------------------------------------------------------------------------
-- Attributes
-- ---------------------------------------------------------------------------
INSERT INTO Attributes (attribute_code, attribute_name, data_type, unit, is_localizable, is_required) VALUES
    ('material',          'Material',              'text',    NULL,   1, 0),
    ('weight_kg',         'Weight',                'number',  'kg',   0, 0),
    ('length_mm',         'Length',                'number',  'mm',   0, 0),
    ('width_mm',          'Width',                 'number',  'mm',   0, 0),
    ('height_mm',         'Height',                'number',  'mm',   0, 0),
    ('thread_size',       'Thread Size',           'text',    NULL,   0, 0),
    ('tensile_strength',  'Tensile Strength',      'number',  'MPa',  0, 0),
    ('certifications',    'Certifications',        'text',    NULL,   0, 0),
    ('part_number',       'Manufacturer Part No.', 'text',    NULL,   0, 1),
    ('description',       'Product Description',   'text',    NULL,   1, 1),
    ('short_description', 'Short Description',     'text',    NULL,   1, 0),
    ('voltage',           'Voltage',               'number',  'V',    0, 0),
    ('wattage',           'Power',                 'number',  'W',    0, 0),
    ('torque_nm',         'Max Torque',            'number',  'Nm',   0, 0),
    ('rpm_max',           'Max RPM',               'number',  'rpm',  0, 0),
    ('ip_rating',         'IP / Ingress Protection Rating', 'text', NULL, 0, 0),
    ('max_pressure_bar',  'Max Pressure',          'number',  'bar',  0, 0),
    ('pack_qty',          'Pack Quantity',         'number',  'pcs',  0, 0),
    ('hazardous',         'Hazardous Material',    'boolean', NULL,   0, 0),
    ('release_date',      'Product Availability',  'date',    NULL,   0, 0),
    ('country_of_origin', 'Country of Origin',     'text',    NULL,   0, 0),
    ('finish',            'Surface Finish',        'text',    NULL,   1, 0),
    ('protection_class',  'Protection Class',      'text',    NULL,   0, 0);

-- ---------------------------------------------------------------------------
-- Products
-- ---------------------------------------------------------------------------
INSERT INTO Products (sku, product_name, brand, status) VALUES
    ('APEX-BT-M8-001',  'M8 Hex Head Bolt DIN 931 Grade 8.8 (Pack 50)',          'Apex Fasteners', 'active'),
    ('APEX-BT-M10-001', 'M10 Hex Head Bolt DIN 931 Grade 8.8 (Pack 25)',         'Apex Fasteners', 'active'),
    ('APEX-BT-M12-001', 'M12 Hex Head Bolt DIN 931 Grade 10.9 (Pack 25)',        'Apex Fasteners', 'active'),
    ('APEX-NK-M8-001',  'M8 Hex Nut DIN 934 Grade 8 (Pack 100)',                 'Apex Fasteners', 'active'),
    ('APEX-NK-M10-001', 'M10 Hex Nut DIN 934 Grade 8 (Pack 100)',                'Apex Fasteners', 'active'),
    ('APEX-WA-M8-001',  'M8 Flat Washer DIN 125 A Stainless A2 (Pack 200)',      'Apex Fasteners', 'active'),
    ('APEX-AN-001',     'M10 Concrete Anchor Bolt Hex 10×60mm (Pack 20)',        'Apex Anchors',   'active'),
    ('APEX-AN-002',     'M12 Chemical Anchor Stud 12×125mm (Pack 10)',           'Apex Anchors',   'active'),
    ('APEX-DR-001',    'Apex Pro 18V Brushless Combi Drill (Bare Unit)',         'Apex Power',     'active'),
    ('APEX-DR-002',    'Apex Pro 18V SDS Plus Rotary Hammer (Kit)',              'Apex Power',     'active'),
    ('APEX-GR-001',    'Apex 115mm Angle Grinder 850W',                         'Apex Power',     'active'),
    ('APEX-GR-002',    'Apex 125mm Angle Grinder 1100W',                        'Apex Power',     'active'),
    ('APEX-SW-001',    'Apex 18V Brushless Circular Saw (Bare Unit)',            'Apex Power',     'active'),
    ('APEX-SW-002',    'Apex 2100W Reciprocating Saw',                          'Apex Power',     'active'),
    ('APEX-SP-001',    'Combination Spanner Set 8–22mm (8 piece)',               'Apex Tools',     'active'),
    ('APEX-SP-002',    'Impact Wrench Socket Set 1/2" Drive (20 piece)',         'Apex Tools',     'active'),
    ('APEX-MT-001',    'Digital Vernier Caliper 0–150mm ±0.02mm',               'Apex Measure',   'active'),
    ('APEX-MT-002',    'Laser Distance Meter 0.05–60m ±2mm',                    'Apex Measure',   'active'),
    ('APEX-SG-H001',   'Safety Hard Hat Type II EN 397 White',                  'SafeApex',       'active'),
    ('APEX-SG-E001',   'Anti-Fog Safety Goggles EN 166 Clear',                  'SafeApex',       'active'),
    ('APEX-SG-R001',   'Half-Face Respirator P3 EN 140 Medium',                 'SafeApex',       'active'),
    ('APEX-SG-G001',   'Cut-Resistant Work Gloves Level D EN 388 Size L',       'SafeApex',       'active'),
    ('APEX-HY-V001',   'Ball Valve DN25 PN40 Stainless Steel',                  'Apex Hydraulics','active'),
    ('APEX-HY-C001',   'Hydraulic Hose Coupling 1/2" BSP Female',               'Apex Hydraulics','active'),
    ('APEX-DR-003',    'Apex 36V SDS Max Demolition Hammer (Discontinued)',     'Apex Power',     'discontinued');

-- ---------------------------------------------------------------------------
-- ProductCategories
-- ---------------------------------------------------------------------------
INSERT INTO ProductCategories (product_id, category_id, is_primary)
SELECT p.product_id, c.category_id, 1
FROM Products p CROSS JOIN Categories c
WHERE (p.sku IN ('APEX-BT-M8-001','APEX-BT-M10-001','APEX-BT-M12-001') AND c.category_code='bolts')
   OR (p.sku IN ('APEX-NK-M8-001','APEX-NK-M10-001','APEX-WA-M8-001') AND c.category_code='nuts-washers')
   OR (p.sku IN ('APEX-AN-001','APEX-AN-002') AND c.category_code='anchors')
   OR (p.sku IN ('APEX-DR-001','APEX-DR-002') AND c.category_code='drills')
   OR (p.sku IN ('APEX-GR-001','APEX-GR-002') AND c.category_code='grinders')
   OR (p.sku IN ('APEX-SW-001','APEX-SW-002') AND c.category_code='saws')
   OR (p.sku IN ('APEX-SP-001','APEX-SP-002') AND c.category_code='spanners')
   OR (p.sku IN ('APEX-MT-001','APEX-MT-002') AND c.category_code='measuring-tools')
   OR (p.sku IN ('APEX-SG-H001') AND c.category_code='head-protection')
   OR (p.sku IN ('APEX-SG-E001') AND c.category_code='eye-protection')
   OR (p.sku IN ('APEX-SG-R001') AND c.category_code='respiratory')
   OR (p.sku IN ('APEX-SG-G001') AND c.category_code='gloves')
   OR (p.sku IN ('APEX-HY-V001') AND c.category_code='valves')
   OR (p.sku IN ('APEX-HY-C001') AND c.category_code='couplings')
   OR (p.sku IN ('APEX-DR-003') AND c.category_code='drills');

-- Parent links
INSERT INTO ProductCategories (product_id, category_id, is_primary)
SELECT p.product_id, c.category_id, 0
FROM Products p CROSS JOIN Categories c
WHERE (p.sku IN ('APEX-BT-M8-001','APEX-BT-M10-001','APEX-BT-M12-001',
                 'APEX-NK-M8-001','APEX-NK-M10-001','APEX-WA-M8-001',
                 'APEX-AN-001','APEX-AN-002') AND c.category_code='fasteners')
   OR (p.sku IN ('APEX-DR-001','APEX-DR-002','APEX-GR-001','APEX-GR-002',
                 'APEX-SW-001','APEX-SW-002','APEX-DR-003') AND c.category_code='power-tools')
   OR (p.sku IN ('APEX-SP-001','APEX-SP-002','APEX-MT-001','APEX-MT-002') AND c.category_code='hand-tools')
   OR (p.sku IN ('APEX-SG-H001','APEX-SG-E001','APEX-SG-R001','APEX-SG-G001') AND c.category_code='safety-gear')
   OR (p.sku IN ('APEX-HY-V001','APEX-HY-C001') AND c.category_code='hydraulics');

-- ---------------------------------------------------------------------------
-- ProductAttributeValues
-- ---------------------------------------------------------------------------
-- Fasteners numeric attributes
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, number_value, text_value)
SELECT p.product_id, a.attribute_id, NULL,
    CASE p.sku
        WHEN 'APEX-BT-M8-001'  THEN CASE a.attribute_code WHEN 'length_mm' THEN 40   WHEN 'width_mm' THEN 8    WHEN 'tensile_strength' THEN 800  WHEN 'pack_qty' THEN 50  ELSE NULL END
        WHEN 'APEX-BT-M10-001' THEN CASE a.attribute_code WHEN 'length_mm' THEN 50   WHEN 'width_mm' THEN 10   WHEN 'tensile_strength' THEN 800  WHEN 'pack_qty' THEN 25  ELSE NULL END
        WHEN 'APEX-BT-M12-001' THEN CASE a.attribute_code WHEN 'length_mm' THEN 60   WHEN 'width_mm' THEN 12   WHEN 'tensile_strength' THEN 1040 WHEN 'pack_qty' THEN 25  ELSE NULL END
        WHEN 'APEX-NK-M8-001'  THEN CASE a.attribute_code WHEN 'width_mm' THEN 8     WHEN 'pack_qty' THEN 100 ELSE NULL END
        WHEN 'APEX-NK-M10-001' THEN CASE a.attribute_code WHEN 'width_mm' THEN 10    WHEN 'pack_qty' THEN 100 ELSE NULL END
        WHEN 'APEX-WA-M8-001'  THEN CASE a.attribute_code WHEN 'width_mm' THEN 8     WHEN 'pack_qty' THEN 200 ELSE NULL END
        WHEN 'APEX-AN-001'     THEN CASE a.attribute_code WHEN 'length_mm' THEN 60   WHEN 'width_mm' THEN 10   WHEN 'pack_qty' THEN 20  ELSE NULL END
        WHEN 'APEX-AN-002'     THEN CASE a.attribute_code WHEN 'length_mm' THEN 125  WHEN 'width_mm' THEN 12   WHEN 'pack_qty' THEN 10  ELSE NULL END
        ELSE NULL
    END,
    CASE p.sku
        WHEN 'APEX-BT-M8-001'  THEN CASE a.attribute_code WHEN 'thread_size' THEN 'M8×1.25'  WHEN 'certifications' THEN 'DIN 931, ISO 4014' WHEN 'part_number' THEN 'APX-BT-M8-40-8.8' ELSE NULL END
        WHEN 'APEX-BT-M10-001' THEN CASE a.attribute_code WHEN 'thread_size' THEN 'M10×1.5'  WHEN 'certifications' THEN 'DIN 931, ISO 4014' WHEN 'part_number' THEN 'APX-BT-M10-50-8.8' ELSE NULL END
        WHEN 'APEX-BT-M12-001' THEN CASE a.attribute_code WHEN 'thread_size' THEN 'M12×1.75' WHEN 'certifications' THEN 'DIN 931, ISO 4014' WHEN 'part_number' THEN 'APX-BT-M12-60-10.9' ELSE NULL END
        WHEN 'APEX-NK-M8-001'  THEN CASE a.attribute_code WHEN 'thread_size' THEN 'M8×1.25'  WHEN 'certifications' THEN 'DIN 934, ISO 4032' WHEN 'part_number' THEN 'APX-NK-M8-8'  ELSE NULL END
        WHEN 'APEX-NK-M10-001' THEN CASE a.attribute_code WHEN 'thread_size' THEN 'M10×1.5'  WHEN 'certifications' THEN 'DIN 934, ISO 4032' WHEN 'part_number' THEN 'APX-NK-M10-8' ELSE NULL END
        WHEN 'APEX-WA-M8-001'  THEN CASE a.attribute_code WHEN 'certifications' THEN 'DIN 125A, ISO 7089'  WHEN 'part_number' THEN 'APX-WA-M8-A2'  ELSE NULL END
        WHEN 'APEX-AN-001'     THEN CASE a.attribute_code WHEN 'certifications' THEN 'ETA, EN 1992' WHEN 'part_number' THEN 'APX-AN-M10-60' ELSE NULL END
        WHEN 'APEX-AN-002'     THEN CASE a.attribute_code WHEN 'certifications' THEN 'ETA, EN 1992' WHEN 'part_number' THEN 'APX-AN-M12-125-CHEM' ELSE NULL END
        ELSE NULL
    END
FROM Products p CROSS JOIN Attributes a
WHERE p.sku IN ('APEX-BT-M8-001','APEX-BT-M10-001','APEX-BT-M12-001',
                'APEX-NK-M8-001','APEX-NK-M10-001','APEX-WA-M8-001',
                'APEX-AN-001','APEX-AN-002')
  AND a.attribute_code IN ('length_mm','width_mm','tensile_strength','pack_qty',
                           'thread_size','certifications','part_number');

-- Material for fasteners
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE p.sku
        WHEN 'APEX-BT-M8-001'  THEN 'Carbon Steel, Yellow Zinc Plated'
        WHEN 'APEX-BT-M10-001' THEN 'Carbon Steel, Yellow Zinc Plated'
        WHEN 'APEX-BT-M12-001' THEN 'Alloy Steel, Galvanised'
        WHEN 'APEX-NK-M8-001'  THEN 'Carbon Steel, Zinc Plated'
        WHEN 'APEX-NK-M10-001' THEN 'Carbon Steel, Zinc Plated'
        WHEN 'APEX-WA-M8-001'  THEN 'Stainless Steel A2 (304)'
        WHEN 'APEX-AN-001'     THEN 'Carbon Steel, Hot-Dip Galvanised'
        WHEN 'APEX-AN-002'     THEN 'Stainless Steel A4 (316)'
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku IN ('APEX-BT-M8-001','APEX-BT-M10-001','APEX-BT-M12-001',
                'APEX-NK-M8-001','APEX-NK-M10-001','APEX-WA-M8-001',
                'APEX-AN-001','APEX-AN-002')
  AND a.attribute_code = 'material'
  AND l.language_code = 'en';

-- Descriptions — fasteners
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE p.sku
        WHEN 'APEX-BT-M8-001'  THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'M8×40mm hex bolt, grade 8.8, zinc-plated, DIN 931 — pack of 50'
            WHEN 'description'       THEN 'M8×40mm partially-threaded hex head bolt in Grade 8.8 carbon steel with yellow zinc plating. Manufactured to DIN 931 / ISO 4014. Pack of 50.'
            ELSE NULL END
        WHEN 'APEX-BT-M10-001' THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'M10×50mm hex bolt, grade 8.8, zinc-plated, DIN 931 — pack of 25'
            WHEN 'description'       THEN 'M10×50mm partially-threaded hex head bolt in Grade 8.8 carbon steel. Yellow zinc plated to DIN 931 / ISO 4014. Pack of 25.'
            ELSE NULL END
        WHEN 'APEX-BT-M12-001' THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'M12×60mm hex bolt, grade 10.9, galvanised, DIN 931 — pack of 25'
            WHEN 'description'       THEN 'M12×60mm hex head bolt, Grade 10.9 alloy steel, hot-dip galvanised. Suitable for structural connections. Pack of 25.'
            ELSE NULL END
        WHEN 'APEX-NK-M8-001'  THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'M8 hex nut, grade 8, zinc-plated, DIN 934 — pack of 100'
            WHEN 'description'       THEN 'M8 hex nut in Grade 8 carbon steel with zinc plating. Manufactured to DIN 934 / ISO 4032. Pack of 100.'
            ELSE NULL END
        WHEN 'APEX-NK-M10-001' THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'M10 hex nut, grade 8, zinc-plated, DIN 934 — pack of 100'
            WHEN 'description'       THEN 'M10 hex nut in Grade 8 carbon steel with zinc plating to DIN 934. Pack of 100.'
            ELSE NULL END
        WHEN 'APEX-WA-M8-001'  THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'M8 flat washer, stainless A2, DIN 125A — pack of 200'
            WHEN 'description'       THEN 'M8 flat washer in Stainless Steel A2 (304). Manufactured to DIN 125A / ISO 7089. Corrosion-resistant. Pack of 200.'
            ELSE NULL END
        WHEN 'APEX-AN-001'     THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'M10×60mm concrete anchor bolt, galvanised, pack of 20'
            WHEN 'description'       THEN 'M10×60mm hex head concrete anchor bolt in hot-dip galvanised carbon steel. ETA approved for use in cracked and non-cracked concrete. Pack of 20.'
            ELSE NULL END
        WHEN 'APEX-AN-002'     THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'M12×125mm chemical anchor stud, stainless A4, pack of 10'
            WHEN 'description'       THEN 'M12×125mm threaded stud for use with chemical resin anchoring systems. Stainless steel A4 (316) for maximum corrosion resistance. Pack of 10.'
            ELSE NULL END
        ELSE NULL
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku IN ('APEX-BT-M8-001','APEX-BT-M10-001','APEX-BT-M12-001',
                'APEX-NK-M8-001','APEX-NK-M10-001','APEX-WA-M8-001',
                'APEX-AN-001','APEX-AN-002')
  AND a.attribute_code IN ('short_description','description')
  AND l.language_code = 'en';

-- Power tools numeric attributes
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, number_value, text_value)
SELECT p.product_id, a.attribute_id, NULL,
    CASE p.sku
        WHEN 'APEX-DR-001' THEN CASE a.attribute_code WHEN 'voltage' THEN 18 WHEN 'torque_nm' THEN 65 WHEN 'rpm_max' THEN 2000 WHEN 'weight_kg' THEN 1.8 ELSE NULL END
        WHEN 'APEX-DR-002' THEN CASE a.attribute_code WHEN 'voltage' THEN 18 WHEN 'torque_nm' THEN 4.0 WHEN 'rpm_max' THEN 1500 WHEN 'weight_kg' THEN 3.1 ELSE NULL END
        WHEN 'APEX-GR-001' THEN CASE a.attribute_code WHEN 'wattage' THEN 850  WHEN 'rpm_max' THEN 11000 WHEN 'weight_kg' THEN 1.5 ELSE NULL END
        WHEN 'APEX-GR-002' THEN CASE a.attribute_code WHEN 'wattage' THEN 1100 WHEN 'rpm_max' THEN 11000 WHEN 'weight_kg' THEN 1.9 ELSE NULL END
        WHEN 'APEX-SW-001' THEN CASE a.attribute_code WHEN 'voltage' THEN 18   WHEN 'weight_kg' THEN 3.2 ELSE NULL END
        WHEN 'APEX-SW-002' THEN CASE a.attribute_code WHEN 'wattage' THEN 2100 WHEN 'rpm_max' THEN 3000 WHEN 'weight_kg' THEN 4.1 ELSE NULL END
        WHEN 'APEX-DR-003' THEN CASE a.attribute_code WHEN 'voltage' THEN 36   WHEN 'weight_kg' THEN 8.5 ELSE NULL END
        ELSE NULL
    END,
    CASE p.sku
        WHEN 'APEX-DR-001' THEN CASE a.attribute_code WHEN 'certifications' THEN 'CE, RoHS, EN 60745' WHEN 'part_number' THEN 'APX-DR-18V-BL' WHEN 'ip_rating' THEN 'IP20' ELSE NULL END
        WHEN 'APEX-DR-002' THEN CASE a.attribute_code WHEN 'certifications' THEN 'CE, RoHS, EN 60745' WHEN 'part_number' THEN 'APX-DR-SDS18V-KIT' WHEN 'ip_rating' THEN 'IP20' ELSE NULL END
        WHEN 'APEX-GR-001' THEN CASE a.attribute_code WHEN 'certifications' THEN 'CE, EN 60745'       WHEN 'part_number' THEN 'APX-GR-115-850W' WHEN 'ip_rating' THEN 'IP20' ELSE NULL END
        WHEN 'APEX-GR-002' THEN CASE a.attribute_code WHEN 'certifications' THEN 'CE, EN 60745'       WHEN 'part_number' THEN 'APX-GR-125-1100W' WHEN 'ip_rating' THEN 'IP20' ELSE NULL END
        WHEN 'APEX-SW-001' THEN CASE a.attribute_code WHEN 'certifications' THEN 'CE, RoHS'           WHEN 'part_number' THEN 'APX-SW-18V-CIRC' ELSE NULL END
        WHEN 'APEX-SW-002' THEN CASE a.attribute_code WHEN 'certifications' THEN 'CE, EN 60745'       WHEN 'part_number' THEN 'APX-SW-2100W-RECIP' ELSE NULL END
        WHEN 'APEX-DR-003' THEN CASE a.attribute_code WHEN 'certifications' THEN 'CE, EN 60745'       WHEN 'part_number' THEN 'APX-DR-SDS36V-DEMO' ELSE NULL END
        ELSE NULL
    END
FROM Products p CROSS JOIN Attributes a
WHERE p.sku IN ('APEX-DR-001','APEX-DR-002','APEX-GR-001','APEX-GR-002','APEX-SW-001','APEX-SW-002','APEX-DR-003')
  AND a.attribute_code IN ('voltage','torque_nm','rpm_max','wattage','weight_kg','certifications','part_number','ip_rating');

-- Power tools descriptions (EN)
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE p.sku
        WHEN 'APEX-DR-001' THEN CASE a.attribute_code
            WHEN 'short_description' THEN '18V brushless combi drill, 65Nm, 2-speed, bare unit'
            WHEN 'description'       THEN 'The Apex Pro 18V Brushless Combi Drill delivers 65Nm of torque in a compact, lightweight body. Brushless motor extends runtime and tool life. Compatible with the entire Apex 18V battery platform. Sold as bare unit.'
            ELSE NULL END
        WHEN 'APEX-DR-002' THEN CASE a.attribute_code
            WHEN 'short_description' THEN '18V SDS Plus rotary hammer, 4J impact energy, includes 2×5Ah batteries + charger'
            WHEN 'description'       THEN 'The Apex Pro 18V SDS Plus Rotary Hammer handles concrete, masonry, and steel with ease. 4J of impact energy in cordless freedom. Kit includes two 5Ah batteries and rapid charger.'
            ELSE NULL END
        WHEN 'APEX-GR-001' THEN CASE a.attribute_code
            WHEN 'short_description' THEN '115mm angle grinder 850W, side handle, disc guard'
            WHEN 'description'       THEN '850W angle grinder for light cutting and grinding on metal and stone. Spindle lock for quick disc changes. Anti-vibration side handle for operator comfort.'
            ELSE NULL END
        WHEN 'APEX-GR-002' THEN CASE a.attribute_code
            WHEN 'short_description' THEN '125mm angle grinder 1100W, variable speed, safety clutch'
            WHEN 'description'       THEN '1100W variable-speed angle grinder with electronic safety clutch to prevent kickback. Suitable for heavy-duty grinding, cutting, and finishing applications.'
            ELSE NULL END
        WHEN 'APEX-SW-001' THEN CASE a.attribute_code
            WHEN 'short_description' THEN '18V brushless circular saw, 165mm blade, bevel 0°–45°'
            WHEN 'description'       THEN 'Cordless 18V brushless circular saw with 165mm blade capacity. Bevel cuts from 0° to 45°. Compact and lightweight for site use. Bare unit — compatible with Apex 18V battery platform.'
            ELSE NULL END
        WHEN 'APEX-SW-002' THEN CASE a.attribute_code
            WHEN 'short_description' THEN '2100W corded reciprocating saw, variable speed, 32mm stroke'
            WHEN 'description'       THEN 'High-power 2100W reciprocating saw for demolition and rough cutting. Variable speed trigger and 32mm stroke length. Tool-free blade change system.'
            ELSE NULL END
        WHEN 'APEX-DR-003' THEN CASE a.attribute_code
            WHEN 'short_description' THEN '36V SDS Max demolition hammer — discontinued, limited stock'
            WHEN 'description'       THEN 'The Apex 36V SDS Max Demolition Hammer (discontinued). Professional-grade demolition performance on battery. Limited remaining stock available through wholesale channel only.'
            ELSE NULL END
        ELSE NULL
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku IN ('APEX-DR-001','APEX-DR-002','APEX-GR-001','APEX-GR-002','APEX-SW-001','APEX-SW-002','APEX-DR-003')
  AND a.attribute_code IN ('short_description','description')
  AND l.language_code = 'en';

-- Hand tools
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, number_value, text_value)
SELECT p.product_id, a.attribute_id, NULL,
    CASE p.sku
        WHEN 'APEX-SP-001' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 1.2 WHEN 'pack_qty' THEN 8  ELSE NULL END
        WHEN 'APEX-SP-002' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 3.8 WHEN 'pack_qty' THEN 20 ELSE NULL END
        WHEN 'APEX-MT-001' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 0.2 ELSE NULL END
        WHEN 'APEX-MT-002' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 0.15 ELSE NULL END
        ELSE NULL
    END,
    CASE p.sku
        WHEN 'APEX-SP-001' THEN CASE a.attribute_code WHEN 'material' THEN 'Chrome Vanadium Steel' WHEN 'certifications' THEN 'DIN 3110' WHEN 'part_number' THEN 'APX-SP-SET8' WHEN 'finish' THEN 'Mirror Chrome' ELSE NULL END
        WHEN 'APEX-SP-002' THEN CASE a.attribute_code WHEN 'material' THEN 'Chrome Molybdenum Steel' WHEN 'certifications' THEN 'DIN 3120, ISO 2725' WHEN 'part_number' THEN 'APX-SP-IMP20' WHEN 'finish' THEN 'Satin Chrome' ELSE NULL END
        WHEN 'APEX-MT-001' THEN CASE a.attribute_code WHEN 'material' THEN 'Stainless Steel Jaws, ABS Body' WHEN 'certifications' THEN 'ISO 13225' WHEN 'part_number' THEN 'APX-MT-DIG150' ELSE NULL END
        WHEN 'APEX-MT-002' THEN CASE a.attribute_code WHEN 'material' THEN 'ABS Casing' WHEN 'certifications' THEN 'CE, EN 60825' WHEN 'part_number' THEN 'APX-MT-LASER60' WHEN 'protection_class' THEN 'Class II' ELSE NULL END
        ELSE NULL
    END
FROM Products p CROSS JOIN Attributes a
WHERE p.sku IN ('APEX-SP-001','APEX-SP-002','APEX-MT-001','APEX-MT-002')
  AND a.attribute_code IN ('weight_kg','pack_qty','material','certifications','part_number','finish','protection_class');

INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE p.sku
        WHEN 'APEX-SP-001' THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'Combination spanner set 8–22mm, 8 piece, CrV steel'
            WHEN 'description'       THEN '8-piece combination spanner set in Chrome Vanadium steel. Sizes: 8, 10, 12, 13, 14, 17, 19, 22mm. Mirror chrome finish. Manufactured to DIN 3110.'
            ELSE NULL END
        WHEN 'APEX-SP-002' THEN CASE a.attribute_code
            WHEN 'short_description' THEN '1/2" drive impact socket set, 20 piece, Cr-Mo steel'
            WHEN 'description'       THEN '20-piece 1/2" drive impact socket set in Chrome Molybdenum steel. Sizes: 10–32mm. Supplied in a blow-moulded storage case. Manufactured to DIN 3120.'
            ELSE NULL END
        WHEN 'APEX-MT-001' THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'Digital vernier caliper 0–150mm, ±0.02mm, IP54'
            WHEN 'description'       THEN 'Precision digital caliper with stainless steel jaws and large LCD display. Resolution 0.01mm, accuracy ±0.02mm. IP54 splash-resistant. Zero/ABS function. ISO 13225 compliant.'
            ELSE NULL END
        WHEN 'APEX-MT-002' THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'Laser distance meter 0.05–60m, ±2mm, IP54'
            WHEN 'description'       THEN 'Compact laser distance meter with 60m range and ±2mm accuracy. Calculates area and volume. Continuous measurement mode. IP54 water and dust protection. CE marked, Class II laser.'
            ELSE NULL END
        ELSE NULL
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku IN ('APEX-SP-001','APEX-SP-002','APEX-MT-001','APEX-MT-002')
  AND a.attribute_code IN ('short_description','description')
  AND l.language_code = 'en';

-- Safety gear
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, number_value, text_value, bool_value)
SELECT p.product_id, a.attribute_id, NULL,
    CASE p.sku
        WHEN 'APEX-SG-H001' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 0.38 ELSE NULL END
        WHEN 'APEX-SG-E001' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 0.11 ELSE NULL END
        WHEN 'APEX-SG-R001' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 0.32 ELSE NULL END
        WHEN 'APEX-SG-G001' THEN CASE a.attribute_code WHEN 'weight_kg' THEN 0.25 ELSE NULL END
        ELSE NULL
    END,
    CASE p.sku
        WHEN 'APEX-SG-H001' THEN CASE a.attribute_code WHEN 'material' THEN 'High-Density Polyethylene (HDPE)' WHEN 'certifications' THEN 'EN 397, ANSI Z89.1 Type II' WHEN 'part_number' THEN 'APX-SG-HH-EN397-WH' ELSE NULL END
        WHEN 'APEX-SG-E001' THEN CASE a.attribute_code WHEN 'material' THEN 'Polycarbonate Lens, PVC Frame'   WHEN 'certifications' THEN 'EN 166:2002, ANSI Z87.1'   WHEN 'part_number' THEN 'APX-SG-EG-EN166' ELSE NULL END
        WHEN 'APEX-SG-R001' THEN CASE a.attribute_code WHEN 'material' THEN 'Thermoplastic Rubber, Silicone Seals' WHEN 'certifications' THEN 'EN 140, EN 143 P3'    WHEN 'part_number' THEN 'APX-SG-HF-P3-M' ELSE NULL END
        WHEN 'APEX-SG-G001' THEN CASE a.attribute_code WHEN 'material' THEN 'HPPE/Glass Fibre Blend'          WHEN 'certifications' THEN 'EN 388:2016 Level D, EN 420' WHEN 'part_number' THEN 'APX-SG-GL-D-L' ELSE NULL END
        ELSE NULL
    END,
    NULL
FROM Products p CROSS JOIN Attributes a
WHERE p.sku IN ('APEX-SG-H001','APEX-SG-E001','APEX-SG-R001','APEX-SG-G001')
  AND a.attribute_code IN ('weight_kg','material','certifications','part_number');

INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE p.sku
        WHEN 'APEX-SG-H001' THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'Hard hat Type II, EN 397, white HDPE — adjustable ratchet'
            WHEN 'description'       THEN 'Type II safety hard hat in HDPE with 6-point polyester suspension and ratchet adjustment. Conforms to EN 397 and ANSI Z89.1. Weight: 380g. Ventilated shell for comfort on site.'
            ELSE NULL END
        WHEN 'APEX-SG-E001' THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'Anti-fog safety goggles, clear polycarbonate, EN 166'
            WHEN 'description'       THEN 'Over-spectacle safety goggles with clear anti-fog, anti-scratch polycarbonate lens. Adjustable elastic headband. EN 166:2002 and ANSI Z87.1 certified. Suitable for chemical splash and impact hazards.'
            ELSE NULL END
        WHEN 'APEX-SG-R001' THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'Half-face respirator P3, EN 140, medium — filters included'
            WHEN 'description'       THEN 'Half-face respirator with P3 particle filters (EN 143). Thermoplastic rubber face seal for comfort and seal. Includes one pair of P3 filters. Size Medium. Reusable. EN 140 certified.'
            ELSE NULL END
        WHEN 'APEX-SG-G001' THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'Cut-resistant work gloves EN 388 Level D, HPPE/glass fibre, size L'
            WHEN 'description'       THEN 'Cut-resistant work gloves providing Level D cut resistance per EN 388:2016. HPPE and glass-fibre blend. Polyurethane palm coating for grip. Ideal for sheet metal handling and glass work. Size Large.'
            ELSE NULL END
        ELSE NULL
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku IN ('APEX-SG-H001','APEX-SG-E001','APEX-SG-R001','APEX-SG-G001')
  AND a.attribute_code IN ('short_description','description')
  AND l.language_code = 'en';

-- Hydraulics
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, number_value, text_value)
SELECT p.product_id, a.attribute_id, NULL,
    CASE p.sku
        WHEN 'APEX-HY-V001' THEN CASE a.attribute_code WHEN 'max_pressure_bar' THEN 40 WHEN 'weight_kg' THEN 0.65 ELSE NULL END
        WHEN 'APEX-HY-C001' THEN CASE a.attribute_code WHEN 'max_pressure_bar' THEN 350 WHEN 'weight_kg' THEN 0.18 ELSE NULL END
        ELSE NULL
    END,
    CASE p.sku
        WHEN 'APEX-HY-V001' THEN CASE a.attribute_code WHEN 'material' THEN 'Body: Stainless Steel 316L, Seat: PTFE' WHEN 'certifications' THEN 'EN 1983, PED 2014/68/EU' WHEN 'part_number' THEN 'APX-HY-BV-DN25-SS316' WHEN 'thread_size' THEN 'DN25 (1") BSP' ELSE NULL END
        WHEN 'APEX-HY-C001' THEN CASE a.attribute_code WHEN 'material' THEN 'Carbon Steel, Zinc Nickel Plated' WHEN 'certifications' THEN 'ISO 7241-1 Series A' WHEN 'part_number' THEN 'APX-HY-HC-12F-BSP' WHEN 'thread_size' THEN '1/2" BSP Female' ELSE NULL END
        ELSE NULL
    END
FROM Products p CROSS JOIN Attributes a
WHERE p.sku IN ('APEX-HY-V001','APEX-HY-C001')
  AND a.attribute_code IN ('max_pressure_bar','weight_kg','material','certifications','part_number','thread_size');

INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE p.sku
        WHEN 'APEX-HY-V001' THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'Full-bore ball valve DN25 PN40, stainless 316L, BSP'
            WHEN 'description'       THEN 'Full-bore 2-piece ball valve in 316L stainless steel with PTFE seat. DN25, PN40 rated. BSP threaded connections. Lever operated. EN 1983 and PED 2014/68/EU compliant. Suitable for water, air, oil, and chemical service.'
            ELSE NULL END
        WHEN 'APEX-HY-C001' THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'Hydraulic hose coupling 1/2" BSP female, ISO 7241-1 Series A, 350 bar'
            WHEN 'description'       THEN 'Flat-face hydraulic quick-release coupling, female half. ISO 7241-1 Series A. Rated to 350 bar. 1/2" BSP female thread. Carbon steel with zinc-nickel plating for corrosion protection. Zero-leak dry-break design.'
            ELSE NULL END
        ELSE NULL
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE p.sku IN ('APEX-HY-V001','APEX-HY-C001')
  AND a.attribute_code IN ('short_description','description')
  AND l.language_code = 'en';

-- Hazardous flag
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, bool_value)
SELECT p.product_id, a.attribute_id, NULL, 0
FROM Products p CROSS JOIN Attributes a
WHERE a.attribute_code = 'hazardous'
  AND p.sku IN ('APEX-BT-M8-001','APEX-BT-M10-001','APEX-BT-M12-001',
                'APEX-NK-M8-001','APEX-NK-M10-001','APEX-WA-M8-001',
                'APEX-AN-001','APEX-AN-002','APEX-HY-V001','APEX-HY-C001');

-- Country of origin
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, NULL,
    CASE p.sku
        WHEN 'APEX-BT-M8-001'  THEN 'Germany'
        WHEN 'APEX-BT-M10-001' THEN 'Germany'
        WHEN 'APEX-BT-M12-001' THEN 'Germany'
        WHEN 'APEX-NK-M8-001'  THEN 'Germany'
        WHEN 'APEX-NK-M10-001' THEN 'Germany'
        WHEN 'APEX-WA-M8-001'  THEN 'Germany'
        WHEN 'APEX-AN-001'     THEN 'Netherlands'
        WHEN 'APEX-AN-002'     THEN 'Netherlands'
        WHEN 'APEX-DR-001'     THEN 'China'
        WHEN 'APEX-DR-002'     THEN 'China'
        WHEN 'APEX-GR-001'     THEN 'China'
        WHEN 'APEX-GR-002'     THEN 'China'
        WHEN 'APEX-HY-V001'    THEN 'Italy'
        WHEN 'APEX-HY-C001'    THEN 'Italy'
        ELSE 'Germany'
    END
FROM Products p CROSS JOIN Attributes a
WHERE a.attribute_code = 'country_of_origin';

-- ---------------------------------------------------------------------------
-- ProductChannels
-- ---------------------------------------------------------------------------
-- All active products: wholesale
INSERT INTO ProductChannels (product_id, channel_id, is_published, published_at)
SELECT p.product_id, c.channel_id, 1, SYSUTCDATETIME()
FROM Products p CROSS JOIN Channels c
WHERE p.status = 'active' AND c.channel_code = 'wholesale';

-- Selected products: retail
INSERT INTO ProductChannels (product_id, channel_id, is_published, published_at)
SELECT p.product_id, c.channel_id, 1, SYSUTCDATETIME()
FROM Products p CROSS JOIN Channels c
WHERE p.sku IN ('APEX-DR-001','APEX-DR-002','APEX-GR-001','APEX-GR-002',
                'APEX-SW-001','APEX-SP-001','APEX-SP-002','APEX-MT-001','APEX-MT-002',
                'APEX-SG-H001','APEX-SG-E001','APEX-SG-R001','APEX-SG-G001')
  AND c.channel_code = 'retail';

-- Fasteners and hydraulics: OEM channel
INSERT INTO ProductChannels (product_id, channel_id, is_published, published_at)
SELECT p.product_id, c.channel_id, 1, SYSUTCDATETIME()
FROM Products p CROSS JOIN Channels c
WHERE p.sku IN ('APEX-BT-M8-001','APEX-BT-M10-001','APEX-BT-M12-001',
                'APEX-NK-M8-001','APEX-NK-M10-001','APEX-WA-M8-001',
                'APEX-AN-001','APEX-AN-002','APEX-HY-V001','APEX-HY-C001')
  AND c.channel_code = 'oem';

-- Discontinued: outlet only, unpublished
INSERT INTO ProductChannels (product_id, channel_id, is_published)
SELECT p.product_id, c.channel_id, 0
FROM Products p CROSS JOIN Channels c
WHERE p.sku = 'APEX-DR-003' AND c.channel_code IN ('wholesale','outlet');

-- ---------------------------------------------------------------------------
-- MediaAssets
-- ---------------------------------------------------------------------------
INSERT INTO MediaAssets (product_id, asset_type, file_name, url, alt_text, sort_order)
SELECT p.product_id, 'image',
    p.sku + '-main.jpg',
    'https://cdn.apex-distribution.example/products/' + p.sku + '-main.jpg',
    p.product_name + ' product image',
    1
FROM Products p;

INSERT INTO MediaAssets (product_id, asset_type, file_name, url, alt_text, sort_order)
SELECT p.product_id, 'document',
    p.sku + '-datasheet-en.pdf',
    'https://cdn.apex-distribution.example/docs/' + p.sku + '-datasheet-en.pdf',
    p.product_name + ' Technical Datasheet (EN)',
    10
FROM Products p
WHERE p.sku IN ('APEX-DR-001','APEX-DR-002','APEX-GR-001','APEX-GR-002',
                'APEX-HY-V001','APEX-HY-C001','APEX-MT-001','APEX-MT-002');

INSERT INTO MediaAssets (product_id, asset_type, file_name, url, alt_text, sort_order)
SELECT p.product_id, 'document',
    p.sku + '-ce-declaration.pdf',
    'https://cdn.apex-distribution.example/docs/' + p.sku + '-ce-declaration.pdf',
    p.product_name + ' CE Declaration of Conformity',
    11
FROM Products p
WHERE p.sku IN ('APEX-DR-001','APEX-DR-002','APEX-GR-001','APEX-GR-002',
                'APEX-SG-H001','APEX-SG-E001','APEX-SG-R001','APEX-SG-G001',
                'APEX-HY-V001');
