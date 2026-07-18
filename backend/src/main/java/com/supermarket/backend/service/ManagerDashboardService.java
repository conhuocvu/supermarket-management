package com.supermarket.backend.service;

import com.supermarket.backend.dto.ManagerDashboardDataDTO;
import com.supermarket.backend.dto.RecentActivityDTO;
import com.supermarket.backend.repository.InventoryRepository;
import com.supermarket.backend.repository.ProductRepository;
import com.supermarket.backend.repository.ManagerDashboardRepository;
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
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ManagerDashboardService {

    private final ProductRepository productRepository;
    private final InventoryRepository inventoryRepository;
    private final ManagerDashboardRepository managerDashboardRepository;

    public ManagerDashboardDataDTO getManagerDashboardData() {
        long totalProducts = productRepository.count();
        long lowStockCount = inventoryRepository.countLowStock();

        // 1. Total Staff
        long totalStaff = managerDashboardRepository.countStaff();

        // 2. Total Customers
        long totalCustomers = managerDashboardRepository.countCustomers();

        // 3. Total Suppliers
        long totalSuppliers = managerDashboardRepository.countSuppliers();

        // 4. Total Revenue
        double totalRevenue = managerDashboardRepository.sumTotalRevenue();

        // 5. Revenue Today
        double revenueToday = managerDashboardRepository.sumRevenueToday();

        // 6. Active Orders Today (Completed or Pending Invoices today)
        long activeOrdersCount = managerDashboardRepository.countActiveOrdersToday();

        // 7. Stock Level Percentage
        double stockLevel = 100.0;
        if (totalProducts > 0) {
            stockLevel = ((double) (totalProducts - lowStockCount) / totalProducts) * 100.0;
            stockLevel = BigDecimal.valueOf(stockLevel).setScale(1, RoundingMode.HALF_UP).doubleValue();
        }

        // 8. Weekly Revenue (optimized: single query group by day)
        LocalDate startDate = LocalDate.now().minusDays(6);
        List<Object[]> weeklyRevenueData = managerDashboardRepository.getWeeklyRevenue(startDate);
        Map<LocalDate, Double> revenueMap = new HashMap<>();
        for (Object[] row : weeklyRevenueData) {
            LocalDate date;
            Object dateObj = row[0];
            if (dateObj instanceof java.sql.Date) {
                date = ((java.sql.Date) dateObj).toLocalDate();
            } else if (dateObj instanceof LocalDate) {
                date = (LocalDate) dateObj;
            } else {
                date = LocalDate.parse(dateObj.toString());
            }
            double amount = ((Number) row[1]).doubleValue();
            revenueMap.put(date, amount);
        }

        List<ManagerDashboardDataDTO.WeeklyRevenueDTO> weeklyRevenueList = new ArrayList<>();
        LocalDate today = LocalDate.now();
        for (int i = 6; i >= 0; i--) {
            LocalDate date = today.minusDays(i);
            String dayName = date.getDayOfWeek().getDisplayName(TextStyle.SHORT, Locale.ENGLISH);
            double amount = revenueMap.getOrDefault(date, 0.0);
            weeklyRevenueList.add(new ManagerDashboardDataDTO.WeeklyRevenueDTO(dayName, amount));
        }

        // 9. Inventory Distribution
        List<Object[]> distResults = managerDashboardRepository.getInventoryDistribution();
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
        List<Object[]> promoRows = managerDashboardRepository.findRecentPromotions();
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
        List<Object[]> stockInRows = managerDashboardRepository.findRecentDeliveries();
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
        List<Object[]> staffRows = managerDashboardRepository.findRecentProfiles();
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
        List<Object[]> reportRows = managerDashboardRepository.findRecentReports();
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
