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
ALTER TABLE promotions ADD COLUMN IF NOT EXISTS promo_code VARCHAR(50);
ALTER TABLE promotions ADD COLUMN IF NOT EXISTS category VARCHAR(50);
ALTER TABLE promotions ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT FALSE;

-- 10. Update seeded promotions with code, category, is_featured, and image URL
UPDATE promotions SET promo_code = 'HARVEST20', category = 'SEASONAL SALE', is_featured = FALSE, image_url = 'https://images.unsplash.com/photo-1610348725531-843dff163e2c?w=400&q=80', description = 'Fresh Harvest 20% Off' WHERE promotion_number = 1;
UPDATE promotions SET promo_code = 'BAKE50', category = 'FLASH DEAL', is_featured = FALSE, image_url = 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&q=80', description = 'Midnight Bakery Special' WHERE promotion_number = 2;
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
ALTER TABLE purchase_requests ADD COLUMN IF NOT EXISTS expected_delivery_date DATE;

-- 13. Add reason and notes to purchase_request_details table
ALTER TABLE purchase_request_details ADD COLUMN IF NOT EXISTS reason VARCHAR(255);
ALTER TABLE purchase_request_details ADD COLUMN IF NOT EXISTS notes TEXT;

-- 14. Create staff, scheduling, and invoicing schema tables if they do not exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'request_status') THEN
        CREATE TYPE request_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status') THEN
        CREATE TYPE payment_status AS ENUM ('PENDING', 'PAID', 'FAILED', 'REFUNDED');
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.leave_requests (
    leave_number SERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(user_id) ON DELETE CASCADE,
    reason VARCHAR(255),
    start_date DATE,
    end_date DATE,
    status request_status DEFAULT 'PENDING',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_date TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.shift_change_requests (
    request_number SERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(user_id) ON DELETE CASCADE,
    reason VARCHAR(255),
    status request_status DEFAULT 'PENDING',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_date TIMESTAMP,
    current_shift_date DATE,
    current_shift_type VARCHAR(50),
    current_shift_start TIME,
    current_shift_end TIME,
    target_shift_date DATE,
    target_shift_type VARCHAR(50),
    target_shift_start TIME,
    target_shift_end TIME
);

CREATE TABLE IF NOT EXISTS public.invoices (
    invoice_number SERIAL PRIMARY KEY,
    cashier_number UUID REFERENCES public.profiles(user_id) ON DELETE SET NULL,
    customer_number INT REFERENCES public.customers(customer_number) ON DELETE SET NULL,
    total_amount NUMERIC(12,2) DEFAULT 0,
    final_amount NUMERIC(12,2) DEFAULT 0,
    status VARCHAR(50) DEFAULT 'UNPAID',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.invoice_details (
    invoice_detail_number SERIAL PRIMARY KEY,
    invoice_number INT REFERENCES public.invoices(invoice_number) ON DELETE CASCADE,
    product_number INT REFERENCES public.products(product_number) ON DELETE RESTRICT,
    quantity NUMERIC(12,3) DEFAULT 0,
    unit_price_at_sale NUMERIC(12,2) DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.payments (
    payment_number SERIAL PRIMARY KEY,
    invoice_number INT REFERENCES public.invoices(invoice_number) ON DELETE CASCADE,
    payment_method VARCHAR(50) NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    status payment_status DEFAULT 'PAID',
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

