package com.supermarket.backend.service;

import com.supermarket.backend.dto.ManagerDashboardDataDTO;
import com.supermarket.backend.dto.RecentActivityDTO;
import com.supermarket.backend.repository.InventoryRepository;
import com.supermarket.backend.repository.ProductRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.TextStyle;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ManagerDashboardService {

    @PersistenceContext
    private EntityManager entityManager;

    private final ProductRepository productRepository;
    private final InventoryRepository inventoryRepository;

    public ManagerDashboardDataDTO getManagerDashboardData() {
        long totalProducts = productRepository.count();
        long lowStockCount = inventoryRepository.countLowStock();

        // 1. Total Staff
        Query staffCountQuery = entityManager.createNativeQuery("SELECT COUNT(*) FROM profiles");
        long totalStaff = ((Number) staffCountQuery.getSingleResult()).longValue();

        // 2. Total Customers
        Query customerCountQuery = entityManager.createNativeQuery("SELECT COUNT(*) FROM customers");
        long totalCustomers = ((Number) customerCountQuery.getSingleResult()).longValue();

        // 3. Total Suppliers
        Query supplierCountQuery = entityManager.createNativeQuery("SELECT COUNT(*) FROM suppliers");
        long totalSuppliers = ((Number) supplierCountQuery.getSingleResult()).longValue();

        // 4. Total Revenue
        Query totalRevenueQuery = entityManager.createNativeQuery("SELECT COALESCE(SUM(final_amount), 0) FROM invoices WHERE status = 'COMPLETED'");
        double totalRevenue = ((Number) totalRevenueQuery.getSingleResult()).doubleValue();

        // 5. Revenue Today
        Query revenueTodayQuery = entityManager.createNativeQuery("SELECT COALESCE(SUM(final_amount), 0) FROM invoices WHERE status = 'COMPLETED' AND CAST(created_date AS DATE) = CURRENT_DATE");
        double revenueToday = ((Number) revenueTodayQuery.getSingleResult()).doubleValue();

        // 6. Active Orders Today (Completed or Pending Invoices today)
        Query activeOrdersQuery = entityManager.createNativeQuery("SELECT COUNT(*) FROM invoices WHERE CAST(created_date AS DATE) = CURRENT_DATE");
        long activeOrdersCount = ((Number) activeOrdersQuery.getSingleResult()).longValue();

        // 7. Stock Level Percentage
        double stockLevel = 100.0;
        if (totalProducts > 0) {
            stockLevel = ((double) (totalProducts - lowStockCount) / totalProducts) * 100.0;
            stockLevel = BigDecimal.valueOf(stockLevel).setScale(1, RoundingMode.HALF_UP).doubleValue();
        }

        // 8. Weekly Revenue
        List<ManagerDashboardDataDTO.WeeklyRevenueDTO> weeklyRevenueList = new ArrayList<>();
        LocalDate today = LocalDate.now();
        for (int i = 6; i >= 0; i--) {
            LocalDate date = today.minusDays(i);
            String dayName = date.getDayOfWeek().getDisplayName(TextStyle.SHORT, Locale.ENGLISH);
            Query query = entityManager.createNativeQuery(
                "SELECT COALESCE(SUM(final_amount), 0) FROM invoices WHERE status = 'COMPLETED' AND CAST(created_date AS DATE) = :date"
            );
            query.setParameter("date", java.sql.Date.valueOf(date));
            double amount = ((Number) query.getSingleResult()).doubleValue();
            weeklyRevenueList.add(new ManagerDashboardDataDTO.WeeklyRevenueDTO(dayName, amount));
        }

        // 9. Inventory Distribution
        Query distQuery = entityManager.createNativeQuery(
            "SELECT c.category_name, COALESCE(SUM(i.available_quantity), 0) as total_qty " +
            "FROM categories c " +
            "JOIN products p ON c.category_number = p.category_number " +
            "JOIN inventories i ON p.product_number = i.product_number " +
            "GROUP BY c.category_name " +
            "ORDER BY total_qty DESC"
        );
        @SuppressWarnings("unchecked")
        List<Object[]> distResults = distQuery.getResultList();
        double grandTotal = 0;
        for (Object[] row : distResults) {
            grandTotal += ((Number) row[1]).doubleValue();
        }

        List<ManagerDashboardDataDTO.InventoryDistributionDTO> distributionList = new ArrayList<>();
        for (Object[] row : distResults) {
            String categoryName = (String) row[0];
            double qty = ((Number) row[1]).doubleValue();
            double percentage = grandTotal > 0 ? (qty / grandTotal) * 100 : 0.0;
            percentage = BigDecimal.valueOf(percentage).setScale(1, RoundingMode.HALF_UP).doubleValue();
            distributionList.add(new ManagerDashboardDataDTO.InventoryDistributionDTO(categoryName, percentage));
        }

        // 10. Recent Activities
        List<RecentActivityDTO> activities = new ArrayList<>();

        // Promotions
        Query promoQuery = entityManager.createNativeQuery(
            "SELECT promotion_name, discount_value, start_date FROM promotions ORDER BY start_date DESC LIMIT 5"
        );
        @SuppressWarnings("unchecked")
        List<Object[]> promoRows = promoQuery.getResultList();
        for (Object[] row : promoRows) {
            String name = (String) row[0];
            Number discount = (Number) row[1];
            LocalDateTime time = convertToLocalDateTime(row[2]);
            activities.add(RecentActivityDTO.builder()
                .action("Promotion Scheduled")
                .item("'" + name + "' approved")
                .quantity(discount + "% discount")
                .time(time)
                .build());
        }

        // Stock-ins
        Query stockInQuery = entityManager.createNativeQuery(
            "SELECT s.supplier_name, si.stock_in_date FROM stock_ins si JOIN suppliers s ON si.supplier_number = s.supplier_number ORDER BY si.stock_in_date DESC LIMIT 5"
        );
        @SuppressWarnings("unchecked")
        List<Object[]> stockInRows = stockInQuery.getResultList();
        for (Object[] row : stockInRows) {
            String supplierName = (String) row[0];
            LocalDateTime time = convertToLocalDateTime(row[1]);
            activities.add(RecentActivityDTO.builder()
                .action("Supplier Delivery Received")
                .item("Delivery from " + supplierName)
                .quantity("1 delivery")
                .time(time)
                .build());
        }

        // Profiles / Staff
        Query staffQuery = entityManager.createNativeQuery(
            "SELECT full_name, role_number, created_at FROM profiles ORDER BY created_at DESC LIMIT 5"
        );
        @SuppressWarnings("unchecked")
        List<Object[]> staffRows = staffQuery.getResultList();
        for (Object[] row : staffRows) {
            String fullName = (String) row[0];
            Number roleNum = (Number) row[1];
            LocalDateTime time = convertToLocalDateTime(row[2]);
            
            String roleName = "Staff";
            if (roleNum != null) {
                int role = roleNum.intValue();
                if (role == 1) roleName = "Admin";
                else if (role == 2) roleName = "Manager";
                else if (role == 3) roleName = "Stock Controller";
                else if (role == 4) roleName = "Sales Associate";
                else if (role == 5) roleName = "Cashier";
            }
            activities.add(RecentActivityDTO.builder()
                .action("New Staff Onboarded")
                .item(fullName + " onboarded")
                .quantity(roleName)
                .time(time)
                .build());
        }

        // Reports
        Query reportQuery = entityManager.createNativeQuery(
            "SELECT pr.description, pr.created_at FROM product_reports pr ORDER BY pr.created_at DESC LIMIT 5"
        );
        @SuppressWarnings("unchecked")
        List<Object[]> reportRows = reportQuery.getResultList();
        for (Object[] row : reportRows) {
            String desc = (String) row[0];
            LocalDateTime time = convertToLocalDateTime(row[1]);
            activities.add(RecentActivityDTO.builder()
                .action("Inventory Warning")
                .item(desc)
                .quantity("1 warning")
                .time(time)
                .build());
        }

        // Sort combined list by time descending and take top 5
        List<RecentActivityDTO> sortedActivities = activities.stream()
            .sorted((a, b) -> b.getTime().compareTo(a.getTime()))
            .limit(5)
            .collect(Collectors.toList());

        return ManagerDashboardDataDTO.builder()
            .totalProducts(totalProducts)
            .totalStaff(totalStaff)
            .totalCustomers(totalCustomers)
            .totalSuppliers(totalSuppliers)
            .totalRevenue(totalRevenue)
            .revenueToday(revenueToday)
            .activeOrdersCount(activeOrdersCount)
            .stockLevel(stockLevel)
            .lowStockCount(lowStockCount)
            .weeklyRevenue(weeklyRevenueList)
            .inventoryDistribution(distributionList)
            .recentActivities(sortedActivities)
            .updatedAt(LocalDateTime.now())
            .build();
    }

    private LocalDateTime convertToLocalDateTime(Object obj) {
        if (obj == null) return LocalDateTime.now();
        if (obj instanceof Timestamp) {
            return ((Timestamp) obj).toLocalDateTime();
        }
        if (obj instanceof LocalDateTime) {
            return (LocalDateTime) obj;
        }
        if (obj instanceof java.util.Date) {
            return new Timestamp(((java.util.Date) obj).getTime()).toLocalDateTime();
        }
        return LocalDateTime.now();
    }
}
