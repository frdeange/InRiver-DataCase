-- ============================================================
-- Seed Data: Nova Industries (Electronics & Semiconductors)
-- Target: db-nova
-- ============================================================

-- ---- Categories (15 total, 2-level hierarchy) ----
SET IDENTITY_INSERT Categories ON;

INSERT INTO Categories (CategoryId, CategoryName, ParentCategoryId, [Description], IsActive)
VALUES
    (1,  'Semiconductors',      NULL, 'ICs, microcontrollers and processors',       1),
    (2,  'Passive Components',  NULL, 'Resistors, capacitors and inductors',        1),
    (3,  'Connectors',          NULL, 'Board-to-board, wire-to-board, I/O',         1),
    (4,  'Displays',            NULL, 'LCD, OLED and LED display modules',          1),
    (5,  'Microcontrollers',    1,    '8/16/32-bit MCUs',                           1),
    (6,  'Memory ICs',          1,    'SRAM, DRAM, Flash',                          1),
    (7,  'Power ICs',           1,    'Voltage regulators, DC-DC converters',       1),
    (8,  'Capacitors',          2,    'Ceramic, electrolytic, film',                1),
    (9,  'Resistors',           2,    'SMD and through-hole resistors',             1),
    (10, 'Inductors',           2,    'Power and RF inductors',                     1),
    (11, 'Board-to-Board',      3,    'Pin headers, sockets and mezzanine',        1),
    (12, 'Wire-to-Board',       3,    'Crimp, IDC and spring connectors',           1),
    (13, 'OLED Displays',       4,    'Organic LED display modules',                1),
    (14, 'LCD Displays',        4,    'TFT and segment LCD modules',                1),
    (15, 'LED Modules',         4,    'Addressable and matrix LED modules',         1);

SET IDENTITY_INSERT Categories OFF;

-- ---- Attributes (10) ----
SET IDENTITY_INSERT Attributes ON;

INSERT INTO Attributes (AttributeId, AttributeName, DataType, Unit, IsRequired)
VALUES
    (1,  'Weight',            'Number',  'g',     1),
    (2,  'Package',           'Text',    NULL,    1),
    (3,  'OperatingVoltage',  'Number',  'V',     0),
    (4,  'Tolerance',         'Text',    NULL,    0),
    (5,  'OperatingTemp',     'Text',    NULL,    0),
    (6,  'Capacitance',       'Text',    NULL,    0),
    (7,  'Resistance',        'Text',    NULL,    0),
    (8,  'ClockSpeed',        'Number',  'MHz',   0),
    (9,  'Resolution',        'Text',    NULL,    0),
    (10, 'Interface',         'Text',    NULL,    0);

SET IDENTITY_INSERT Attributes OFF;

-- ---- Products (15) ----
SET IDENTITY_INSERT Products ON;

INSERT INTO Products (ProductId, ProductNumber, ProductName, [Description], CategoryId, Brand, Status, ListPrice, Currency, SKU, IsActive)
VALUES
    (1,  'NOVA-MCU-001', 'NovaChip ARM Cortex-M4 MCU',        '32-bit ARM Cortex-M4 168MHz 512KB Flash',            5,  'NovaChip',    'Published', 4.85,   'USD', 'NC-MCU-M4',    1),
    (2,  'NOVA-MCU-002', 'NovaChip RISC-V MCU 32-bit',        '32-bit RISC-V 120MHz 256KB Flash',                   5,  'NovaChip',    'Published', 2.99,   'USD', 'NC-MCU-RV32',  1),
    (3,  'NOVA-MEM-001', 'NovaChip 8MB SPI Flash',            '64Mbit SPI NOR Flash 133MHz',                        6,  'NovaChip',    'Published', 1.45,   'USD', 'NC-MEM-8M',    1),
    (4,  'NOVA-PWR-001', 'NovaChip 3.3V LDO Regulator',       '3.3V 500mA low-dropout voltage regulator SOT-223',   7,  'NovaChip',    'Published', 0.35,   'USD', 'NC-PWR-33',    1),
    (5,  'NOVA-PWR-002', 'NovaChip 5V Buck Converter',        '5V 2A synchronous step-down converter',              7,  'NovaChip',    'Published', 1.20,   'USD', 'NC-PWR-5B',    1),
    (6,  'NOVA-CAP-001', 'NovaPassive 100nF MLCC 0402',       '100nF 16V X7R ceramic capacitor 0402',               8,  'NovaPassive', 'Published', 0.02,   'USD', 'NP-CAP-100N',  1),
    (7,  'NOVA-CAP-002', 'NovaPassive 10uF Electrolytic',     '10uF 25V aluminum electrolytic capacitor',           8,  'NovaPassive', 'Published', 0.08,   'USD', 'NP-CAP-10U',   1),
    (8,  'NOVA-RES-001', 'NovaPassive 10K Ohm 0603',          '10K Ohm 1% 0603 thick film resistor',                9,  'NovaPassive', 'Published', 0.01,   'USD', 'NP-RES-10K',   1),
    (9,  'NOVA-RES-002', 'NovaPassive 4.7K Ohm 0402',         '4.7K Ohm 1% 0402 thin film resistor',               9,  'NovaPassive', 'Published', 0.01,   'USD', 'NP-RES-47K',   1),
    (10, 'NOVA-IND-001', 'NovaPassive 10uH Power Inductor',   '10uH 3A shielded power inductor',                   10, 'NovaPassive', 'Published', 0.55,   'USD', 'NP-IND-10U',   1),
    (11, 'NOVA-CON-001', 'NovaLink 2x20 Pin Header 2.54mm',   'Male double-row pin header 40-pin',                  11, 'NovaLink',    'Published', 0.30,   'USD', 'NL-CON-2X20',  1),
    (12, 'NOVA-CON-002', 'NovaLink JST-XH 4-Pin Connector',   'Wire-to-board 4-pin 2.5mm pitch',                    12, 'NovaLink',    'Published', 0.18,   'USD', 'NL-CON-XH4',   1),
    (13, 'NOVA-DSP-001', 'NovaDisplay 1.3" OLED 128x64',      '1.3 inch white OLED display SSD1306 I2C',            13, 'NovaDisplay', 'Published', 6.50,   'USD', 'ND-DSP-13O',   1),
    (14, 'NOVA-DSP-002', 'NovaDisplay 2.4" TFT LCD 240x320',  '2.4 inch TFT LCD ILI9341 SPI',                       14, 'NovaDisplay', 'Published', 8.99,   'USD', 'ND-DSP-24T',   1),
    (15, 'NOVA-DSP-003', 'NovaDisplay 8x8 LED Matrix WS2812', 'Addressable RGB LED 8x8 matrix panel',               15, 'NovaDisplay', 'Approved',  12.50,  'USD', 'ND-DSP-8X8',   1);

SET IDENTITY_INSERT Products OFF;

-- ---- ProductAttributes ----
INSERT INTO ProductAttributes (ProductId, AttributeId, [Value])
VALUES
    -- NovaChip ARM Cortex-M4
    (1, 1, '5'),    (1, 2, 'LQFP-64'),    (1, 3, '3.3'),    (1, 5, '-40 to 85C'),    (1, 8, '168'),
    -- NovaChip RISC-V MCU
    (2, 1, '3'),    (2, 2, 'QFN-48'),    (2, 3, '3.3'),    (2, 8, '120'),
    -- NovaChip SPI Flash
    (3, 1, '0.5'),    (3, 2, 'SOP-8'),    (3, 3, '3.3'),    (3, 10, 'SPI'),
    -- NovaChip LDO
    (4, 1, '0.2'),    (4, 2, 'SOT-223'),    (4, 3, '3.3'),
    -- NovaPassive MLCC
    (6, 1, '0.01'),   (6, 2, '0402'),    (6, 4, '10%'),    (6, 6, '100nF'),
    -- NovaPassive Electrolytic
    (7, 1, '1.5'),    (7, 2, 'Radial'),    (7, 6, '10uF'),
    -- NovaPassive 10K Resistor
    (8, 1, '0.005'),  (8, 2, '0603'),    (8, 4, '1%'),    (8, 7, '10K Ohm'),
    -- NovaDisplay OLED
    (13, 1, '8'),   (13, 9, '128x64'),    (13, 10, 'I2C'),    (13, 3, '3.3'),
    -- NovaDisplay TFT LCD
    (14, 1, '25'),  (14, 9, '240x320'),   (14, 10, 'SPI'),    (14, 3, '3.3');

-- ---- Customers (8) ----
SET IDENTITY_INSERT Customers ON;

INSERT INTO Customers (CustomerId, CustomerName, ContactEmail, Country, Segment, IsActive)
VALUES
    (1, 'Shenzhen MakerHub Co.',       'sales@makerhub.cn',            'China',          'Distributor',  1),
    (2, 'DigiParts Europe BV',         'orders@digiparts.nl',          'Netherlands',    'Distributor',  1),
    (3, 'Silicon Valley Robotics Inc.', 'procurement@svrobotics.com',   'United States',  'OEM',          1),
    (4, 'Bangalore IoT Solutions',      'purchase@bangaloreiot.in',     'India',          'OEM',          1),
    (5, 'Seoul Semiconductor Ltd.',     'parts@seoulsemi.kr',           'South Korea',    'Manufacturer', 1),
    (6, 'Munich Embedded Systems GmbH', 'einkauf@munichembedded.de',    'Germany',        'OEM',          1),
    (7, 'TechTronics Japan',            'info@techtronics.jp',          'Japan',          'Distributor',  1),
    (8, 'Nairobi Makers Lab',           'orders@nairobimakerslab.ke',   'Kenya',          'Education',    1);

SET IDENTITY_INSERT Customers OFF;

-- ---- Orders (12) ----
SET IDENTITY_INSERT Orders ON;

INSERT INTO Orders (OrderId, OrderNumber, CustomerId, ProductId, Quantity, UnitPrice, OrderDate, [Status])
VALUES
    (1,  'NOVA-ORD-0001', 1, 1,  5000,  4.85,  '2026-01-10', 'Delivered'),
    (2,  'NOVA-ORD-0002', 1, 6,  50000, 0.02,  '2026-01-10', 'Delivered'),
    (3,  'NOVA-ORD-0003', 2, 8,  100000,0.01,  '2026-01-22', 'Shipped'),
    (4,  'NOVA-ORD-0004', 3, 2,  2000,  2.99,  '2026-02-01', 'Shipped'),
    (5,  'NOVA-ORD-0005', 4, 13, 500,   6.50,  '2026-02-10', 'Confirmed'),
    (6,  'NOVA-ORD-0006', 5, 5,  10000, 1.20,  '2026-02-15', 'Confirmed'),
    (7,  'NOVA-ORD-0007', 6, 1,  1000,  4.85,  '2026-02-28', 'Pending'),
    (8,  'NOVA-ORD-0008', 7, 14, 300,   8.99,  '2026-03-05', 'Pending'),
    (9,  'NOVA-ORD-0009', 3, 4,  20000, 0.35,  '2026-03-08', 'Confirmed'),
    (10, 'NOVA-ORD-0010', 8, 15, 50,    12.50, '2026-03-12', 'Pending'),
    (11, 'NOVA-ORD-0011', 2, 11, 5000,  0.30,  '2026-03-18', 'Pending'),
    (12, 'NOVA-ORD-0012', 4, 10, 3000,  0.55,  '2026-03-22', 'Pending');

SET IDENTITY_INSERT Orders OFF;
