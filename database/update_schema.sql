-- 1. Add expiry_warning_days to products table
ALTER TABLE products
ADD COLUMN IF NOT EXISTS expiry_warning_days INT DEFAULT 30;

-- 2. Seed categories table
INSERT INTO
    categories (
        category_number,
        category_name,
        status
    )
VALUES (1, 'Dairy', 'ACTIVE'),
    (2, 'Bakery', 'ACTIVE'),
    (3, 'Cereal', 'ACTIVE'),
    (4, 'Beverages', 'ACTIVE') ON CONFLICT (category_number) DO NOTHING;

-- 3. Seed units table
INSERT INTO
    units (unit_number, unit_name)
VALUES (1, 'Box'),
    (2, 'Bottle'),
    (3, 'Bag'),
    (4, 'Loaf'),
    (5, 'Carton') ON CONFLICT (unit_number) DO NOTHING;

-- 4. Update products with category and unit references
UPDATE products
SET
    category_number = 1,
    inventory_unit_number = 5
WHERE
    product_number = 1;

UPDATE products
SET
    category_number = 2,
    inventory_unit_number = 4
WHERE
    product_number = 2;

UPDATE products
SET
    category_number = 3,
    inventory_unit_number = 1
WHERE
    product_number = 3;

UPDATE products
SET
    category_number = 4,
    inventory_unit_number = 2
WHERE
    product_number = 4;

UPDATE products
SET
    category_number = 4,
    inventory_unit_number = 1
WHERE
    product_number = 5;

-- 5. Seed suppliers table
INSERT INTO
    suppliers (
        supplier_number,
        supplier_name,
        phone,
        email,
        status
    )
VALUES (
        1,
        'Global Distribution Co.',
        '0123456789',
        'contact@globaldist.com',
        'ACTIVE'
    ) ON CONFLICT (supplier_number) DO NOTHING;

-- 6. Seed product_suppliers table
INSERT INTO
    product_suppliers (
        product_supplier_number,
        product_number,
        supplier_number,
        import_price,
        minimum_order_quantity
    )
VALUES (1, 1, 1, 25000, 10),
    (2, 2, 1, 18000, 5),
    (3, 3, 1, 45000, 10),
    (4, 4, 1, 30000, 15),
    (5, 5, 1, 38000, 8) ON CONFLICT (product_supplier_number) DO NOTHING;

-- 7. Add description to categories table
ALTER TABLE categories ADD COLUMN IF NOT EXISTS description TEXT;

-- 8. Add internal notes to categories table
ALTER TABLE categories ADD COLUMN IF NOT EXISTS internal_notes TEXT;

-- 9. Add columns to promotions table
ALTER TABLE promotions
ADD COLUMN IF NOT EXISTS promo_code VARCHAR(50);

ALTER TABLE promotions ADD COLUMN IF NOT EXISTS category VARCHAR(50);

ALTER TABLE promotions
ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT FALSE;

-- 10. Update seeded promotions with code, category, is_featured, and image URL
UPDATE promotions
SET
    promo_code = 'HARVEST20',
    category = 'SEASONAL SALE',
    is_featured = FALSE,
    image_url = 'https://images.unsplash.com/photo-1610348725531-843dff163e2c?w=400&q=80',
    description = 'Fresh Harvest 20% Off'
WHERE
    promotion_number = 1;

UPDATE promotions
SET
    promo_code = 'BAKE50',
    category = 'FLASH DEAL',
    is_featured = FALSE,
    image_url = 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&q=80',
    description = 'Midnight Bakery Special'
WHERE
    promotion_number = 2;

UPDATE promotions SET promo_code = 'CLEANUP', category = 'HOME CARE', is_featured = FALSE, image_url = 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&q=80', description = 'Cleaning Essentials Pack', status = 'EXPIRED'::promotion_status WHERE promotion_number = 3;

-- 11. Add a few more promotions to match mockups
INSERT INTO promotions (promotion_number, promotion_name, discount_value, status, start_date, end_date, promo_code, category, is_featured, image_url, description)
VALUES 
(4, 'Buy 1 Get 1 Juice Blend', 12.5, 'ACTIVE'::promotion_status, CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE + INTERVAL '20 days', 'VIBE24', 'BOGO', FALSE, 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400&q=80', 'Buy 1 Get 1 Juice Blend')
ON CONFLICT (promotion_number) DO NOTHING;

INSERT INTO promotions (promotion_number, promotion_name, discount_value, status, start_date, end_date, promo_code, category, is_featured, image_url, description)
VALUES 
(5, 'Grand Opening Anniversary', 15.0, 'ACTIVE'::promotion_status, CURRENT_DATE - INTERVAL '5 days', CURRENT_DATE + INTERVAL '12 days', 'ANNIVERSARY5', 'STOREWIDE EVENT', TRUE, 'https://images.unsplash.com/photo-1534723452862-4c874018d66d?w=800&q=80', 'Special store-wide discounts across all departments to celebrate our 5th year in operation.')
ON CONFLICT (promotion_number) DO NOTHING;

-- 12. Add expected_delivery_date to purchase_requests table
ALTER TABLE purchase_requests
ADD COLUMN IF NOT EXISTS expected_delivery_date DATE;

-- 13. Add reason and notes to purchase_request_details table
ALTER TABLE purchase_request_details ADD COLUMN IF NOT EXISTS reason VARCHAR(255);
ALTER TABLE purchase_request_details ADD COLUMN IF NOT EXISTS notes TEXT;

-- 14. Add columns to suppliers table for contact person, address, category, and notes
ALTER TABLE suppliers ADD COLUMN IF NOT EXISTS contact_person VARCHAR(255);
ALTER TABLE suppliers ADD COLUMN IF NOT EXISTS address VARCHAR(255);
ALTER TABLE suppliers ADD COLUMN IF NOT EXISTS category VARCHAR(255);
ALTER TABLE suppliers ADD COLUMN IF NOT EXISTS notes TEXT;
