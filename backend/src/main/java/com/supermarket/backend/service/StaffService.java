package com.supermarket.backend.service;

import com.supermarket.backend.dto.*;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.TextStyle;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

@Service
@Transactional(readOnly = true)
public class StaffService {

    @PersistenceContext
    private EntityManager entityManager;

    /**
     * Fetch staff list, optionally filtered by keyword (full_name or phone)
     * and/or workStatus: ALL | ON_DUTY | OFF_DUTY | ON_LEAVE
     */
    public StaffSummaryDTO getStaffList(String keyword, String workStatus) {

        // -------------------------------------------------------
        // Build the base query joining profiles → roles
        // and LEFT JOINing work_schedules + shifts for today's shift
        // and LEFT JOINing leave_requests for active approved leaves
        // -------------------------------------------------------
        String baseSql = """
                SELECT
                    p.user_id,
                    p.full_name,
                    p.phone,
                    p.avatar_url,
                    p.status,
                    p.role_number,
                    r.role_name,
                    s.shift_name,
                    CAST(s.start_time AS VARCHAR),
                    CAST(s.end_time   AS VARCHAR),
                    lr.leave_number
                FROM profiles p
                LEFT JOIN roles r ON p.role_number = r.role_number
                LEFT JOIN work_schedules ws
                    ON ws.user_id = p.user_id
                    AND ws.work_date = CURRENT_DATE
                    AND ws.status = 'ASSIGNED'
                LEFT JOIN shifts s ON s.shift_number = ws.shift_number
                LEFT JOIN leave_requests lr
                    ON lr.user_id = p.user_id
                    AND lr.status = 'APPROVED'
                    AND CURRENT_DATE BETWEEN lr.start_date AND lr.end_date
                WHERE 1=1
                """;

        // Keyword filter
        boolean hasKeyword = keyword != null && !keyword.isBlank();
        if (hasKeyword) {
            baseSql += " AND (LOWER(p.full_name) LIKE :keyword OR p.phone LIKE :keyword)";
        }

        baseSql += " ORDER BY p.full_name ASC";

        Query query = entityManager.createNativeQuery(baseSql);
        if (hasKeyword) {
            query.setParameter("keyword", "%" + keyword.toLowerCase() + "%");
        }

        @SuppressWarnings("unchecked")
        List<Object[]> rows = query.getResultList();

        List<StaffListDTO> staffList = new ArrayList<>();
        long onShiftCount = 0;

        for (Object[] row : rows) {
            String userId     = row[0] != null ? row[0].toString() : null;
            String fullName   = (String) row[1];
            String phone      = row[2] != null ? (String) row[2] : "";
            String avatarUrl  = row[3] != null ? (String) row[3] : null;
            String status     = row[4] != null ? (String) row[4] : "ACTIVE";
            Integer roleNum   = row[5] != null ? ((Number) row[5]).intValue() : null;
            String roleName   = row[6] != null ? (String) row[6] : "Unknown";
            String shiftName  = row[7] != null ? (String) row[7] : null;
            String startTime  = row[8] != null ? (String) row[8] : null;
            String endTime    = row[9] != null ? (String) row[9] : null;
            boolean onLeave   = row[10] != null; // leave_number

            // Determine work status
            String computed;
            if (onLeave) {
                computed = "ON_LEAVE";
            } else if (shiftName != null) {
                computed = "ON_DUTY";
                onShiftCount++;
            } else {
                computed = "OFF_DUTY";
            }

            // Apply workStatus filter after computing
            if (workStatus != null && !workStatus.isBlank() && !workStatus.equalsIgnoreCase("ALL")) {
                if (!computed.equalsIgnoreCase(workStatus)) {
                    continue;
                }
            }

            staffList.add(StaffListDTO.builder()
                    .userId(userId)
                    .fullName(fullName)
                    .phone(phone)
                    .avatarUrl(avatarUrl)
                    .status(status)
                    .roleNumber(roleNum)
                    .roleName(roleName)
                    .workStatus(computed)
                    .shiftName(shiftName)
                    .shiftStartTime(startTime)
                    .shiftEndTime(endTime)
                    .build());
        }

        // Total staff without filter (for summary cards)
        long totalStaff = rows.size();

        return StaffSummaryDTO.builder()
                .totalStaff(totalStaff)
                .onShiftCount(onShiftCount)
                .staff(staffList)
                .build();
    }

    /**
     * UC-ST-02: Get detailed information of a single staff member.
     */
    public StaffDetailDTO getStaffDetail(String userId) {

        // 1. Fetch profile + role + today's shift
        String profileSql = """
                SELECT
                    p.user_id, p.full_name, p.phone, p.avatar_url, p.address,
                    p.status, CAST(p.created_at AS VARCHAR),
                    p.role_number, r.role_name,
                    s.shift_name,
                    CAST(s.start_time AS VARCHAR), CAST(s.end_time AS VARCHAR),
                    lr.leave_number
                FROM profiles p
                LEFT JOIN roles r ON p.role_number = r.role_number
                LEFT JOIN work_schedules ws
                    ON ws.user_id = p.user_id
                    AND ws.work_date = CURRENT_DATE
                    AND ws.status = 'ASSIGNED'
                LEFT JOIN shifts s ON s.shift_number = ws.shift_number
                LEFT JOIN leave_requests lr
                    ON lr.user_id = p.user_id
                    AND lr.status = 'APPROVED'
                    AND CURRENT_DATE BETWEEN lr.start_date AND lr.end_date
                WHERE p.user_id = CAST(:userId AS uuid)
                """;

        Query pq = entityManager.createNativeQuery(profileSql);
        pq.setParameter("userId", userId);

        @SuppressWarnings("unchecked")
        List<Object[]> pRows = pq.getResultList();
        if (pRows.isEmpty()) {
            throw new RuntimeException("Staff record not found.");
        }

        Object[] pr = pRows.get(0);
        String shiftName  = pr[9] != null ? (String) pr[9] : null;
        boolean onLeave   = pr[12] != null;
        String computed;
        if (onLeave)          computed = "ON_LEAVE";
        else if (shiftName != null) computed = "ON_DUTY";
        else                  computed = "OFF_DUTY";

        // 2. Fetch this week's schedule (Mon-Sun)
        String weekSql = """
                SELECT
                    ws.work_date,
                    ws.shift_number,
                    s.shift_name,
                    CAST(s.start_time AS VARCHAR),
                    CAST(s.end_time   AS VARCHAR)
                FROM work_schedules ws
                LEFT JOIN shifts s ON s.shift_number = ws.shift_number
                WHERE ws.user_id = CAST(:userId AS uuid)
                  AND ws.work_date >= CURRENT_DATE
                  AND ws.work_date < CURRENT_DATE + INTERVAL '7 days'
                  AND ws.status = 'ASSIGNED'
                ORDER BY ws.work_date
                """;

        Query wq = entityManager.createNativeQuery(weekSql);
        wq.setParameter("userId", userId);

        @SuppressWarnings("unchecked")
        List<Object[]> wRows = wq.getResultList();
        DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy-MM-dd");

        List<StaffDetailDTO.WeeklyShiftDTO> weekly = new ArrayList<>();
        for (Object[] wr : wRows) {
            Object dateObj = wr[0];
            LocalDate date;
            if (dateObj instanceof java.sql.Date) {
                date = ((java.sql.Date) dateObj).toLocalDate();
            } else if (dateObj instanceof java.time.LocalDate) {
                date = (java.time.LocalDate) dateObj;
            } else {
                date = LocalDate.parse(dateObj.toString());
            }
            weekly.add(StaffDetailDTO.WeeklyShiftDTO.builder()
                    .workDate(date.format(dtf))
                    .dayOfWeek(date.getDayOfWeek().getDisplayName(TextStyle.FULL, Locale.ENGLISH))
                    .shiftNumber(wr[1] != null ? ((Number) wr[1]).intValue() : null)
                    .shiftName(wr[2] != null ? (String) wr[2] : null)
                    .shiftStartTime(wr[3] != null ? (String) wr[3] : null)
                    .shiftEndTime(wr[4] != null ? (String) wr[4] : null)
                    .build());
        }

        return StaffDetailDTO.builder()
                .userId(pr[0] != null ? pr[0].toString() : null)
                .fullName((String) pr[1])
                .phone(pr[2] != null ? (String) pr[2] : "")
                .avatarUrl(pr[3] != null ? (String) pr[3] : null)
                .address(pr[4] != null ? (String) pr[4] : null)
                .status(pr[5] != null ? (String) pr[5] : "ACTIVE")
                .createdAt(pr[6] != null ? (String) pr[6] : null)
                .roleNumber(pr[7] != null ? ((Number) pr[7]).intValue() : null)
                .roleName(pr[8] != null ? (String) pr[8] : "Unknown")
                .workStatus(computed)
                .shiftName(shiftName)
                .shiftStartTime(pr[10] != null ? (String) pr[10] : null)
                .shiftEndTime(pr[11] != null ? (String) pr[11] : null)
                .weeklySchedule(weekly)
                .build();
    }

    /**
     * UC-ST-03: Update a staff member's role.
     * Only Managers can set staff roles (BR-ST-05).
     */
    @Transactional
    public void setStaffRole(String userId, Integer roleNumber) {
        // Validate role exists
        String roleCheckSql = "SELECT COUNT(*) FROM roles WHERE role_number = :roleNumber";
        Query rcq = entityManager.createNativeQuery(roleCheckSql);
        rcq.setParameter("roleNumber", roleNumber);
        long count = ((Number) rcq.getSingleResult()).longValue();
        if (count == 0) {
            throw new RuntimeException("Role not found.");
        }

        String updateSql = "UPDATE profiles SET role_number = :roleNumber WHERE user_id = CAST(:userId AS uuid)";
        Query uq = entityManager.createNativeQuery(updateSql);
        uq.setParameter("roleNumber", roleNumber);
        uq.setParameter("userId", userId);
        int updated = uq.executeUpdate();
        if (updated == 0) {
            throw new RuntimeException("Staff record not found.");
        }
    }

    /**
     * UC-ST-04: Assign weekly shifts for a staff member.
     * Each staff member can have only one working shift or day off per day (BR-ST-09).
     */
    @Transactional
    public void assignShifts(String userId, AssignShiftsRequestDTO request) {
        if (request.getSchedule() == null || request.getSchedule().isEmpty()) {
            throw new RuntimeException("No schedule provided.");
        }

        for (AssignShiftsRequestDTO.DayShiftDTO day : request.getSchedule()) {
            if (day.getWorkDate() == null) continue;

            // Delete any existing assignment for this date
            String deleteSql = """
                    DELETE FROM work_schedules
                    WHERE user_id = CAST(:userId AS uuid) AND work_date = CAST(:workDate AS date)
                    """;
            Query dq = entityManager.createNativeQuery(deleteSql);
            dq.setParameter("userId", userId);
            dq.setParameter("workDate", day.getWorkDate());
            dq.executeUpdate();

            // If shiftNumber is provided (not day off), insert new assignment
            if (day.getShiftNumber() != null) {
                String insertSql = """
                        INSERT INTO work_schedules (user_id, shift_number, work_date, status, assigned_date)
                        VALUES (CAST(:userId AS uuid), :shiftNumber, CAST(:workDate AS date), 'ASSIGNED', NOW())
                        """;
                Query iq = entityManager.createNativeQuery(insertSql);
                iq.setParameter("userId", userId);
                iq.setParameter("shiftNumber", day.getShiftNumber());
                iq.setParameter("workDate", day.getWorkDate());
                iq.executeUpdate();
            }
        }
    }

    /**
     * Get all available roles.
     */
    public List<Object[]> getRoles() {
        @SuppressWarnings("unchecked")
        List<Object[]> rows = entityManager.createNativeQuery(
                "SELECT role_number, role_name, description FROM roles ORDER BY role_number"
        ).getResultList();
        return rows;
    }

    /**
     * Get all available shifts.
     */
    public List<Object[]> getShifts() {
        @SuppressWarnings("unchecked")
        List<Object[]> rows = entityManager.createNativeQuery(
                "SELECT DISTINCT shift_number, shift_name, CAST(start_time AS VARCHAR), CAST(end_time AS VARCHAR) FROM shifts WHERE shift_number IS NOT NULL ORDER BY shift_number"
        ).getResultList();
        return rows;
    }
}
