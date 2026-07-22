package com.supermarket.backend.repository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Repository
@Transactional(readOnly = true)
public class StaffRepository {

    @PersistenceContext
    private EntityManager entityManager;

    public long countStaffList(String keyword, String statusFilter, Integer roleNumber, Integer shiftNumber) {
        String sql = """
                SELECT COUNT(*)
                FROM profiles p
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

        sql = applyFilters(sql, keyword, statusFilter, roleNumber, shiftNumber);

        Query query = entityManager.createNativeQuery(sql);
        setParameters(query, keyword, roleNumber, shiftNumber);
        return ((Number) query.getSingleResult()).longValue();
    }

    public long countOnShiftStaffList(String keyword, String statusFilter, Integer roleNumber, Integer shiftNumber) {
        if (statusFilter != null && (statusFilter.equalsIgnoreCase("OFF_DUTY") || statusFilter.equalsIgnoreCase("ON_LEAVE"))) {
            return 0;
        }

        String sql = """
                SELECT COUNT(*)
                FROM profiles p
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
                  AND lr.leave_number IS NULL
                  AND s.shift_number IS NOT NULL
                """;

        sql = applyFilters(sql, keyword, null, roleNumber, shiftNumber);

        Query query = entityManager.createNativeQuery(sql);
        setParameters(query, keyword, roleNumber, shiftNumber);
        return ((Number) query.getSingleResult()).longValue();
    }

    @SuppressWarnings("unchecked")
    public List<Object[]> getStaffList(String keyword, String statusFilter, Integer roleNumber, Integer shiftNumber, int limit, int offset) {
        String sql = """
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
                    lr.leave_number,
                    u.email
                FROM profiles p
                LEFT JOIN roles r ON p.role_number = r.role_number
                LEFT JOIN auth.users u ON p.user_id = u.id
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

        sql = applyFilters(sql, keyword, statusFilter, roleNumber, shiftNumber);
        sql += " ORDER BY p.full_name ASC LIMIT :limit OFFSET :offset";

        Query query = entityManager.createNativeQuery(sql);
        setParameters(query, keyword, roleNumber, shiftNumber);
        query.setParameter("limit", limit);
        query.setParameter("offset", offset);
        return query.getResultList();
    }

    private String applyFilters(String sql, String keyword, String statusFilter, Integer roleNumber, Integer shiftNumber) {
        if (keyword != null && !keyword.isBlank()) {
            sql += " AND (LOWER(p.full_name) LIKE :keyword OR p.phone LIKE :keyword)";
        }
        if (statusFilter != null && !statusFilter.isBlank() && !statusFilter.equalsIgnoreCase("ALL")) {
            if (statusFilter.equalsIgnoreCase("ON_LEAVE")) {
                sql += " AND lr.leave_number IS NOT NULL";
            } else if (statusFilter.equalsIgnoreCase("ON_DUTY")) {
                sql += " AND lr.leave_number IS NULL AND s.shift_number IS NOT NULL";
            } else if (statusFilter.equalsIgnoreCase("OFF_DUTY")) {
                sql += " AND lr.leave_number IS NULL AND s.shift_number IS NULL";
            } else if (statusFilter.equalsIgnoreCase("ACTIVE")) {
                sql += " AND p.status = 'ACTIVE'";
            } else if (statusFilter.equalsIgnoreCase("SUSPENDED")) {
                sql += " AND p.status = 'SUSPENDED'";
            } else if (statusFilter.equalsIgnoreCase("INACTIVE")) {
                sql += " AND p.status = 'INACTIVE'";
            }
        }
        if (roleNumber != null) {
            sql += " AND p.role_number = :roleNumber";
        }
        if (shiftNumber != null) {
            sql += " AND s.shift_number = :shiftNumber";
        }
        return sql;
    }

    private void setParameters(Query query, String keyword, Integer roleNumber, Integer shiftNumber) {
        if (keyword != null && !keyword.isBlank()) {
            query.setParameter("keyword", "%" + keyword.trim().toLowerCase() + "%");
        }
        if (roleNumber != null) {
            query.setParameter("roleNumber", roleNumber);
        }
        if (shiftNumber != null) {
            query.setParameter("shiftNumber", shiftNumber);
        }
    }

    @SuppressWarnings("unchecked")
    public List<Object[]> getStaffDetail(String userId) {
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
        return pq.getResultList();
    }

    @SuppressWarnings("unchecked")
    public List<Object[]> getWeeklySchedule(String userId) {
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
        return wq.getResultList();
    }

    public boolean existsRole(Integer roleNumber) {
        String roleCheckSql = "SELECT COUNT(*) FROM roles WHERE role_number = :roleNumber";
        Query rcq = entityManager.createNativeQuery(roleCheckSql);
        rcq.setParameter("roleNumber", roleNumber);
        long count = ((Number) rcq.getSingleResult()).longValue();
        return count > 0;
    }

    @Transactional
    public int updateStaffRole(String userId, Integer roleNumber) {
        String updateSql = "UPDATE profiles SET role_number = :roleNumber WHERE user_id = CAST(:userId AS uuid)";
        Query uq = entityManager.createNativeQuery(updateSql);
        uq.setParameter("roleNumber", roleNumber);
        uq.setParameter("userId", userId);
        return uq.executeUpdate();
    }

    @Transactional
    public void deleteWorkSchedule(String userId, String workDate) {
        String deleteSql = """
                DELETE FROM work_schedules
                WHERE user_id = CAST(:userId AS uuid) AND work_date = CAST(:workDate AS date)
                """;
        Query dq = entityManager.createNativeQuery(deleteSql);
        dq.setParameter("userId", userId);
        dq.setParameter("workDate", workDate);
        dq.executeUpdate();
    }

    @Transactional
    public void insertWorkSchedule(String userId, Integer shiftNumber, String workDate) {
        String insertSql = """
                INSERT INTO work_schedules (user_id, shift_number, work_date, status, assigned_date)
                VALUES (CAST(:userId AS uuid), :shiftNumber, CAST(:workDate AS date), 'ASSIGNED', NOW())
                """;
        Query iq = entityManager.createNativeQuery(insertSql);
        iq.setParameter("userId", userId);
        iq.setParameter("shiftNumber", shiftNumber);
        iq.setParameter("workDate", workDate);
        iq.executeUpdate();
    }

    @SuppressWarnings("unchecked")
    public List<Object[]> getRoles() {
        return entityManager.createNativeQuery(
                "SELECT role_number, role_name, description FROM roles ORDER BY role_number"
        ).getResultList();
    }

    @SuppressWarnings("unchecked")
    public List<Object[]> getShifts() {
        return entityManager.createNativeQuery(
                "SELECT DISTINCT shift_number, shift_name, CAST(start_time AS VARCHAR), CAST(end_time AS VARCHAR) FROM shifts WHERE shift_number IS NOT NULL ORDER BY shift_number"
        ).getResultList();
    }

    public String getUserRole(String userId) {
        try {
            String sql = """
                SELECT r.role_name
                FROM profiles p
                JOIN roles r ON p.role_number = r.role_number
                WHERE p.user_id = CAST(:userId AS uuid)
                """;
            Query query = entityManager.createNativeQuery(sql);
            query.setParameter("userId", userId);
            return (String) query.getSingleResult();
        } catch (Exception e) {
            return null;
        }
    }
}
