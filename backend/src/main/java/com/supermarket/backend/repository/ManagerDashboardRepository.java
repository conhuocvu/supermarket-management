package com.supermarket.backend.repository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Repository
@Transactional(readOnly = true)
public class ManagerDashboardRepository {

    @PersistenceContext
    private EntityManager entityManager;

    public long countStaff() {
        Query query = entityManager.createNativeQuery("SELECT COUNT(*) FROM profiles");
        return ((Number) query.getSingleResult()).longValue();
    }

    public long countCustomers() {
        Query query = entityManager.createNativeQuery("SELECT COUNT(*) FROM customers");
        return ((Number) query.getSingleResult()).longValue();
    }

    public long countSuppliers() {
        Query query = entityManager.createNativeQuery("SELECT COUNT(*) FROM suppliers");
        return ((Number) query.getSingleResult()).longValue();
    }

    public double sumTotalRevenue() {
        Query query = entityManager.createNativeQuery("SELECT COALESCE(SUM(final_amount), 0) FROM invoices WHERE status = 'COMPLETED'");
        return ((Number) query.getSingleResult()).doubleValue();
    }

    public double sumRevenueToday() {
        Query query = entityManager.createNativeQuery("SELECT COALESCE(SUM(final_amount), 0) FROM invoices WHERE status = 'COMPLETED' AND CAST(created_date AS DATE) = CURRENT_DATE");
        return ((Number) query.getSingleResult()).doubleValue();
    }

    public long countActiveOrdersToday() {
        Query query = entityManager.createNativeQuery("SELECT COUNT(*) FROM invoices WHERE CAST(created_date AS DATE) = CURRENT_DATE");
        return ((Number) query.getSingleResult()).longValue();
    }

    @SuppressWarnings("unchecked")
    public List<Object[]> getWeeklyRevenue(LocalDate startDate) {
        Query query = entityManager.createNativeQuery(
            "SELECT CAST(created_date AS DATE) as rev_date, COALESCE(SUM(final_amount), 0) as total " +
            "FROM invoices " +
            "WHERE status = 'COMPLETED' AND CAST(created_date AS DATE) >= :startDate " +
            "GROUP BY CAST(created_date AS DATE)"
        );
        query.setParameter("startDate", java.sql.Date.valueOf(startDate));
        return query.getResultList();
    }

    @SuppressWarnings("unchecked")
    public List<Object[]> getInventoryDistribution() {
        Query query = entityManager.createNativeQuery(
            "SELECT c.category_name, COALESCE(SUM(i.available_quantity), 0) as total_qty " +
            "FROM categories c " +
            "JOIN products p ON c.category_number = p.category_number " +
            "JOIN inventories i ON p.product_number = i.product_number " +
            "GROUP BY c.category_name " +
            "ORDER BY total_qty DESC"
        );
        return query.getResultList();
    }

    @SuppressWarnings("unchecked")
    public List<Object[]> findRecentPromotions() {
        Query query = entityManager.createNativeQuery(
            "SELECT promotion_name, discount_value, start_date FROM promotions ORDER BY start_date DESC LIMIT 5"
        );
        return query.getResultList();
    }

    @SuppressWarnings("unchecked")
    public List<Object[]> findRecentDeliveries() {
        Query query = entityManager.createNativeQuery(
            "SELECT s.supplier_name, si.stock_in_date FROM stock_ins si JOIN suppliers s ON si.supplier_number = s.supplier_number ORDER BY si.stock_in_date DESC LIMIT 5"
        );
        return query.getResultList();
    }

    @SuppressWarnings("unchecked")
    public List<Object[]> findRecentProfiles() {
        Query query = entityManager.createNativeQuery(
            "SELECT p.full_name, r.role_name, p.created_at " +
            "FROM profiles p " +
            "LEFT JOIN roles r ON p.role_number = r.role_number " +
            "ORDER BY p.created_at DESC LIMIT 5"
        );
        return query.getResultList();
    }

    @SuppressWarnings("unchecked")
    public List<Object[]> findRecentReports() {
        Query query = entityManager.createNativeQuery(
            "SELECT pr.description, pr.created_at FROM product_reports pr ORDER BY pr.created_at DESC LIMIT 5"
        );
        return query.getResultList();
    }
}
