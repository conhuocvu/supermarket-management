package com.supermarket.backend.service;

import com.supermarket.backend.dto.DashboardDataDTO;
import com.supermarket.backend.dto.RecentActivityDTO;
import com.supermarket.backend.entity.InventoryTransaction;
import com.supermarket.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class InventoryService {

    private final ProductRepository productRepository;
    private final InventoryRepository inventoryRepository;
    private final StockInDetailRepository stockInDetailRepository;
    private final PurchaseRequestRepository purchaseRequestRepository;
    private final InventoryTransactionRepository inventoryTransactionRepository;

    @Transactional(readOnly = true)
    public DashboardDataDTO getDashboardData() {
        long totalProducts = productRepository.count();
        long lowStockCount = inventoryRepository.countLowStock();
        
        LocalDate now = LocalDate.now();
        LocalDate threshold = now.plusDays(30);
        long nearExpiryCount = stockInDetailRepository.countNearExpiry(now, threshold);
        
        long pendingRequestsCount = purchaseRequestRepository.countByStatus("PENDING");
        
        BigDecimal sumAvailable = inventoryRepository.sumAvailableQuantity();
        double capacityUsed = 0.0;
        if (sumAvailable != null && sumAvailable.doubleValue() > 0) {
            // Assume default warehouse capacity is 5000 units
            double capacityLimit = 5000.0;
            capacityUsed = (sumAvailable.doubleValue() / capacityLimit) * 100;
            if (capacityUsed > 100.0) {
                capacityUsed = 100.0;
            }
            // Round to 1 decimal place
            capacityUsed = BigDecimal.valueOf(capacityUsed)
                    .setScale(1, RoundingMode.HALF_UP)
                    .doubleValue();
        }

        List<InventoryTransaction> transactions = inventoryTransactionRepository.findRecentTransactions(PageRequest.of(0, 10));
        List<RecentActivityDTO> recentActivities = transactions.stream()
                .map(t -> {
                    String action = "Stock adjustment";
                    if ("IN".equalsIgnoreCase(t.getType())) {
                        action = "Stock-in";
                    } else if ("OUT".equalsIgnoreCase(t.getType())) {
                        action = "Stock-out";
                    }

                    String item = t.getProduct() != null ? t.getProduct().getProductName() : "Unknown Item";
                    
                    // Format quantity nicely, removing unnecessary decimals
                    String qtyStr = "0 units";
                    if (t.getQuantity() != null) {
                        BigDecimal qty = t.getQuantity();
                        qtyStr = qty.stripTrailingZeros().toPlainString() + " units";
                    }

                    return RecentActivityDTO.builder()
                            .action(action)
                            .item(item)
                            .quantity(qtyStr)
                            .time(t.getCreatedAt())
                            .build();
                })
                .collect(Collectors.toList());

        return DashboardDataDTO.builder()
                .totalProducts(totalProducts)
                .lowStockCount(lowStockCount)
                .nearExpiryCount(nearExpiryCount)
                .pendingRequestsCount(pendingRequestsCount)
                .capacityUsed(capacityUsed)
                .recentActivities(recentActivities)
                .updatedAt(LocalDateTime.now())
                .build();
    }
}
