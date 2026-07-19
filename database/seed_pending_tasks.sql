-- Seed pending tasks data for testing
DO $$
DECLARE
    v_user_id UUID;
BEGIN
    SELECT user_id INTO v_user_id FROM profiles LIMIT 1;
    
    IF v_user_id IS NULL THEN
        -- Fallback to a random UUID if profiles is empty (should not happen if seed_data.sql ran)
        v_user_id := 'e3b3ec4a-da0b-40f5-9747-29361993892b';
    END IF;

    -- 1. Insert Purchase Requests for Pending Stock-In
    -- PR 2: APPROVED
    INSERT INTO purchase_requests (purchase_request_number, created_by, approved_by, status, created_date, approved_date)
    VALUES (2, v_user_id, v_user_id, 'APPROVED', NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day')
    ON CONFLICT (purchase_request_number) DO UPDATE 
    SET status = 'APPROVED', approved_date = NOW() - INTERVAL '1 day';

    -- PR 3: PARTIALLY_RECEIVED
    INSERT INTO purchase_requests (purchase_request_number, created_by, approved_by, status, created_date, approved_date)
    VALUES (3, v_user_id, v_user_id, 'PARTIALLY_RECEIVED', NOW() - INTERVAL '3 days', NOW() - INTERVAL '2 days')
    ON CONFLICT (purchase_request_number) DO UPDATE 
    SET status = 'PARTIALLY_RECEIVED', approved_date = NOW() - INTERVAL '2 days';

    -- 2. Insert Purchase Request Details
    -- Details for PR 2: 45 Boxes/Units
    INSERT INTO purchase_request_details (purchase_request_detail_number, purchase_request_number, product_supplier_number, requested_quantity)
    VALUES (10, 2, 12, 45)
    ON CONFLICT (purchase_request_detail_number) DO UPDATE SET requested_quantity = 45;

    -- Details for PR 3: 120 Units
    INSERT INTO purchase_request_details (purchase_request_detail_number, purchase_request_number, product_supplier_number, requested_quantity)
    VALUES (11, 3, 2, 120)
    ON CONFLICT (purchase_request_detail_number) DO UPDATE SET requested_quantity = 120;

    -- 3. Add a Pending Stock-Out Report if it doesn't exist
    -- Report 4: Expiry Write-Off (APPROVED but no Stock-Out created yet)
    INSERT INTO product_reports (report_number, reported_by, product_number, stock_in_detail_number, report_type, issue_type, quantity, description, status, created_at)
    VALUES (4, v_user_id, 6, 2, 'NEAR_EXPIRY'::report_type, 'EXPIRED'::report_issue_type, 50, 'Vinamilk Milk is expired.', 'APPROVED'::request_status, NOW() - INTERVAL '1 day')
    ON CONFLICT (report_number) DO UPDATE SET status = 'APPROVED'::request_status;

    -- 4. Reset sequences to prevent duplicate key errors
    PERFORM setval('roles_role_number_seq', COALESCE((SELECT MAX(role_number) FROM roles), 1));
    PERFORM setval('categories_category_number_seq', COALESCE((SELECT MAX(category_number) FROM categories), 1));
    PERFORM setval('units_unit_number_seq', COALESCE((SELECT MAX(unit_number) FROM units), 1));
    PERFORM setval('suppliers_supplier_number_seq', COALESCE((SELECT MAX(supplier_number) FROM suppliers), 1));
    PERFORM setval('products_product_number_seq', COALESCE((SELECT MAX(product_number) FROM products), 1));
    PERFORM setval('product_suppliers_product_supplier_number_seq', COALESCE((SELECT MAX(product_supplier_number) FROM product_suppliers), 1));
    PERFORM setval('stock_ins_stock_in_number_seq', COALESCE((SELECT MAX(stock_in_number) FROM stock_ins), 1));
    PERFORM setval('stock_in_details_stock_in_detail_number_seq', COALESCE((SELECT MAX(stock_in_detail_number) FROM stock_in_details), 1));
    PERFORM setval('inventory_transactions_transaction_number_seq', COALESCE((SELECT MAX(transaction_number) FROM inventory_transactions), 1));
    PERFORM setval('promotions_promotion_number_seq', COALESCE((SELECT MAX(promotion_number) FROM promotions), 1));
    PERFORM setval('promotion_products_promotion_product_number_seq', COALESCE((SELECT MAX(promotion_product_number) FROM promotion_products), 1));
    PERFORM setval('product_reports_report_number_seq', COALESCE((SELECT MAX(report_number) FROM product_reports), 1));
    PERFORM setval('purchase_requests_purchase_request_number_seq', COALESCE((SELECT MAX(purchase_request_number) FROM purchase_requests), 1));
    PERFORM setval('purchase_request_details_purchase_request_detail_number_seq', COALESCE((SELECT MAX(purchase_request_detail_number) FROM purchase_request_details), 1));

END $$;
