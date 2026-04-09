-- =============================================================================
-- Seed Data: Nova Retail — Fashion / Apparel
-- Run AFTER schema.sql
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Categories
-- ---------------------------------------------------------------------------
INSERT INTO Categories (category_code, category_name, parent_id, sort_order) VALUES
    ('clothing',        'Clothing',        NULL, 1),
    ('footwear',        'Footwear',        NULL, 2),
    ('bags',            'Bags & Luggage',  NULL, 3),
    ('jewellery',       'Jewellery',       NULL, 4),
    ('tops',            'Tops',            (SELECT category_id FROM Categories WHERE category_code='clothing'), 1),
    ('bottoms',         'Bottoms',         (SELECT category_id FROM Categories WHERE category_code='clothing'), 2),
    ('outerwear',       'Outerwear',       (SELECT category_id FROM Categories WHERE category_code='clothing'), 3),
    ('dresses',         'Dresses & Skirts',(SELECT category_id FROM Categories WHERE category_code='clothing'), 4),
    ('activewear',      'Activewear',      (SELECT category_id FROM Categories WHERE category_code='clothing'), 5),
    ('t-shirts',        'T-Shirts',        (SELECT category_id FROM Categories WHERE category_code='tops'), 1),
    ('shirts',          'Shirts & Blouses',(SELECT category_id FROM Categories WHERE category_code='tops'), 2),
    ('knitwear',        'Knitwear',        (SELECT category_id FROM Categories WHERE category_code='tops'), 3),
    ('jeans',           'Jeans',           (SELECT category_id FROM Categories WHERE category_code='bottoms'), 1),
    ('trousers',        'Trousers & Chinos',(SELECT category_id FROM Categories WHERE category_code='bottoms'), 2),
    ('shorts',          'Shorts',          (SELECT category_id FROM Categories WHERE category_code='bottoms'), 3),
    ('trainers',        'Trainers',        (SELECT category_id FROM Categories WHERE category_code='footwear'), 1),
    ('boots',           'Boots',           (SELECT category_id FROM Categories WHERE category_code='footwear'), 2),
    ('sandals',         'Sandals',         (SELECT category_id FROM Categories WHERE category_code='footwear'), 3),
    ('backpacks',       'Backpacks',       (SELECT category_id FROM Categories WHERE category_code='bags'), 1),
    ('tote-bags',       'Tote Bags',       (SELECT category_id FROM Categories WHERE category_code='bags'), 2);

-- ---------------------------------------------------------------------------
-- Attributes
-- ---------------------------------------------------------------------------
INSERT INTO Attributes (attribute_code, attribute_name, data_type, unit, is_localizable, is_required) VALUES
    ('size',              'Size',                  'text',    NULL,  1, 1),
    ('color',             'Color',                 'text',    NULL,  1, 1),
    ('material',          'Material Composition',  'text',    NULL,  1, 0),
    ('care_instructions', 'Care Instructions',     'text',    NULL,  1, 0),
    ('description',       'Product Description',   'text',    NULL,  1, 1),
    ('short_description', 'Short Description',     'text',    NULL,  1, 0),
    ('gender',            'Gender',                'text',    NULL,  0, 0),
    ('age_group',         'Age Group',             'text',    NULL,  0, 0),
    ('weight_kg',         'Weight',                'number',  'kg',  0, 0),
    ('country_of_origin', 'Country of Origin',     'text',    NULL,  0, 0),
    ('is_sustainable',    'Sustainable Product',   'boolean', NULL,  0, 0),
    ('season',            'Season',                'text',    NULL,  0, 0),
    ('fit',               'Fit',                   'text',    NULL,  1, 0),
    ('available_sizes',   'Available Sizes',       'text',    NULL,  0, 0),
    ('ean',               'EAN / Barcode',         'text',    NULL,  0, 0),
    ('release_date',      'Collection Release',    'date',    NULL,  0, 0),
    ('heel_height_cm',    'Heel Height',           'number',  'cm',  0, 0),
    ('volume_l',          'Volume',                'number',  'L',   0, 0),
    ('waterproof',        'Waterproof',            'boolean', NULL,  0, 0);

-- ---------------------------------------------------------------------------
-- Products
-- ---------------------------------------------------------------------------
INSERT INTO Products (sku, product_name, brand, status) VALUES
    ('NOVA-TS-001', 'Classic Logo Tee',               'Nova Basics', 'active'),
    ('NOVA-TS-002', 'Oversized Graphic Tee',          'Nova Basics', 'active'),
    ('NOVA-TS-003', 'Organic Cotton V-Neck',          'Nova Eco',    'active'),
    ('NOVA-SH-001', 'Oxford Button-Down Shirt',       'Nova Classic','active'),
    ('NOVA-SH-002', 'Linen Summer Shirt',             'Nova Classic','active'),
    ('NOVA-KN-001', 'Merino Crew-Neck Sweater',       'Nova Premium','active'),
    ('NOVA-KN-002', 'Chunky Cable-Knit Cardigan',     'Nova Premium','active'),
    ('NOVA-JN-001', 'Slim Fit Jeans — Indigo',        'Nova Denim',  'active'),
    ('NOVA-JN-002', 'Wide Leg Jeans — Light Wash',    'Nova Denim',  'active'),
    ('NOVA-JN-003', 'Skinny Jeans — Black',           'Nova Denim',  'active'),
    ('NOVA-TR-001', 'Tailored Chino Trousers',        'Nova Classic','active'),
    ('NOVA-TR-002', 'Jogger Sweatpants',              'Nova Sport',  'active'),
    ('NOVA-SH-003', 'Cargo Shorts',                   'Nova Sport',  'active'),
    ('NOVA-DR-001', 'Floral Midi Dress',              'Nova Summer', 'active'),
    ('NOVA-DR-002', 'Wrap Dress — Solid',             'Nova Summer', 'active'),
    ('NOVA-OW-001', 'Puffer Jacket — Recycled Fill',  'Nova Eco',    'active'),
    ('NOVA-OW-002', 'Wool-Blend Trench Coat',         'Nova Premium','active'),
    ('NOVA-AW-001', 'Performance Running Leggings',   'Nova Sport',  'active'),
    ('NOVA-AW-002', 'Seamless Sports Bra',            'Nova Sport',  'active'),
    ('NOVA-FT-001', 'Leather Chelsea Boots',          'Nova Shoes',  'active'),
    ('NOVA-FT-002', 'Canvas Trainers',                'Nova Shoes',  'active'),
    ('NOVA-FT-003', 'Espadrille Sandals',             'Nova Summer', 'active'),
    ('NOVA-BG-001', 'Leather Backpack',               'Nova Bags',   'active'),
    ('NOVA-BG-002', 'Canvas Tote Bag',                'Nova Eco',    'active'),
    ('NOVA-KN-003', 'Cashmere Roll-Neck',             'Nova Premium','discontinued');

-- ---------------------------------------------------------------------------
-- ProductCategories
-- ---------------------------------------------------------------------------
INSERT INTO ProductCategories (product_id, category_id, is_primary)
SELECT p.product_id, c.category_id, 1
FROM Products p CROSS JOIN Categories c
WHERE (p.sku IN ('NOVA-TS-001','NOVA-TS-002','NOVA-TS-003') AND c.category_code='t-shirts')
   OR (p.sku IN ('NOVA-SH-001','NOVA-SH-002') AND c.category_code='shirts')
   OR (p.sku IN ('NOVA-KN-001','NOVA-KN-002','NOVA-KN-003') AND c.category_code='knitwear')
   OR (p.sku IN ('NOVA-JN-001','NOVA-JN-002','NOVA-JN-003') AND c.category_code='jeans')
   OR (p.sku IN ('NOVA-TR-001') AND c.category_code='trousers')
   OR (p.sku IN ('NOVA-TR-002','NOVA-SH-003') AND c.category_code='shorts')
   OR (p.sku IN ('NOVA-DR-001','NOVA-DR-002') AND c.category_code='dresses')
   OR (p.sku IN ('NOVA-OW-001','NOVA-OW-002') AND c.category_code='outerwear')
   OR (p.sku IN ('NOVA-AW-001','NOVA-AW-002') AND c.category_code='activewear')
   OR (p.sku IN ('NOVA-FT-001') AND c.category_code='boots')
   OR (p.sku IN ('NOVA-FT-002') AND c.category_code='trainers')
   OR (p.sku IN ('NOVA-FT-003') AND c.category_code='sandals')
   OR (p.sku IN ('NOVA-BG-001') AND c.category_code='backpacks')
   OR (p.sku IN ('NOVA-BG-002') AND c.category_code='tote-bags');

-- Parent category links
INSERT INTO ProductCategories (product_id, category_id, is_primary)
SELECT p.product_id, c.category_id, 0
FROM Products p CROSS JOIN Categories c
WHERE p.sku IN ('NOVA-TS-001','NOVA-TS-002','NOVA-TS-003','NOVA-SH-001','NOVA-SH-002',
                'NOVA-KN-001','NOVA-KN-002','NOVA-KN-003','NOVA-DR-001','NOVA-DR-002',
                'NOVA-OW-001','NOVA-OW-002','NOVA-TR-001','NOVA-TR-002','NOVA-SH-003',
                'NOVA-AW-001','NOVA-AW-002')
  AND c.category_code = 'clothing';

INSERT INTO ProductCategories (product_id, category_id, is_primary)
SELECT p.product_id, c.category_id, 0
FROM Products p CROSS JOIN Categories c
WHERE p.sku IN ('NOVA-JN-001','NOVA-JN-002','NOVA-JN-003')
  AND c.category_code IN ('bottoms','clothing');

INSERT INTO ProductCategories (product_id, category_id, is_primary)
SELECT p.product_id, c.category_id, 0
FROM Products p CROSS JOIN Categories c
WHERE p.sku IN ('NOVA-FT-001','NOVA-FT-002','NOVA-FT-003')
  AND c.category_code = 'footwear';

-- ---------------------------------------------------------------------------
-- ProductAttributeValues — English
-- ---------------------------------------------------------------------------
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value, bool_value, date_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE p.sku
      WHEN 'NOVA-TS-001' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'The Nova Classic Logo Tee. 100% organic cotton in a relaxed fit. Available in 8 colours.'
        WHEN 'short_description' THEN '100% organic cotton crew-neck tee, relaxed fit'
        WHEN 'color'             THEN 'White'
        WHEN 'material'          THEN '100% Organic Cotton'
        WHEN 'care_instructions' THEN 'Machine wash 30°C, do not tumble dry'
        WHEN 'gender'            THEN 'Unisex'
        WHEN 'available_sizes'   THEN 'XS, S, M, L, XL, XXL'
        WHEN 'fit'               THEN 'Relaxed'
        WHEN 'season'            THEN 'All Season'
        WHEN 'ean'               THEN '5901234123457'
        WHEN 'country_of_origin' THEN 'Portugal'
        ELSE NULL END
      WHEN 'NOVA-TS-002' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'An oversized graphic tee with bold artistic prints. Dropped shoulders, boxy silhouette.'
        WHEN 'short_description' THEN 'Oversized graphic tee, dropped shoulder'
        WHEN 'color'             THEN 'Black'
        WHEN 'material'          THEN '100% Cotton'
        WHEN 'care_instructions' THEN 'Machine wash 30°C, wash inside out'
        WHEN 'gender'            THEN 'Unisex'
        WHEN 'available_sizes'   THEN 'S, M, L, XL'
        WHEN 'fit'               THEN 'Oversized'
        WHEN 'season'            THEN 'All Season'
        ELSE NULL END
      WHEN 'NOVA-TS-003' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'Lightweight V-neck made from GOTS-certified organic cotton. Sustainably produced in Portugal.'
        WHEN 'short_description' THEN 'Organic cotton V-neck tee, slim fit'
        WHEN 'color'             THEN 'Navy'
        WHEN 'material'          THEN '100% GOTS-certified Organic Cotton'
        WHEN 'care_instructions' THEN 'Machine wash 30°C, do not tumble dry'
        WHEN 'gender'            THEN 'Womens'
        WHEN 'available_sizes'   THEN 'XS, S, M, L, XL'
        WHEN 'fit'               THEN 'Slim'
        WHEN 'season'            THEN 'All Season'
        WHEN 'country_of_origin' THEN 'Portugal'
        ELSE NULL END
      WHEN 'NOVA-SH-001' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'A timeless Oxford button-down shirt in premium cotton. Single-needle tailoring and a medium spread collar.'
        WHEN 'short_description' THEN 'Classic Oxford button-down, 100% cotton'
        WHEN 'color'             THEN 'White'
        WHEN 'material'          THEN '100% Cotton Oxford Weave'
        WHEN 'care_instructions' THEN 'Machine wash 40°C, iron on medium heat'
        WHEN 'gender'            THEN 'Mens'
        WHEN 'available_sizes'   THEN 'S, M, L, XL, XXL'
        WHEN 'fit'               THEN 'Regular'
        WHEN 'season'            THEN 'All Season'
        ELSE NULL END
      WHEN 'NOVA-SH-002' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'Breathable linen shirt, ideal for warm weather. Relaxed fit with a camp collar.'
        WHEN 'short_description' THEN 'Linen camp-collar shirt, relaxed fit'
        WHEN 'color'             THEN 'Sand'
        WHEN 'material'          THEN '100% Linen'
        WHEN 'care_instructions' THEN 'Machine wash 30°C or hand wash, hang to dry'
        WHEN 'gender'            THEN 'Unisex'
        WHEN 'available_sizes'   THEN 'S, M, L, XL'
        WHEN 'fit'               THEN 'Relaxed'
        WHEN 'season'            THEN 'Spring/Summer'
        ELSE NULL END
      WHEN 'NOVA-KN-001' THEN CASE a.attribute_code
        WHEN 'description'       THEN '100% extra-fine merino wool crew-neck sweater. Incredibly soft, temperature-regulating, and naturally odour-resistant.'
        WHEN 'short_description' THEN 'Extra-fine merino crew-neck, 100% wool'
        WHEN 'color'             THEN 'Oatmeal'
        WHEN 'material'          THEN '100% Extra-fine Merino Wool'
        WHEN 'care_instructions' THEN 'Hand wash cold or delicate machine wash, lay flat to dry'
        WHEN 'gender'            THEN 'Unisex'
        WHEN 'available_sizes'   THEN 'XS, S, M, L, XL'
        WHEN 'fit'               THEN 'Regular'
        WHEN 'season'            THEN 'Autumn/Winter'
        ELSE NULL END
      WHEN 'NOVA-KN-002' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'A cosy cable-knit cardigan in a chunky gauge. Features deep side pockets and a relaxed drape.'
        WHEN 'short_description' THEN 'Chunky cable-knit cardigan, oversized fit'
        WHEN 'color'             THEN 'Camel'
        WHEN 'material'          THEN '60% Wool, 40% Acrylic'
        WHEN 'care_instructions' THEN 'Hand wash cold, lay flat to dry'
        WHEN 'gender'            THEN 'Womens'
        WHEN 'available_sizes'   THEN 'XS, S, M, L'
        WHEN 'fit'               THEN 'Oversized'
        WHEN 'season'            THEN 'Autumn/Winter'
        ELSE NULL END
      WHEN 'NOVA-JN-001' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'Mid-rise slim fit jeans in classic indigo denim. Made with 2% elastane for comfort and shape retention.'
        WHEN 'short_description' THEN 'Mid-rise slim fit jeans, indigo denim'
        WHEN 'color'             THEN 'Indigo'
        WHEN 'material'          THEN '98% Cotton, 2% Elastane'
        WHEN 'care_instructions' THEN 'Machine wash 30°C, wash inside out, do not tumble dry'
        WHEN 'gender'            THEN 'Mens'
        WHEN 'available_sizes'   THEN '28×30, 30×30, 32×30, 32×32, 34×30, 34×32, 36×32'
        WHEN 'fit'               THEN 'Slim'
        WHEN 'season'            THEN 'All Season'
        ELSE NULL END
      WHEN 'NOVA-JN-002' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'High-rise wide leg jeans in a light wash. A fashion-forward silhouette with a comfortable straight leg.'
        WHEN 'short_description' THEN 'High-rise wide leg jeans, light wash'
        WHEN 'color'             THEN 'Light Blue'
        WHEN 'material'          THEN '100% Cotton'
        WHEN 'care_instructions' THEN 'Machine wash 30°C, wash inside out'
        WHEN 'gender'            THEN 'Womens'
        WHEN 'available_sizes'   THEN 'XS, S, M, L, XL'
        WHEN 'fit'               THEN 'Wide Leg'
        WHEN 'season'            THEN 'All Season'
        ELSE NULL END
      WHEN 'NOVA-JN-003' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'Classic skinny jeans in a sleek black. High-stretch fabric hugs curves and retains shape wash after wash.'
        WHEN 'short_description' THEN 'Skinny jeans, black stretch denim'
        WHEN 'color'             THEN 'Black'
        WHEN 'material'          THEN '95% Cotton, 5% Elastane'
        WHEN 'care_instructions' THEN 'Machine wash 30°C, wash inside out'
        WHEN 'gender'            THEN 'Womens'
        WHEN 'available_sizes'   THEN 'XS, S, M, L, XL'
        WHEN 'fit'               THEN 'Skinny'
        WHEN 'season'            THEN 'All Season'
        ELSE NULL END
      WHEN 'NOVA-DR-001' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'A flowing midi dress in a vibrant floral print. Lightweight viscose fabric with a V-neckline and flutter sleeves.'
        WHEN 'short_description' THEN 'Floral midi dress, viscose, flutter sleeve'
        WHEN 'color'             THEN 'Multi-Floral'
        WHEN 'material'          THEN '100% Viscose'
        WHEN 'care_instructions' THEN 'Hand wash cold, hang to dry, cool iron'
        WHEN 'gender'            THEN 'Womens'
        WHEN 'available_sizes'   THEN 'XS, S, M, L, XL'
        WHEN 'fit'               THEN 'Regular'
        WHEN 'season'            THEN 'Spring/Summer'
        ELSE NULL END
      WHEN 'NOVA-DR-002' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'Effortlessly versatile wrap dress that transitions from day to evening. Available in eight solid shades.'
        WHEN 'short_description' THEN 'Wrap dress, solid colours, day-to-evening'
        WHEN 'color'             THEN 'Terracotta'
        WHEN 'material'          THEN '95% Viscose, 5% Elastane'
        WHEN 'care_instructions' THEN 'Machine wash 30°C, hang to dry'
        WHEN 'gender'            THEN 'Womens'
        WHEN 'available_sizes'   THEN 'XS, S, M, L, XL'
        WHEN 'fit'               THEN 'Wrap'
        WHEN 'season'            THEN 'All Season'
        ELSE NULL END
      WHEN 'NOVA-OW-001' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'Warm and lightweight puffer jacket filled with 100% recycled PET insulation. Packable into its own pocket.'
        WHEN 'short_description' THEN 'Puffer jacket, recycled fill, packable'
        WHEN 'color'             THEN 'Forest Green'
        WHEN 'material'          THEN 'Shell: 100% Recycled Nylon, Fill: 100% Recycled PET'
        WHEN 'care_instructions' THEN 'Machine wash 30°C, tumble dry low'
        WHEN 'gender'            THEN 'Unisex'
        WHEN 'available_sizes'   THEN 'XS, S, M, L, XL, XXL'
        WHEN 'fit'               THEN 'Regular'
        WHEN 'season'            THEN 'Autumn/Winter'
        ELSE NULL END
      WHEN 'NOVA-OW-002' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'A classic double-breasted trench coat in a premium wool-blend fabric. Timeless and tailored.'
        WHEN 'short_description' THEN 'Double-breasted wool-blend trench coat'
        WHEN 'color'             THEN 'Camel'
        WHEN 'material'          THEN '60% Wool, 30% Polyester, 10% Nylon'
        WHEN 'care_instructions' THEN 'Dry clean only'
        WHEN 'gender'            THEN 'Womens'
        WHEN 'available_sizes'   THEN 'XS, S, M, L'
        WHEN 'fit'               THEN 'Tailored'
        WHEN 'season'            THEN 'Autumn/Winter'
        ELSE NULL END
      WHEN 'NOVA-AW-001' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'High-performance running leggings with 4-way stretch fabric, flatlock seams, and deep waistband pockets.'
        WHEN 'short_description' THEN 'Running leggings, 4-way stretch, high-waist'
        WHEN 'color'             THEN 'Black'
        WHEN 'material'          THEN '82% Polyamide, 18% Elastane'
        WHEN 'care_instructions' THEN 'Machine wash 30°C, do not tumble dry'
        WHEN 'gender'            THEN 'Womens'
        WHEN 'available_sizes'   THEN 'XS, S, M, L, XL'
        WHEN 'fit'               THEN 'Compression'
        WHEN 'season'            THEN 'All Season'
        ELSE NULL END
      WHEN 'NOVA-AW-002' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'Seamlessly knitted sports bra for medium-impact activities. Moisture-wicking and breathable.'
        WHEN 'short_description' THEN 'Seamless sports bra, medium impact'
        WHEN 'color'             THEN 'Dusty Rose'
        WHEN 'material'          THEN '73% Polyamide, 27% Elastane'
        WHEN 'care_instructions' THEN 'Machine wash 30°C, do not tumble dry, do not iron'
        WHEN 'gender'            THEN 'Womens'
        WHEN 'available_sizes'   THEN 'XS/S, S/M, M/L, L/XL'
        WHEN 'fit'               THEN 'Fitted'
        WHEN 'season'            THEN 'All Season'
        ELSE NULL END
      WHEN 'NOVA-FT-001' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'Handcrafted leather Chelsea boots with a pull-on elastic gusset. Leather sole with rubber heel cap.'
        WHEN 'short_description' THEN 'Leather Chelsea boots, pull-on'
        WHEN 'color'             THEN 'Tan'
        WHEN 'material'          THEN 'Upper: Full-grain leather, Sole: Leather/Rubber'
        WHEN 'care_instructions' THEN 'Clean with leather cloth, condition regularly'
        WHEN 'gender'            THEN 'Unisex'
        WHEN 'available_sizes'   THEN 'EU 36, 37, 38, 39, 40, 41, 42, 43, 44, 45'
        WHEN 'season'            THEN 'Autumn/Winter'
        WHEN 'country_of_origin' THEN 'Spain'
        ELSE NULL END
      WHEN 'NOVA-FT-002' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'Casual canvas trainers with a rubber sole and metal eyelets. A wardrobe staple.'
        WHEN 'short_description' THEN 'Canvas trainers, rubber sole'
        WHEN 'color'             THEN 'Off-White'
        WHEN 'material'          THEN 'Upper: 100% Canvas, Sole: Rubber'
        WHEN 'care_instructions' THEN 'Spot clean only, allow to air dry'
        WHEN 'gender'            THEN 'Unisex'
        WHEN 'available_sizes'   THEN 'EU 36–45'
        WHEN 'season'            THEN 'Spring/Summer'
        ELSE NULL END
      WHEN 'NOVA-FT-003' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'Handwoven jute and canvas espadrilles with a crepe rubber sole. Perfect for warm-weather holidays.'
        WHEN 'short_description' THEN 'Espadrille sandals, jute and canvas'
        WHEN 'color'             THEN 'Navy'
        WHEN 'material'          THEN 'Upper: Canvas + Jute, Sole: Natural Crepe Rubber'
        WHEN 'care_instructions' THEN 'Spot clean only, do not wet'
        WHEN 'gender'            THEN 'Womens'
        WHEN 'available_sizes'   THEN 'EU 36–41'
        WHEN 'season'            THEN 'Spring/Summer'
        WHEN 'country_of_origin' THEN 'Spain'
        ELSE NULL END
      WHEN 'NOVA-BG-001' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'Full-grain leather backpack with padded 15" laptop sleeve, organiser pockets, and YKK zips.'
        WHEN 'short_description' THEN 'Full-grain leather backpack, 22L'
        WHEN 'color'             THEN 'Black'
        WHEN 'material'          THEN 'Full-grain vegetable-tanned leather'
        WHEN 'care_instructions' THEN 'Wipe clean with a damp cloth, condition regularly'
        WHEN 'season'            THEN 'All Season'
        ELSE NULL END
      WHEN 'NOVA-BG-002' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'Roomy canvas tote bag. GOTS-certified organic cotton with reinforced handles and an inner zip pocket.'
        WHEN 'short_description' THEN 'Organic cotton canvas tote, 15L'
        WHEN 'color'             THEN 'Natural'
        WHEN 'material'          THEN '100% GOTS-certified Organic Cotton'
        WHEN 'care_instructions' THEN 'Machine wash 30°C, hang to dry'
        WHEN 'season'            THEN 'All Season'
        ELSE NULL END
      WHEN 'NOVA-TR-001' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'Slim tapered chinos in a stretch twill fabric. Perfect for smart-casual occasions.'
        WHEN 'short_description' THEN 'Tailored chino trousers, slim taper'
        WHEN 'color'             THEN 'Khaki'
        WHEN 'material'          THEN '97% Cotton, 3% Elastane'
        WHEN 'care_instructions' THEN 'Machine wash 40°C, tumble dry low, iron on medium'
        WHEN 'gender'            THEN 'Mens'
        WHEN 'available_sizes'   THEN '28×30, 30×30, 32×30, 32×32, 34×30, 34×32'
        WHEN 'fit'               THEN 'Slim Taper'
        WHEN 'season'            THEN 'All Season'
        ELSE NULL END
      WHEN 'NOVA-TR-002' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'Comfortable French-terry jogger sweatpants with an elasticated drawstring waist and deep side pockets.'
        WHEN 'short_description' THEN 'Jogger sweatpants, French terry, relaxed fit'
        WHEN 'color'             THEN 'Charcoal Grey'
        WHEN 'material'          THEN '80% Cotton, 20% Polyester'
        WHEN 'care_instructions' THEN 'Machine wash 30°C, tumble dry low'
        WHEN 'gender'            THEN 'Unisex'
        WHEN 'available_sizes'   THEN 'XS, S, M, L, XL, XXL'
        WHEN 'fit'               THEN 'Relaxed'
        WHEN 'season'            THEN 'All Season'
        ELSE NULL END
      WHEN 'NOVA-SH-003' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'Six-pocket cargo shorts in ripstop cotton. Drawstring hem for an adjustable fit.'
        WHEN 'short_description' THEN 'Cargo shorts, ripstop cotton, 6 pockets'
        WHEN 'color'             THEN 'Olive'
        WHEN 'material'          THEN '100% Ripstop Cotton'
        WHEN 'care_instructions' THEN 'Machine wash 40°C, tumble dry low'
        WHEN 'gender'            THEN 'Mens'
        WHEN 'available_sizes'   THEN 'S, M, L, XL, XXL'
        WHEN 'fit'               THEN 'Regular'
        WHEN 'season'            THEN 'Spring/Summer'
        ELSE NULL END
      WHEN 'NOVA-KN-003' THEN CASE a.attribute_code
        WHEN 'description'       THEN 'Luxuriously soft cashmere roll-neck knit. Now discontinued — final stock available.'
        WHEN 'short_description' THEN 'Cashmere roll-neck, 100% cashmere'
        WHEN 'color'             THEN 'Ivory'
        WHEN 'material'          THEN '100% Grade A Cashmere'
        WHEN 'care_instructions' THEN 'Dry clean only, or hand wash cold'
        WHEN 'gender'            THEN 'Womens'
        WHEN 'available_sizes'   THEN 'S, M'
        WHEN 'season'            THEN 'Autumn/Winter'
        ELSE NULL END
      ELSE NULL
    END,
    NULL, -- bool_value
    NULL  -- date_value
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE l.language_code = 'en'
  AND a.attribute_code IN ('description','short_description','color','material','care_instructions',
                           'gender','age_group','country_of_origin','season','fit',
                           'available_sizes','ean')
  AND p.sku IN ('NOVA-TS-001','NOVA-TS-002','NOVA-TS-003','NOVA-SH-001','NOVA-SH-002',
                'NOVA-KN-001','NOVA-KN-002','NOVA-KN-003','NOVA-JN-001','NOVA-JN-002','NOVA-JN-003',
                'NOVA-TR-001','NOVA-TR-002','NOVA-SH-003','NOVA-DR-001','NOVA-DR-002',
                'NOVA-OW-001','NOVA-OW-002','NOVA-AW-001','NOVA-AW-002',
                'NOVA-FT-001','NOVA-FT-002','NOVA-FT-003','NOVA-BG-001','NOVA-BG-002');

-- Sustainable flag
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, bool_value)
SELECT p.product_id, a.attribute_id, NULL, 1
FROM Products p CROSS JOIN Attributes a
WHERE a.attribute_code = 'is_sustainable'
  AND p.sku IN ('NOVA-TS-003','NOVA-OW-001','NOVA-BG-002');

-- Release dates
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, date_value)
SELECT p.product_id, a.attribute_id, NULL,
    CASE p.sku
        WHEN 'NOVA-DR-001' THEN '2024-03-01'
        WHEN 'NOVA-DR-002' THEN '2024-03-01'
        WHEN 'NOVA-SH-002' THEN '2024-03-01'
        WHEN 'NOVA-FT-003' THEN '2024-03-01'
        WHEN 'NOVA-OW-001' THEN '2024-09-01'
        WHEN 'NOVA-OW-002' THEN '2024-09-01'
        WHEN 'NOVA-KN-001' THEN '2024-09-01'
        WHEN 'NOVA-KN-002' THEN '2024-09-01'
        ELSE '2024-01-15'
    END
FROM Products p CROSS JOIN Attributes a
WHERE a.attribute_code = 'release_date';

-- French translations (selected products)
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE p.sku
        WHEN 'NOVA-TS-001' THEN CASE a.attribute_code
            WHEN 'color'             THEN 'Blanc'
            WHEN 'short_description' THEN 'T-shirt col rond 100 % coton bio, coupe décontractée'
            WHEN 'description'       THEN 'Le T-shirt Nova Classic Logo. 100 % coton bio dans une coupe décontractée. Disponible en 8 couleurs.'
            WHEN 'fit'               THEN 'Décontracté'
            WHEN 'care_instructions' THEN 'Lavage machine 30°C, ne pas sécher en machine'
            ELSE NULL END
        WHEN 'NOVA-KN-001' THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'Pull col rond en mérinos extra-fin, 100 % laine'
            WHEN 'description'       THEN 'Pull col rond en laine mérinos extra-fine 100 %. Incroyablement doux, thermorégulant et naturellement anti-odeur.'
            WHEN 'color'             THEN 'Flocon d''avoine'
            WHEN 'care_instructions' THEN 'Lavage main froid ou programme délicat, sécher à plat'
            ELSE NULL END
        WHEN 'NOVA-OW-001' THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'Doudoune en rembourrage recyclé, pliable'
            WHEN 'description'       THEN 'Doudoune légère et chaude, rembourrage 100 % PET recyclé. Se glisse dans sa propre poche.'
            WHEN 'color'             THEN 'Vert forêt'
            WHEN 'care_instructions' THEN 'Lavage machine 30°C, séchage machine programme doux'
            ELSE NULL END
        ELSE NULL
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE l.language_code = 'fr'
  AND p.sku IN ('NOVA-TS-001','NOVA-KN-001','NOVA-OW-001')
  AND a.attribute_code IN ('color','short_description','description','fit','care_instructions');

-- German translations
INSERT INTO ProductAttributeValues (product_id, attribute_id, language_id, text_value)
SELECT p.product_id, a.attribute_id, l.language_id,
    CASE p.sku
        WHEN 'NOVA-TS-001' THEN CASE a.attribute_code
            WHEN 'color'             THEN 'Weiß'
            WHEN 'short_description' THEN '100 % Bio-Baumwoll-T-Shirt mit Rundhalsausschnitt, Relaxed Fit'
            WHEN 'description'       THEN 'Das Nova Classic Logo T-Shirt. 100 % Bio-Baumwolle in lockerer Passform. In 8 Farben erhältlich.'
            WHEN 'care_instructions' THEN 'Maschinenwäsche 30°C, nicht im Trockner trocknen'
            ELSE NULL END
        WHEN 'NOVA-KN-001' THEN CASE a.attribute_code
            WHEN 'short_description' THEN 'Extrafeiner Merino-Rundhals-Pullover, 100 % Wolle'
            WHEN 'description'       THEN '100 % extrafeiner Merino-Wollpullover mit Rundhalsausschnitt. Unglaublich weich und temperaturregulierend.'
            WHEN 'color'             THEN 'Haferflocken'
            WHEN 'care_instructions' THEN 'Handwäsche kalt oder Schonprogramm, liegend trocknen'
            ELSE NULL END
        ELSE NULL
    END
FROM Products p CROSS JOIN Attributes a CROSS JOIN Languages l
WHERE l.language_code = 'de'
  AND p.sku IN ('NOVA-TS-001','NOVA-KN-001')
  AND a.attribute_code IN ('color','short_description','description','care_instructions');

-- ---------------------------------------------------------------------------
-- ProductChannels
-- ---------------------------------------------------------------------------
INSERT INTO ProductChannels (product_id, channel_id, is_published, published_at)
SELECT p.product_id, c.channel_id, 1, SYSUTCDATETIME()
FROM Products p CROSS JOIN Channels c
WHERE p.status = 'active'
  AND c.channel_code = 'web';

INSERT INTO ProductChannels (product_id, channel_id, is_published, published_at)
SELECT p.product_id, c.channel_id, 1, SYSUTCDATETIME()
FROM Products p CROSS JOIN Channels c
WHERE p.sku IN ('NOVA-DR-001','NOVA-DR-002','NOVA-SH-002','NOVA-FT-003',
                'NOVA-TS-001','NOVA-TS-002','NOVA-TS-003','NOVA-AW-001','NOVA-AW-002')
  AND c.channel_code = 'summer';

INSERT INTO ProductChannels (product_id, channel_id, is_published, published_at)
SELECT p.product_id, c.channel_id, 1, SYSUTCDATETIME()
FROM Products p CROSS JOIN Channels c
WHERE p.sku IN ('NOVA-KN-001','NOVA-KN-002','NOVA-OW-001','NOVA-OW-002','NOVA-FT-001')
  AND c.channel_code = 'winter';

INSERT INTO ProductChannels (product_id, channel_id, is_published, published_at)
SELECT p.product_id, c.channel_id, 1, SYSUTCDATETIME()
FROM Products p CROSS JOIN Channels c
WHERE p.sku IN ('NOVA-KN-003')
  AND c.channel_code = 'outlet';

-- ---------------------------------------------------------------------------
-- MediaAssets
-- ---------------------------------------------------------------------------
INSERT INTO MediaAssets (product_id, asset_type, file_name, url, alt_text, sort_order)
SELECT p.product_id, 'image',
    p.sku + '-front.jpg',
    'https://cdn.nova-retail.example/products/' + p.sku + '-front.jpg',
    p.product_name + ' — front',
    1
FROM Products p;

INSERT INTO MediaAssets (product_id, asset_type, file_name, url, alt_text, sort_order)
SELECT p.product_id, 'image',
    p.sku + '-back.jpg',
    'https://cdn.nova-retail.example/products/' + p.sku + '-back.jpg',
    p.product_name + ' — back',
    2
FROM Products p WHERE p.sku IN ('NOVA-TS-001','NOVA-JN-001','NOVA-JN-002','NOVA-JN-003',
                                 'NOVA-DR-001','NOVA-DR-002','NOVA-OW-001','NOVA-OW-002');

INSERT INTO MediaAssets (product_id, asset_type, file_name, url, alt_text, sort_order)
SELECT p.product_id, 'image',
    p.sku + '-lifestyle.jpg',
    'https://cdn.nova-retail.example/products/' + p.sku + '-lifestyle.jpg',
    p.product_name + ' — lifestyle shot',
    3
FROM Products p WHERE p.sku IN ('NOVA-DR-001','NOVA-DR-002','NOVA-OW-001','NOVA-FT-001','NOVA-BG-001');
