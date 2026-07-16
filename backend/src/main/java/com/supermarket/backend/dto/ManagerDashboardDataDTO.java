package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ManagerDashboardDataDTO {
    private long totalProducts;
    private long totalStaff;
    private long totalCustomers;
    private long totalSuppliers;
    private double totalRevenue;
    private double revenueToday;
    private long activeOrdersCount;
    private double stockLevel;
    private long lowStockCount;
    private List<WeeklyRevenueDTO> weeklyRevenue;
    private List<InventoryDistributionDTO> inventoryDistribution;
    private List<RecentActivityDTO> recentActivities;
    private LocalDateTime updatedAt;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class WeeklyRevenueDTO {
        private String day;
        private double amount;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class InventoryDistributionDTO {
        private String categoryName;
        private double percentage;
    }
}
