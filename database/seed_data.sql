-- Reset database records
TRUNCATE TABLE product_reports, promotion_products, promotions, 
               inventory_transactions, stock_in_details, stock_ins, 
               inventories, purchase_request_details, purchase_requests, 
               product_suppliers, products, units, categories, suppliers,
               profiles, roles RESTART IDENTITY CASCADE;

-- 1. Seed roles
INSERT INTO roles (role_number, role_name, description) VALUES
(1, 'Admin', 'System Administrator'),
(2, 'Manager', 'Store Manager'),
(3, 'Stock Controller', 'Stock Controller'),
(4, 'Sales Associate', 'Sales Associate'),
(5, 'Cashier', 'Cashier')
ON CONFLICT (role_number) DO NOTHING;

-- 2. Seed auth users and profiles for employees
INSERT INTO auth.users (id, email, encrypted_password, raw_app_meta_data, raw_user_meta_data, aud, role, is_sso_user, is_anonymous) VALUES
('f0000000-0000-0000-0000-000000000001', 'a@sms.com', '$2a$10$Vz2PvmaC0sRo4EtTzF3HWOxtJFM3z7ecRWzYB0hDVFQsoJYskXtta', '{"provider":"email","providers":["email"]}', '{"full_name":"Nguyen Van A","phone":"0912345678"}', 'authenticated', 'authenticated', FALSE, FALSE),
('f0000000-0000-0000-0000-000000000002', 'b@sms.com', '$2a$10$Vz2PvmaC0sRo4EtTzF3HWOxtJFM3z7ecRWzYB0hDVFQsoJYskXtta', '{"provider":"email","providers":["email"]}', '{"full_name":"Tran Thi B","phone":"0987654321"}', 'authenticated', 'authenticated', FALSE, FALSE),
('f0000000-0000-0000-0000-000000000003', 'c@sms.com', '$2a$10$Vz2PvmaC0sRo4EtTzF3HWOxtJFM3z7ecRWzYB0hDVFQsoJYskXtta', '{"provider":"email","providers":["email"]}', '{"full_name":"Le Van C","phone":"0901234567"}', 'authenticated', 'authenticated', FALSE, FALSE),
('f0000000-0000-0000-0000-000000000004', 'd@sms.com', '$2a$10$Vz2PvmaC0sRo4EtTzF3HWOxtJFM3z7ecRWzYB0hDVFQsoJYskXtta', '{"provider":"email","providers":["email"]}', '{"full_name":"Pham Thi D","phone":"0934567890"}', 'authenticated', 'authenticated', FALSE, FALSE),
('f0000000-0000-0000-0000-000000000005', 'e@sms.com', '$2a$10$Vz2PvmaC0sRo4EtTzF3HWOxtJFM3z7ecRWzYB0hDVFQsoJYskXtta', '{"provider":"email","providers":["email"]}', '{"full_name":"Hoang Van E","phone":"0976543210"}', 'authenticated', 'authenticated', FALSE, FALSE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO profiles (user_id, role_number, full_name, phone, status, created_at) VALUES
('f0000000-0000-0000-0000-000000000001', 3, 'Nguyen Van A', '0912345678', 'ACTIVE', NOW()),
('f0000000-0000-0000-0000-000000000002', 4, 'Tran Thi B', '0987654321', 'ACTIVE', NOW()),
('f0000000-0000-0000-0000-000000000003', 5, 'Le Van C', '0901234567', 'ACTIVE', NOW()),
('f0000000-0000-0000-0000-000000000004', 3, 'Pham Thi D', '0934567890', 'ACTIVE', NOW()),
('f0000000-0000-0000-0000-000000000005', 4, 'Hoang Van E', '0976543210', 'ACTIVE', NOW())
ON CONFLICT (user_id) DO UPDATE SET
  role_number = EXCLUDED.role_number,
  full_name = EXCLUDED.full_name,
  phone = EXCLUDED.phone,
  status = EXCLUDED.status;

-- 2b. Seed profiles for other existing auth users
INSERT INTO profiles (user_id, role_number, full_name, phone, status, created_at)
SELECT id, 3, 'John Doe', '0123456789', 'ACTIVE', NOW()
FROM auth.users
WHERE email = 'user@sms.com'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO profiles (user_id, role_number, full_name, phone, status, created_at)
SELECT id, 1, 'Admin User', '0987654321', 'ACTIVE', NOW()
FROM auth.users
WHERE email = 'minh@gmail.com'
ON CONFLICT (user_id) DO NOTHING;

-- Fallback default profile if auth.users is empty or doesn't match
INSERT INTO profiles (user_id, role_number, full_name, phone, status, created_at)
SELECT id, 1, 'Default System Admin', '0000000000', 'ACTIVE', NOW()
FROM auth.users
WHERE id NOT IN (SELECT user_id FROM profiles)
ON CONFLICT (user_id) DO NOTHING;

-- 3. Seed categories
-- Parent categories
INSERT INTO categories (category_number, parent_category_number, category_name, status) VALUES
(1, NULL, 'Beverages', 'ACTIVE'),
(2, NULL, 'Dry Food', 'ACTIVE'),
(3, NULL, 'Dairy Products', 'ACTIVE'),
(4, NULL, 'Seasonings & Condiments', 'ACTIVE'),
(5, NULL, 'Household Cleaning', 'ACTIVE'),
(6, NULL, 'Personal Care', 'ACTIVE'),
(7, NULL, 'Fresh Produce', 'ACTIVE'),
(8, NULL, 'Snacks & Confectionery', 'ACTIVE');

-- Child categories
INSERT INTO categories (category_number, parent_category_number, category_name, status) VALUES
(9, 1, 'Bottled Water', 'ACTIVE'),
(10, 1, 'Soft Drinks', 'ACTIVE'),
(11, 1, 'Bottled Tea', 'ACTIVE'),
(12, 1, 'Coffee', 'ACTIVE'),
(13, 2, 'Instant Noodles', 'ACTIVE'),
(14, 2, 'Rice', 'ACTIVE'),
(15, 2, 'Canned Food', 'ACTIVE'),
(16, 3, 'Milk', 'ACTIVE'),
(17, 3, 'Yogurt', 'ACTIVE'),
(18, 4, 'Cooking Oil', 'ACTIVE'),
(19, 4, 'Fish Sauce', 'ACTIVE'),
(20, 4, 'Soy Sauce', 'ACTIVE'),
(21, 4, 'Sugar', 'ACTIVE'),
(22, 4, 'Salt', 'ACTIVE'),
(23, 5, 'Laundry Detergent', 'ACTIVE'),
(24, 5, 'Dishwashing Liquid', 'ACTIVE'),
(25, 5, 'Floor Cleaner', 'ACTIVE'),
(26, 6, 'Shampoo', 'ACTIVE'),
(27, 6, 'Toothpaste', 'ACTIVE'),
(28, 6, 'Body Wash', 'ACTIVE'),
(29, 7, 'Vegetables', 'ACTIVE'),
(30, 7, 'Fruits', 'ACTIVE'),
(31, 8, 'Biscuits', 'ACTIVE'),
(32, 8, 'Candy', 'ACTIVE'),
(33, 8, 'Chips', 'ACTIVE');

-- 4. Seed units
INSERT INTO units (unit_number, unit_name) VALUES
(1, 'Bottle'),
(2, 'Can'),
(3, 'Pack'),
(4, 'Box'),
(5, 'Case'),
(6, 'Bundle'),
(7, 'Kg'),
(8, 'Gram'),
(9, 'Sack'),
(10, 'Bag'),
(11, 'Piece'),
(12, 'Liter'),
(13, 'Ml'),
(14, 'Carton'),
(15, 'Tube');

-- 5. Seed suppliers
INSERT INTO suppliers (supplier_number, supplier_name, phone, email, status) VALUES
(1, 'Lavie Distribution', '02839401111', 'sales@laviedist.vn', 'ACTIVE'),
(2, 'Coca-Cola Distribution', '02839402222', 'order@cocacoladist.vn', 'ACTIVE'),
(3, 'Vinamilk Distribution', '02839403333', 'sales@vinamilkdist.vn', 'ACTIVE'),
(4, 'Acecook Distribution', '02839404444', 'contact@acecookdist.vn', 'ACTIVE'),
(5, 'Masan Consumer Distribution', '02839405555', 'sales@masandist.vn', 'ACTIVE'),
(6, 'Unilever Distribution', '02839406666', 'support@unileverdist.vn', 'ACTIVE'),
(7, 'P&G Distribution', '02839407777', 'sales@pgdist.vn', 'ACTIVE'),
(8, 'Dalat Fresh Produce Supplier', '02633940888', 'contact@dalatfresh.vn', 'ACTIVE');

-- 6. Seed products
INSERT INTO products (product_number, category_number, inventory_unit_number, product_name, barcode, selling_price, reorder_level, status, description, image_url, expiry_warning_days) VALUES
(1, 9, 1, 'Lavie Bottled Water 500ml', '8930000000001', 6000, 48, 'ACTIVE', 'Pure mineral water bottled at source in Dalat.', 'https://picsum.photos/200/200?random=1', 30),
(2, 10, 2, 'Coca-Cola Can 320ml', '8930000000002', 10000, 48, 'ACTIVE', 'Classic carbonated soft drink.', 'https://picsum.photos/200/200?random=2', 30),
(3, 11, 1, 'Zero Degree Green Tea 455ml', '8930000000003', 12000, 36, 'ACTIVE', 'Refreshing green tea with lemon flavor.', 'https://picsum.photos/200/200?random=3', 30),
(4, 13, 3, 'Hao Hao Sour Hot Instant Noodles', '8930000000004', 4500, 60, 'ACTIVE', 'Popular Vietnamese sour and hot shrimp noodles.', 'https://picsum.photos/200/200?random=4', 30),
(5, 14, 7, 'ST25 Rice', '8930000000005', 32000, 50, 'ACTIVE', 'Premium fragrant rice from Soc Trang, Vietnam.', 'https://picsum.photos/200/200?random=5', 30),
(6, 16, 4, 'Vinamilk Fresh Milk 180ml', '8930000000006', 8000, 60, 'ACTIVE', '100% pure fresh milk with sugar.', 'https://picsum.photos/200/200?random=6', 30),
(7, 18, 1, 'Tuong An Cooking Oil 1L', '8930000000007', 48000, 20, 'ACTIVE', 'Refined vegetable oil for cooking.', 'https://picsum.photos/200/200?random=7', 30),
(8, 19, 1, 'Nam Ngu Fish Sauce 500ml', '8930000000008', 35000, 20, 'ACTIVE', 'Rich and tasty traditional Vietnamese fish sauce.', 'https://picsum.photos/200/200?random=8', 30),
(9, 23, 10, 'OMO Laundry Detergent 3kg', '8930000000009', 125000, 10, 'ACTIVE', 'Deep cleaning laundry powder detergent.', 'https://picsum.photos/200/200?random=9', 30),
(10, 24, 1, 'Sunlight Dishwashing Liquid 750ml', '8930000000010', 32000, 15, 'ACTIVE', 'Fast grease removal dishwashing liquid.', 'https://picsum.photos/200/200?random=10', 30),
(11, 26, 1, 'Clear Shampoo 650g', '8930000000011', 145000, 10, 'ACTIVE', 'Anti-dandruff shampoo for cool sensation.', 'https://picsum.photos/200/200?random=11', 30),
(12, 27, 15, 'P/S Toothpaste 180g', '8930000000012', 28000, 20, 'ACTIVE', 'PS cavity protection toothpaste.', 'https://picsum.photos/200/200?random=12', 30),
(13, 31, 3, 'Oreo Chocolate Sandwich Cookies', '8930000000013', 15000, 30, 'ACTIVE', 'Chocolate cookies with rich cream filling.', 'https://picsum.photos/200/200?random=13', 30),
(14, 33, 3, 'Lay''s Classic Potato Chips', '8930000000014', 18000, 30, 'ACTIVE', 'Crispy and salty classic potato chips.', 'https://picsum.photos/200/200?random=14', 30),
(15, 29, 7, 'Dalat Carrot', '8930000000015', 25000, 20, 'ACTIVE', 'Fresh sweet carrots from Dalat farms.', 'https://picsum.photos/200/200?random=15', 30),
(16, 30, 7, 'Fuji Apple', '8930000000016', 65000, 20, 'ACTIVE', 'Sweet, crisp, and juicy Fuji apples.', 'https://picsum.photos/200/200?random=16', 30);

-- 7. Seed product suppliers
INSERT INTO product_suppliers (product_supplier_number, product_number, supplier_number, import_price, minimum_order_quantity) VALUES
(1, 1, 1, 4000, 12),
(2, 2, 2, 7000, 24),
(3, 3, 2, 8500, 12),
(4, 4, 4, 3200, 30),
(5, 5, 5, 24000, 10),
(6, 6, 3, 6000, 48),
(7, 7, 5, 36000, 12),
(8, 8, 5, 26000, 12),
(9, 9, 6, 95000, 6),
(10, 10, 6, 24000, 12),
(11, 11, 6, 110000, 6),
(12, 12, 6, 20000, 24),
(13, 13, 7, 11000, 24),
(14, 14, 7, 13000, 24),
(15, 15, 8, 15000, 20),
(16, 16, 8, 45000, 15);

-- 8. Seed inventories
INSERT INTO inventories (product_number, total_quantity, available_quantity, last_updated) VALUES
(1, 240, 240, NOW()),
(2, 240, 240, NOW()),
(3, 120, 120, NOW()),
(4, 300, 300, NOW()),
(5, 250, 250, NOW()),
(6, 240, 240, NOW()),
(7, 60, 60, NOW()),
(8, 60, 60, NOW()),
(9, 36, 36, NOW()),
(10, 60, 60, NOW()),
(11, 36, 36, NOW()),
(12, 72, 72, NOW()),
(13, 120, 120, NOW()),
(14, 120, 120, NOW()),
(15, 80, 80, NOW()),
(16, 60, 60, NOW());

-- 9. Seed stock-ins
INSERT INTO stock_ins (stock_in_number, purchase_request_number, supplier_number, created_by, stock_in_date, status) VALUES
(1, NULL, 1, (SELECT user_id FROM profiles LIMIT 1), NOW() - INTERVAL '5 days', 'APPROVED'::request_status),
(2, NULL, 3, (SELECT user_id FROM profiles LIMIT 1), NOW() - INTERVAL '3 days', 'APPROVED'::request_status),
(3, NULL, 6, (SELECT user_id FROM profiles LIMIT 1), NOW() - INTERVAL '1 day', 'APPROVED'::request_status);

-- 10. Seed stock-in details
INSERT INTO stock_in_details (stock_in_detail_number, stock_in_number, product_number, batch_number, quantity, remaining_quantity, import_price, expiry_date, manufacturing_date) VALUES
(1, 1, 1, 'BATCH-LAVIE-01', 240, 240, 4000, CURRENT_DATE + INTERVAL '365 days', CURRENT_DATE - INTERVAL '10 days'),
(2, 2, 6, 'BATCH-VINAMILK-01', 240, 240, 6000, CURRENT_DATE + INTERVAL '30 days', CURRENT_DATE - INTERVAL '5 days'),
(3, 3, 9, 'BATCH-OMO-01', 36, 36, 95000, CURRENT_DATE + INTERVAL '720 days', CURRENT_DATE - INTERVAL '30 days'),
(4, 1, 2, 'BATCH-COCA-01', 240, 240, 7000, CURRENT_DATE + INTERVAL '180 days', CURRENT_DATE - INTERVAL '10 days');

-- 11. Seed inventory transactions
INSERT INTO inventory_transactions (transaction_number, product_number, stock_in_detail_number, type, quantity, reference_type, reference_id, created_by, created_at) VALUES
(1, 1, 1, 'IN'::transaction_type, 240, 'STOCK_IN', 1, (SELECT user_id FROM profiles LIMIT 1), NOW() - INTERVAL '5 days'),
(2, 6, 2, 'IN'::transaction_type, 240, 'STOCK_IN', 2, (SELECT user_id FROM profiles LIMIT 1), NOW() - INTERVAL '3 days'),
(3, 9, 3, 'IN'::transaction_type, 36, 'STOCK_IN', 3, (SELECT user_id FROM profiles LIMIT 1), NOW() - INTERVAL '1 day'),
(4, 2, 4, 'IN'::transaction_type, 240, 'STOCK_IN', 1, (SELECT user_id FROM profiles LIMIT 1), NOW() - INTERVAL '5 days');

-- 12. Seed promotions
INSERT INTO promotions (promotion_number, promotion_name, discount_value, status, start_date, end_date) VALUES
(1, 'Summer Beverage Sale', 10, 'ACTIVE'::promotion_status, CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE + INTERVAL '30 days'),
(2, 'Dairy Weekend Deal', 8, 'ACTIVE'::promotion_status, CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE + INTERVAL '5 days'),
(3, 'Household Cleaning Discount', 12, 'ACTIVE'::promotion_status, CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE + INTERVAL '15 days');

-- 13. Seed promotion products
INSERT INTO promotion_products (promotion_product_number, promotion_number, product_number, status, stock_in_detail_number) VALUES
(1, 1, 1, 'ACTIVE', 1),
(2, 1, 2, 'ACTIVE', 4),
(3, 2, 6, 'ACTIVE', 2),
(4, 3, 9, 'ACTIVE', 3);

-- 14. Seed product reports
INSERT INTO product_reports (report_number, reported_by, product_number, stock_in_detail_number, report_type, issue_type, quantity, description, status, created_at) VALUES
(1, (SELECT user_id FROM profiles LIMIT 1), 9, 3, 'LOW_STOCK'::report_type, 'LOW_STOCK'::report_issue_type, 10, 'OMO laundry detergent level is near reorder threshold.', 'PENDING'::request_status, NOW()),
(2, (SELECT user_id FROM profiles LIMIT 1), 6, 2, 'NEAR_EXPIRY'::report_type, 'EXPIRED'::report_issue_type, 50, 'Vinamilk Milk is near expiry date.', 'PENDING'::request_status, NOW()),
(3, (SELECT user_id FROM profiles LIMIT 1), 2, 4, 'DAMAGED'::report_type, 'DAMAGED'::report_issue_type, 5, 'Coca-Cola cans crushed during unloading.', 'APPROVED'::request_status, NOW());
