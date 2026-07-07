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
public class DashboardDataDTO {
    private long totalProducts;
    private long lowStockCount;
    private long nearExpiryCount;
    private long pendingRequestsCount;
    private double capacityUsed;
    private List<RecentActivityDTO> recentActivities;
    private LocalDateTime updatedAt;
}
