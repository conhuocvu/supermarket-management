package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReportsDashboardDTO {

    private StatisticsSection statistics;
    private RevenueSection revenue;
    private InventorySection inventory;
    private WasteSection waste;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class StatisticsSection {
        private double grossSales;
        private String grossSalesTrend;
        private double avgBasket;
        private String avgBasketTrend;
        private double stockTurn;
        private String stockTurnTrend;
        private int footTraffic;
        private String footTrafficTrend;
        private List<SalesVelocityPoint> salesVelocity;
        private List<CategoryPercentage> topCategories;
        private List<AnomalyDTO> recentAnomalies;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RevenueSection {
        private double netSales;
        private String netSalesTrend;
        private double netProfit;
        private String netProfitTrend;
        private double grossMargin;
        private String grossMarginTrend;
        private List<SalesVelocityPoint> revenueTrend;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class InventorySection {
        private double totalStockValue;
        private String stockValueTrend;
        private int lowStockAlerts;
        private double stockTurnoverRate;
        private List<CategoryPercentage> inventoryDistribution;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class WasteSection {
        private double totalWasteValue;
        private String wasteValueTrend;
        private int wasteItemsCount;
        private List<AnomalyDTO> recentWasteEvents;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SalesVelocityPoint {
        private String label;
        private double amount;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CategoryPercentage {
        private String categoryName;
        private double percentage;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AnomalyDTO {
        private String timestamp;
        private String entity;
        private String eventType;
        private String value;
        private String action;
    }
}
