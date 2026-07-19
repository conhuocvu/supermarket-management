-- Additive demo data for the Sales Associate screens.
-- Safe to run on top of seed_data.sql: no TRUNCATE, explicit IDs with
-- ON CONFLICT DO NOTHING, and sequence bumps at the end.
-- Run in the Supabase SQL editor (or psql) against the project database.

-- 1. More products with images (picsum placeholders, same convention as seed_data.sql)
INSERT INTO products (product_number, category_number, inventory_unit_number, product_name, barcode, selling_price, reorder_level, status, description, image_url, expiry_warning_days) VALUES
(17, 16, 4, 'TH True Milk 1L',                 '8930000000017', 32000,  40, 'ACTIVE', 'UHT fresh milk from TH farms.',                        'https://picsum.photos/200/200?random=17', 30),
(18, 17, 4, 'Vinamilk Yogurt 100g x4',         '8930000000018', 28000,  30, 'ACTIVE', 'Sweetened yogurt 4-cup pack.',                         'https://picsum.photos/200/200?random=18', 20),
(19, 12, 3, 'G7 Instant Coffee 3in1 (20 sachets)', '8930000000019', 48000, 25, 'ACTIVE', 'Trung Nguyen G7 3-in-1 instant coffee.',           'https://picsum.photos/200/200?random=19', 90),
(20, 15, 2, 'Three Lady Cooks Canned Fish',    '8930000000020', 22000,  30, 'ACTIVE', 'Canned sardines in tomato sauce.',                     'https://picsum.photos/200/200?random=20', 180),
(21, 21, 7, 'Bien Hoa Sugar 1kg',              '8930000000021', 27000,  25, 'ACTIVE', 'Refined white sugar.',                                 'https://picsum.photos/200/200?random=21', 365),
(22, 25, 1, 'Gift Floor Cleaner 1L',           '8930000000022', 39000,  15, 'ACTIVE', 'Lily-scented floor cleaning liquid.',                  'https://picsum.photos/200/200?random=22', 365),
(23, 28, 1, 'Lifebuoy Body Wash 850g',         '8930000000023', 115000, 12, 'ACTIVE', 'Antibacterial body wash.',                             'https://picsum.photos/200/200?random=23', 365),
(24, 32, 3, 'Alpenliebe Candy Bag 115g',       '8930000000024', 16000,  35, 'ACTIVE', 'Caramel hard candy.',                                  'https://picsum.photos/200/200?random=24', 180),
(25, 29, 7, 'Dalat Tomato',                    '8930000000025', 30000,  25, 'ACTIVE', 'Fresh greenhouse tomatoes.',                           'https://picsum.photos/200/200?random=25', 7),
(26, 30, 7, 'Cavendish Banana',                '8930000000026', 28000,  30, 'ACTIVE', 'Ripe Cavendish bananas.',                              'https://picsum.photos/200/200?random=26', 5),
(27, 10, 2, 'Pepsi Can 320ml',                 '8930000000027', 10000,  48, 'ACTIVE', 'Carbonated cola soft drink.',                          'https://picsum.photos/200/200?random=27', 180),
(28, 13, 3, 'Omachi Beef Stew Noodles',        '8930000000028', 8000,   50, 'ACTIVE', 'Premium instant noodles, beef stew flavor.',           'https://picsum.photos/200/200?random=28', 120),
(29, 27, 15, 'Colgate MaxFresh 225g',          '8930000000029', 42000,  20, 'ACTIVE', 'Cooling crystal toothpaste.',                          'https://picsum.photos/200/200?random=29', 365),
(30, 31, 4, 'Cosy Marie Biscuits 320g',        '8930000000030', 25000,  25, 'ACTIVE', 'Classic Marie biscuits box.',                          'https://picsum.photos/200/200?random=30', 150)
ON CONFLICT (product_number) DO NOTHING;

-- 2. Supplier links for the new products
INSERT INTO product_suppliers (product_supplier_number, product_number, supplier_number, import_price, minimum_order_quantity) VALUES
(17, 17, 3, 25000, 24),
(18, 18, 3, 21000, 20),
(19, 19, 5, 38000, 12),
(20, 20, 5, 16000, 24),
(21, 21, 5, 21000, 20),
(22, 22, 6, 30000, 12),
(23, 23, 6, 88000, 6),
(24, 24, 7, 11000, 30),
(25, 25, 8, 18000, 20),
(26, 26, 8, 17000, 25),
(27, 27, 2, 7000, 48),
(28, 28, 4, 5800, 40),
(29, 29, 6, 31000, 24),
(30, 30, 7, 18000, 20)
ON CONFLICT (product_supplier_number) DO NOTHING;

-- 3. Inventory levels — mixed: healthy, low stock (< reorder_level), out of stock
INSERT INTO inventories (product_number, total_quantity, available_quantity, last_updated) VALUES
(17, 150, 150, NOW()),  -- healthy
(18,  22,  22, NOW()),  -- LOW (reorder 30)
(19,  80,  80, NOW()),  -- healthy
(20,  12,  12, NOW()),  -- LOW (reorder 30)
(21,  60,  60, NOW()),  -- healthy
(22,   0,   0, NOW()),  -- OUT OF STOCK
(23,  25,  25, NOW()),  -- healthy
(24,  90,  90, NOW()),  -- healthy
(25,  10,  10, NOW()),  -- LOW (reorder 25)
(26,   0,   0, NOW()),  -- OUT OF STOCK
(27, 200, 200, NOW()),  -- healthy
(28,  35,  35, NOW()),  -- LOW-ish (reorder 50)
(29,  48,  48, NOW()),  -- healthy
(30,  70,  70, NOW())   -- healthy
ON CONFLICT (product_number) DO NOTHING;

-- 4. Demo product reports for the Sales Associate flows
--    (report_type INVENTORY_ISSUE / UPDATE_SUGGESTION matches the new backend)
INSERT INTO product_reports (report_number, reported_by, product_number, report_type, issue_type, quantity, description, status, created_at) VALUES
(4, (SELECT user_id FROM profiles LIMIT 1), 18, 'INVENTORY_ISSUE', 'EXPIRED',  6,
 'Found 6 yogurt packs past expiry date on shelf B-2.', 'PENDING', NOW() - INTERVAL '6 hours'),
(5, (SELECT user_id FROM profiles LIMIT 1), 26, 'INVENTORY_ISSUE', 'DAMAGED', 12,
 'Banana bunch crushed during restocking, not sellable.', 'RESOLVED', NOW() - INTERVAL '2 days'),
(6, (SELECT user_id FROM profiles LIMIT 1), 25, 'INVENTORY_ISSUE', 'MISSING',  4,
 'Count mismatch: 4 tomato kg missing vs system record.', 'PENDING', NOW() - INTERVAL '1 day'),
(7, (SELECT user_id FROM profiles LIMIT 1), 27, 'UPDATE_SUGGESTION', 'PRICE_OR_INFO', NULL,
 'Selling price: 11000; Reason: Competitor price increased, margin too thin.', 'PENDING', NOW() - INTERVAL '3 hours'),
(8, (SELECT user_id FROM profiles LIMIT 1), 19, 'UPDATE_SUGGESTION', 'PRICE_OR_INFO', NULL,
 'Name: G7 Coffee 3in1 Box 20 sachets; Reason: Align name with supplier packaging.', 'APPROVED', NOW() - INTERVAL '4 days')
ON CONFLICT (report_number) DO NOTHING;

-- 5. Bump sequences past the explicit IDs so future backend inserts don't collide
SELECT setval('products_product_number_seq',                       (SELECT MAX(product_number)          FROM products));
SELECT setval('product_suppliers_product_supplier_number_seq',     (SELECT MAX(product_supplier_number) FROM product_suppliers));
SELECT setval('product_reports_report_number_seq',                 (SELECT MAX(report_number)           FROM product_reports));
