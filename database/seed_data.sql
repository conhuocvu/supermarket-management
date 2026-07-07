-- Seed products (if empty)
INSERT INTO products (product_name, barcode, selling_price, reorder_level, status, description) 
VALUES 
('Fresh Whole Milk', '8930000000001', 35000, 20, 'ACTIVE', 'Fresh whole milk, pasteurized'),
('Sliced Wheat Bread', '8930000000002', 25000, 15, 'ACTIVE', 'Sliced whole wheat sandwich bread'),
('Honey Crunch Cereal', '8930000000003', 65000, 10, 'ACTIVE', 'Honey roasted oats and flakes cereal'),
('Organic Apple Juice', '8930000000004', 45000, 30, 'ACTIVE', '100% natural organic apple juice'),
('Green Tea Pack', '8930000000005', 55000, 25, 'ACTIVE', 'Organic premium green tea bags');

-- Seed inventories (matching product_number generated keys 1, 2, 3, 4, 5)
INSERT INTO inventories (product_number, total_quantity, available_quantity, last_updated) 
VALUES 
(1, 50, 50, NOW()),
(2, 12, 12, NOW()),
(3, 100, 100, NOW()),
(4, 8, 8, NOW()),
(5, 60, 60, NOW());

-- Seed stock_in_details
INSERT INTO stock_in_details (product_number, batch_number, quantity, remaining_quantity, import_price, expiry_date, manufacturing_date) 
VALUES 
(1, 'BATCH-001', 100, 50, 25000, CURRENT_DATE + 10, CURRENT_DATE - 20),
(3, 'BATCH-002', 200, 100, 45000, CURRENT_DATE + 180, CURRENT_DATE - 10),
(2, 'BATCH-003', 50, 12, 18000, CURRENT_DATE - 5, CURRENT_DATE - 35);

-- Seed purchase requests (casting status to request_status enum)
INSERT INTO purchase_requests (status, created_date) 
VALUES 
(CAST('PENDING' AS request_status), NOW() - INTERVAL '1 DAY'),
(CAST('PENDING' AS request_status), NOW() - INTERVAL '2 HOUR'),
(CAST('PENDING' AS request_status), NOW()),
(CAST('APPROVED' AS request_status), NOW() - INTERVAL '5 DAY');

-- Seed inventory transactions (casting type to transaction_type enum)
INSERT INTO inventory_transactions (product_number, type, quantity, created_at) 
VALUES 
(1, CAST('IN' AS transaction_type), 50, NOW() - INTERVAL '10 MINUTE'),
(2, CAST('OUT' AS transaction_type), 10, NOW() - INTERVAL '2 HOUR'),
(3, CAST('IN' AS transaction_type), 100, NOW() - INTERVAL '1 DAY'),
(4, CAST('OUT' AS transaction_type), 24, NOW() - INTERVAL '1 DAY');
