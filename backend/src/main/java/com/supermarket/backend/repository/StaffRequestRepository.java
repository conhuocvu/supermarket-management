package com.supermarket.backend.repository;

import com.supermarket.backend.dto.StaffRequestDTO;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Reads leave requests and shift change requests from PostgreSQL,
 * then converts both request types into one unified staff request list.
 *
 * This repository is read-only.
 */
@Repository
public class StaffRequestRepository {

    private final NamedParameterJdbcTemplate jdbcTemplate;

    public StaffRequestRepository(NamedParameterJdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    /**
     * Gets a filtered and paginated list of staff requests.
     */
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

                    UNION ALL

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
                ) staff_requests
                WHERE (:requestType = 'ALL' OR request_type = :requestType)
                  AND (:status = 'ALL' OR UPPER(status) = :status)
                  AND (
                        :keyword = ''
                        OR LOWER(employee_name) LIKE LOWER(CONCAT('%', :keyword, '%'))
                      )
                ORDER BY created_date DESC NULLS LAST, request_number DESC
                LIMIT :limit
                OFFSET :offset
                """;

        MapSqlParameterSource parameters = createFilterParameters(
                requestType,
                status,
                keyword);

        parameters.addValue("limit", limit);
        parameters.addValue("offset", offset);

        return jdbcTemplate.query(sql, parameters, (resultSet, rowNumber) -> {
            LocalDate startDate = resultSet.getObject(
                    "start_date",
                    LocalDate.class);

            LocalDate endDate = resultSet.getObject(
                    "end_date",
                    LocalDate.class);

            LocalDateTime createdDate = resultSet.getObject(
                    "created_date",
                    LocalDateTime.class);

            LocalDateTime approvedDate = resultSet.getObject(
                    "approved_date",
                    LocalDateTime.class);

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

    /**
     * Counts all requests matching the current filters.
     * Flutter uses this value to calculate pagination.
     */
    public long countStaffRequests(
            String requestType,
            String status,
            String keyword) {

        String sql = """
                SELECT COUNT(*)
                FROM (
                    SELECT
                        'LEAVE' AS request_type,
                        lr.user_id,
                        COALESCE(p.full_name, 'Unknown Staff') AS employee_name,
                        CAST(lr.status AS TEXT) AS status
                    FROM public.leave_requests lr
                    LEFT JOIN public.profiles p
                        ON p.user_id = lr.user_id

                    UNION ALL

                    SELECT
                        'SHIFT_CHANGE' AS request_type,
                        scr.user_id,
                        COALESCE(p.full_name, 'Unknown Staff') AS employee_name,
                        CAST(scr.status AS TEXT) AS status
                    FROM public.shift_change_requests scr
                    LEFT JOIN public.profiles p
                        ON p.user_id = scr.user_id
                ) staff_requests
                WHERE (:requestType = 'ALL' OR request_type = :requestType)
                  AND (:status = 'ALL' OR UPPER(status) = :status)
                  AND (
                        :keyword = ''
                        OR LOWER(employee_name) LIKE LOWER(CONCAT('%', :keyword, '%'))
                      )
                """;

        MapSqlParameterSource parameters = createFilterParameters(
                requestType,
                status,
                keyword);

        Long result = jdbcTemplate.queryForObject(
                sql,
                parameters,
                Long.class);

        return result == null ? 0L : result;
    }

    private MapSqlParameterSource createFilterParameters(
            String requestType,
            String status,
            String keyword) {

        return new MapSqlParameterSource()
                .addValue("requestType", requestType)
                .addValue("status", status)
                .addValue("keyword", keyword);
    }
}