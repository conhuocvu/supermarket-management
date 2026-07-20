package com.supermarket.backend.repository;

import com.supermarket.backend.dto.StaffRequestDTO;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Repository
public class StaffRequestRepository {

    private final NamedParameterJdbcTemplate jdbcTemplate;

    public StaffRequestRepository(NamedParameterJdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public List<StaffRequestDTO> findStaffRequests(
            String requestType,
            String status,
            String keyword,
            int limit,
            int offset) {

        String sql = """
                SELECT
                    request_number,
                    request_type,
                    user_id,
                    employee_name,
                    reason,
                    start_date,
                    end_date,
                    status,
                    created_date,
                    approved_date,
                    product_name,
                    discount_percentage,
                    batch_number,
                    remaining_quantity,
                    selling_price,
                    import_price
                FROM (
                    %s
                ) staff_requests
                ORDER BY created_date DESC NULLS LAST, request_number DESC
                LIMIT :limit
                OFFSET :offset
                """.formatted(buildListUnion(requestType, status));

        MapSqlParameterSource parameters = createFilterParameters(status, keyword);
        parameters.addValue("limit", limit);
        parameters.addValue("offset", offset);

        return jdbcTemplate.query(sql, parameters, (resultSet, rowNumber) -> {
            LocalDate startDate = resultSet.getObject("start_date", LocalDate.class);
            LocalDate endDate = resultSet.getObject("end_date", LocalDate.class);
            LocalDateTime createdDate = resultSet.getObject("created_date", LocalDateTime.class);
            LocalDateTime approvedDate = resultSet.getObject("approved_date", LocalDateTime.class);

            java.math.BigDecimal remainingQty = resultSet.getBigDecimal("remaining_quantity");
            java.math.BigDecimal sellingPr = resultSet.getBigDecimal("selling_price");
            java.math.BigDecimal importPr = resultSet.getBigDecimal("import_price");
            Double discPercentage = resultSet.getObject("discount_percentage") != null ? resultSet.getDouble("discount_percentage") : null;

            return new StaffRequestDTO(
                    resultSet.getInt("request_number"),
                    resultSet.getString("request_type"),
                    resultSet.getObject("user_id", java.util.UUID.class),
                    resultSet.getString("employee_name"),
                    resultSet.getString("reason"),
                    startDate,
                    endDate,
                    resultSet.getString("status"),
                    createdDate,
                    approvedDate,
                    resultSet.getString("product_name"),
                    discPercentage,
                    resultSet.getString("batch_number"),
                    remainingQty,
                    sellingPr,
                    importPr);
        });
    }

    public long countStaffRequests(
            String requestType,
            String status,
            String keyword) {

        String sql = """
                SELECT COUNT(*)
                FROM (
                    %s
                ) staff_requests
                """.formatted(buildCountUnion(requestType, status));

        return jdbcTemplate.queryForObject(
                sql,
                createFilterParameters(status, keyword),
                Long.class);
    }


    public int updateRequestStatus(
            String requestType,
            int requestNumber,
            String status) {

        String sql;

        if ("LEAVE".equals(requestType)) {
            sql = """
                    UPDATE public.leave_requests
                    SET status = CAST(:status AS public.request_status),
                        approved_date = CASE
                            WHEN CAST(:status AS TEXT) = 'APPROVED' THEN CURRENT_TIMESTAMP
                            ELSE NULL
                        END
                    WHERE leave_number = :requestNumber
                      AND status = CAST('PENDING' AS public.request_status)
                    """;
        } else if ("SHIFT_CHANGE".equals(requestType)) {
            sql = """
                    UPDATE public.shift_change_requests
                    SET status = CAST(:status AS public.request_status),
                        approved_date = CASE
                            WHEN CAST(:status AS TEXT) = 'APPROVED' THEN CURRENT_TIMESTAMP
                            ELSE NULL
                        END
                    WHERE request_number = :requestNumber
                      AND status = CAST('PENDING' AS public.request_status)
                    """;
        } else if ("CLEARANCE".equals(requestType)) {
            throw new UnsupportedOperationException("Clearance request status updates are handled via JPA service.");
        } else {
            throw new IllegalArgumentException(
                    "Unsupported request type: " + requestType);
        }

        MapSqlParameterSource parameters = new MapSqlParameterSource()
                .addValue("requestNumber", requestNumber)
                .addValue("status", status);

        return jdbcTemplate.update(sql, parameters);
    }

    private String buildListUnion(String requestType, String status) {
        List<String> branches = new ArrayList<>();

        if ("ALL".equals(requestType) || "LEAVE".equals(requestType)) {
            branches.add(buildLeaveListQuery(status));
        }

        if ("ALL".equals(requestType) || "SHIFT_CHANGE".equals(requestType)) {
            branches.add(buildShiftChangeListQuery(status));
        }

        if ("ALL".equals(requestType) || "CLEARANCE".equals(requestType)) {
            branches.add(buildClearanceListQuery(status));
        }

        if ("ALL".equals(requestType) || "PURCHASE".equals(requestType)) {
            branches.add(buildPurchaseListQuery(status));
        }

        return String.join("\nUNION ALL\n", branches);
    }

    private String buildCountUnion(String requestType, String status) {
        List<String> branches = new ArrayList<>();

        if ("ALL".equals(requestType) || "LEAVE".equals(requestType)) {
            branches.add(buildLeaveCountQuery(status));
        }

        if ("ALL".equals(requestType) || "SHIFT_CHANGE".equals(requestType)) {
            branches.add(buildShiftChangeCountQuery(status));
        }

        if ("ALL".equals(requestType) || "CLEARANCE".equals(requestType)) {
            branches.add(buildClearanceCountQuery(status));
        }

        if ("ALL".equals(requestType) || "PURCHASE".equals(requestType)) {
            branches.add(buildPurchaseCountQuery(status));
        }

        return String.join("\nUNION ALL\n", branches);
    }

    private String buildLeaveListQuery(String status) {
        return """
                SELECT
                    lr.leave_number AS request_number,
                    'LEAVE' AS request_type,
                    lr.user_id,
                    COALESCE(p.full_name, 'Unknown Staff') AS employee_name,
                    lr.reason,
                    lr.start_date,
                    lr.end_date,
                    CAST(lr.status AS TEXT) AS status,
                    lr.created_date,
                    lr.approved_date,
                    NULL::TEXT AS product_name,
                    NULL::DOUBLE PRECISION AS discount_percentage,
                    NULL::TEXT AS batch_number,
                    NULL::NUMERIC AS remaining_quantity,
                    NULL::NUMERIC AS selling_price,
                    NULL::NUMERIC AS import_price
                FROM public.leave_requests lr
                LEFT JOIN public.profiles p
                    ON p.user_id = lr.user_id
                WHERE (
                    :keyword = ''
                    OR LOWER(COALESCE(p.full_name, 'Unknown Staff'))
                        LIKE LOWER(CONCAT('%%', :keyword, '%%'))
                )
                %s
                """.formatted(statusCondition("lr", status));
    }

    private String buildShiftChangeListQuery(String status) {
        return """
                SELECT
                    scr.request_number,
                    'SHIFT_CHANGE' AS request_type,
                    scr.user_id,
                    COALESCE(p.full_name, 'Unknown Staff') AS employee_name,
                    scr.reason,
                    NULL::DATE AS start_date,
                    NULL::DATE AS end_date,
                    CAST(scr.status AS TEXT) AS status,
                    scr.created_date,
                    scr.approved_date,
                    NULL::TEXT AS product_name,
                    NULL::DOUBLE PRECISION AS discount_percentage,
                    NULL::TEXT AS batch_number,
                    NULL::NUMERIC AS remaining_quantity,
                    NULL::NUMERIC AS selling_price,
                    NULL::NUMERIC AS import_price
                FROM public.shift_change_requests scr
                LEFT JOIN public.profiles p
                    ON p.user_id = scr.user_id
                WHERE (
                    :keyword = ''
                    OR LOWER(COALESCE(p.full_name, 'Unknown Staff'))
                        LIKE LOWER(CONCAT('%%', :keyword, '%%'))
                )
                %s
                """.formatted(statusCondition("scr", status));
    }

    private String buildClearanceListQuery(String status) {
        return """
                SELECT
                    p.promotion_number AS request_number,
                    'CLEARANCE' AS request_type,
                    pr.reported_by AS user_id,
                    COALESCE(prof.full_name, 'Unknown Staff') AS employee_name,
                    p.description AS reason,
                    p.start_date,
                    p.end_date,
                    CASE
                        WHEN p.status = 'PENDING' THEN 'PENDING'
                        WHEN p.status = 'ACTIVE' THEN 'APPROVED'
                        ELSE 'REJECTED'
                    END AS status,
                    p.start_date::timestamp AS created_date,
                    NULL::timestamp AS approved_date,
                    COALESCE(prod.product_name, pp.product) AS product_name,
                    p.discount_value AS discount_percentage,
                    sd.batch_number,
                    sd.remaining_quantity,
                    prod.selling_price,
                    sd.import_price
                FROM public.promotions p
                LEFT JOIN public.promotion_products pp
                    ON pp.promotion_number = p.promotion_number
                LEFT JOIN public.product_reports pr
                    ON pr.stock_in_detail_number = pp.stock_in_detail_number
                LEFT JOIN public.profiles prof
                    ON prof.user_id = pr.reported_by
                LEFT JOIN public.stock_in_details sd
                    ON sd.stock_in_detail_number = pp.stock_in_detail_number
                LEFT JOIN public.products prod
                    ON prod.product_number = pp.product_number
                WHERE p.category = 'CLEARANCE'
                  AND (
                    :keyword = ''
                    OR LOWER(COALESCE(prof.full_name, 'Unknown Staff'))
                        LIKE LOWER(CONCAT('%%', :keyword, '%%'))
                    OR LOWER(COALESCE(p.promotion_name, ''))
                        LIKE LOWER(CONCAT('%%', :keyword, '%%'))
                  )
                %s
                """.formatted(clearanceStatusCondition(status));
    }

    private String buildLeaveCountQuery(String status) {
        return """
                SELECT lr.leave_number AS request_number
                FROM public.leave_requests lr
                LEFT JOIN public.profiles p
                    ON p.user_id = lr.user_id
                WHERE (
                    :keyword = ''
                    OR LOWER(COALESCE(p.full_name, 'Unknown Staff'))
                        LIKE LOWER(CONCAT('%%', :keyword, '%%'))
                )
                %s
                """.formatted(statusCondition("lr", status));
    }

    private String buildShiftChangeCountQuery(String status) {
        return """
                SELECT scr.request_number
                FROM public.shift_change_requests scr
                LEFT JOIN public.profiles p
                    ON p.user_id = scr.user_id
                WHERE (
                    :keyword = ''
                    OR LOWER(COALESCE(p.full_name, 'Unknown Staff'))
                        LIKE LOWER(CONCAT('%%', :keyword, '%%'))
                )
                %s
                """.formatted(statusCondition("scr", status));
    }

    private String buildClearanceCountQuery(String status) {
        return """
                SELECT p.promotion_number AS request_number
                FROM public.promotions p
                LEFT JOIN public.promotion_products pp
                    ON pp.promotion_number = p.promotion_number
                LEFT JOIN public.product_reports pr
                    ON pr.stock_in_detail_number = pp.stock_in_detail_number
                LEFT JOIN public.profiles prof
                    ON prof.user_id = pr.reported_by
                WHERE p.category = 'CLEARANCE'
                  AND (
                    :keyword = ''
                    OR LOWER(COALESCE(prof.full_name, 'Unknown Staff'))
                        LIKE LOWER(CONCAT('%%', :keyword, '%%'))
                    OR LOWER(COALESCE(p.promotion_name, ''))
                        LIKE LOWER(CONCAT('%%', :keyword, '%%'))
                  )
                %s
                """.formatted(clearanceStatusCondition(status));
    }

    private String statusCondition(String alias, String status) {
        if ("ALL".equals(status)) {
            return "";
        }

        return """
                AND %s.status = CAST(:status AS public.request_status)
                """.formatted(alias);
    }

    private String clearanceStatusCondition(String status) {
        if ("ALL".equals(status)) {
            return "";
        }
        if ("PENDING".equals(status)) {
            return "AND p.status = 'PENDING'";
        }
        if ("APPROVED".equals(status)) {
            return "AND p.status = 'ACTIVE'";
        }
        if ("REJECTED".equals(status)) {
            return "AND p.status IN ('INACTIVE', 'EXPIRED')";
        }
        return "";
    }

    private MapSqlParameterSource createFilterParameters(
            String status,
            String keyword) {

        MapSqlParameterSource parameters = new MapSqlParameterSource()
                .addValue("keyword", keyword);

        if (!"ALL".equals(status)) {
            parameters.addValue("status", status);
        }

        return parameters;
    }

    private String buildPurchaseListQuery(String status) {
        return """
                SELECT
                    pr.purchase_request_number AS request_number,
                    'PURCHASE' AS request_type,
                    pr.created_by AS user_id,
                    COALESCE(p.full_name, 'Unknown Staff') AS employee_name,
                    'Purchase order: ' || COALESCE(MAX(s.supplier_name), 'Various') || ' (' || COUNT(prd.purchase_request_detail_number) || ' item(s))' AS reason,
                    NULL::DATE AS start_date,
                    NULL::DATE AS end_date,
                    CASE
                        WHEN pr.status = 'PENDING' THEN 'PENDING'
                        WHEN pr.status IN ('APPROVED', 'PARTIALLY_RECEIVED', 'COMPLETED') THEN 'APPROVED'
                        ELSE 'REJECTED'
                    END AS status,
                    pr.created_date,
                    pr.approved_date,
                    NULL::TEXT AS product_name,
                    NULL::DOUBLE PRECISION AS discount_percentage,
                    NULL::TEXT AS batch_number,
                    NULL::NUMERIC AS remaining_quantity,
                    NULL::NUMERIC AS selling_price,
                    NULL::NUMERIC AS import_price
                FROM public.purchase_requests pr
                LEFT JOIN public.profiles p
                    ON p.user_id = pr.created_by
                LEFT JOIN public.purchase_request_details prd
                    ON prd.purchase_request_number = pr.purchase_request_number
                LEFT JOIN public.product_suppliers ps
                    ON ps.product_supplier_number = prd.product_supplier_number
                LEFT JOIN public.suppliers s
                    ON s.supplier_number = ps.supplier_number
                WHERE pr.status != 'DRAFT'
                  AND (
                    :keyword = ''
                    OR LOWER(COALESCE(p.full_name, 'Unknown Staff'))
                        LIKE LOWER(CONCAT('%%', :keyword, '%%'))
                    OR LOWER(COALESCE(s.supplier_name, ''))
                        LIKE LOWER(CONCAT('%%', :keyword, '%%'))
                  )
                %s
                GROUP BY pr.purchase_request_number, pr.status, pr.created_date, pr.approved_date, pr.created_by, p.full_name
                """.formatted(purchaseStatusCondition(status));
    }

    private String buildPurchaseCountQuery(String status) {
        return """
                SELECT DISTINCT pr.purchase_request_number AS request_number
                FROM public.purchase_requests pr
                LEFT JOIN public.profiles p
                    ON p.user_id = pr.created_by
                LEFT JOIN public.purchase_request_details prd
                    ON prd.purchase_request_number = pr.purchase_request_number
                LEFT JOIN public.product_suppliers ps
                    ON ps.product_supplier_number = prd.product_supplier_number
                LEFT JOIN public.suppliers s
                    ON s.supplier_number = ps.supplier_number
                WHERE pr.status != 'DRAFT'
                  AND (
                    :keyword = ''
                    OR LOWER(COALESCE(p.full_name, 'Unknown Staff'))
                        LIKE LOWER(CONCAT('%%', :keyword, '%%'))
                    OR LOWER(COALESCE(s.supplier_name, ''))
                        LIKE LOWER(CONCAT('%%', :keyword, '%%'))
                  )
                %s
                """.formatted(purchaseStatusCondition(status));
    }

    private String purchaseStatusCondition(String status) {
        if ("ALL".equals(status)) {
            return "";
        }
        if ("PENDING".equals(status)) {
            return "AND pr.status = 'PENDING'";
        }
        if ("APPROVED".equals(status)) {
            return "AND pr.status IN ('APPROVED', 'PARTIALLY_RECEIVED', 'COMPLETED')";
        }
        if ("REJECTED".equals(status)) {
            return "AND pr.status = 'REJECTED'";
        }
        return "";
    }
}
