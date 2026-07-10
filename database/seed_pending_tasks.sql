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

END $$;
