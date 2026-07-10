-- 1. Add expiry_warning_days to products table
ALTER TABLE products ADD COLUMN IF NOT EXISTS expiry_warning_days INT DEFAULT 30;

-- 2. Seed categories table
INSERT INTO categories (category_number, category_name, status)
VALUES 
(1, 'Dairy', 'ACTIVE'),
(2, 'Bakery', 'ACTIVE'),
(3, 'Cereal', 'ACTIVE'),
(4, 'Beverages', 'ACTIVE')
ON CONFLICT (category_number) DO NOTHING;

-- 3. Seed units table
INSERT INTO units (unit_number, unit_name)
VALUES
(1, 'Box'),
(2, 'Bottle'),
(3, 'Bag'),
(4, 'Loaf'),
(5, 'Carton')
ON CONFLICT (unit_number) DO NOTHING;

-- 4. Update products with category and unit references
UPDATE products SET category_number = 1, inventory_unit_number = 5 WHERE product_number = 1;
UPDATE products SET category_number = 2, inventory_unit_number = 4 WHERE product_number = 2;
UPDATE products SET category_number = 3, inventory_unit_number = 1 WHERE product_number = 3;
UPDATE products SET category_number = 4, inventory_unit_number = 2 WHERE product_number = 4;
UPDATE products SET category_number = 4, inventory_unit_number = 1 WHERE product_number = 5;

-- 5. Seed suppliers table
INSERT INTO suppliers (supplier_number, supplier_name, phone, email, status)
VALUES (1, 'Global Distribution Co.', '0123456789', 'contact@globaldist.com', 'ACTIVE')
ON CONFLICT (supplier_number) DO NOTHING;

-- 6. Seed product_suppliers table
INSERT INTO product_suppliers (product_supplier_number, product_number, supplier_number, import_price, minimum_order_quantity)
VALUES
(1, 1, 1, 25000, 10),
(2, 2, 1, 18000, 5),
(3, 3, 1, 45000, 10),
(4, 4, 1, 30000, 15),
(5, 5, 1, 38000, 8)
ON CONFLICT (product_supplier_number) DO NOTHING;

-- 7. Add description to categories table
ALTER TABLE categories ADD COLUMN IF NOT EXISTS description TEXT;

-- 8. Add internal notes to categories table
ALTER TABLE categories ADD COLUMN IF NOT EXISTS internal_notes TEXT;
