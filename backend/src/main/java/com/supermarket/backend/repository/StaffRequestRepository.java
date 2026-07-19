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
                    approved_date
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
                    approvedDate);
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

        Long result = jdbcTemplate.queryForObject(
                sql,
                createFilterParameters(status, keyword),
                Long.class);

        return result == null ? 0L : result;
    }

    private String buildListUnion(String requestType, String status) {
        List<String> branches = new ArrayList<>();

        if ("ALL".equals(requestType) || "LEAVE".equals(requestType)) {
            branches.add(buildLeaveListQuery(status));
        }

        if ("ALL".equals(requestType) || "SHIFT_CHANGE".equals(requestType)) {
            branches.add(buildShiftChangeListQuery(status));
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
                    lr.approved_date
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
                    scr.approved_date
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

    private String statusCondition(String alias, String status) {
        if ("ALL".equals(status)) {
            return "";
        }

        return """
                AND %s.status = CAST(:status AS public.request_status)
                """.formatted(alias);
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
}
