package com.supermarket.backend.service;

import com.supermarket.backend.dto.*;
import com.supermarket.backend.entity.InventoryTransaction;
import com.supermarket.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.jdbc.core.JdbcTemplate;
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
    private final JdbcTemplate jdbcTemplate;

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

    @Transactional(readOnly = true)
    public List<com.supermarket.backend.dto.InventoryTransactionDTO> getInventoryTransactions() {
        List<InventoryTransaction> transactions = inventoryTransactionRepository.findAllTransactions();
        return transactions.stream().map(t -> {
            String unitName = "Unknown";
            if (t.getProduct() != null && t.getProduct().getUnit() != null) {
                unitName = t.getProduct().getUnit().getUnitName();
            }
            return com.supermarket.backend.dto.InventoryTransactionDTO.builder()
                    .transactionNumber(t.getTransactionNumber())
                    .productNumber(t.getProduct() != null ? t.getProduct().getProductNumber() : null)
                    .productName(t.getProduct() != null ? t.getProduct().getProductName() : "Unknown Product")
                    .type(t.getType())
                    .quantity(t.getQuantity())
                    .unitName(unitName)
                    .referenceType(t.getReferenceType())
                    .referenceId(t.getReferenceId())
                    .reason(t.getReason())
                    .createdBy(t.getCreatedBy() != null ? t.getCreatedBy().toString() : null)
                    .createdAt(t.getCreatedAt())
                    .build();
        }).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public PendingTasksDTO getPendingTasks() {
        String stockInSql = "SELECT pr.purchase_request_number, pr.created_date, pr.status, " +
                "(SELECT s.supplier_name FROM purchase_request_details prd " +
                " JOIN product_suppliers ps ON prd.product_supplier_number = ps.product_supplier_number " +
                " JOIN suppliers s ON ps.supplier_number = s.supplier_number " +
                " WHERE prd.purchase_request_number = pr.purchase_request_number LIMIT 1) as supplier_name, " +
                "(SELECT SUM(prd.requested_quantity) FROM purchase_request_details prd " +
                " WHERE prd.purchase_request_number = pr.purchase_request_number) as total_items, " +
                "(SELECT u.unit_name FROM purchase_request_details prd " +
                " JOIN product_suppliers ps ON prd.product_supplier_number = ps.product_supplier_number " +
                " JOIN products p ON ps.product_number = p.product_number " +
                " JOIN units u ON p.inventory_unit_number = u.unit_number " +
                " WHERE prd.purchase_request_number = pr.purchase_request_number LIMIT 1) as unit_name " +
                "FROM purchase_requests pr " +
                "WHERE pr.status IN ('APPROVED', 'PARTIALLY_RECEIVED')";

        List<PendingStockInDTO> pendingStockIns = jdbcTemplate.query(stockInSql, (rs, rowNum) -> 
            PendingStockInDTO.builder()
                .purchaseRequestNumber(rs.getInt("purchase_request_number"))
                .createdDate(rs.getTimestamp("created_date") != null ? rs.getTimestamp("created_date").toLocalDateTime() : null)
                .supplierName(rs.getString("supplier_name"))
                .totalItems(rs.getBigDecimal("total_items"))
                .unitName(rs.getString("unit_name"))
                .status(rs.getString("status"))
                .build()
        );

        String stockOutSql = "SELECT pr.report_number, p.product_name, pr.quantity, u.unit_name, " +
                "('A-' || p.category_number || '-' || p.product_number) as location, pr.created_at " +
                "FROM product_reports pr " +
                "JOIN products p ON pr.product_number = p.product_number " +
                "JOIN units u ON p.inventory_unit_number = u.unit_number " +
                "WHERE pr.status = 'APPROVED' AND pr.report_type IN ('DAMAGED', 'NEAR_EXPIRY')";

        List<PendingStockOutDTO> pendingStockOuts = jdbcTemplate.query(stockOutSql, (rs, rowNum) -> 
            PendingStockOutDTO.builder()
                .reportNumber(rs.getInt("report_number"))
                .productName(rs.getString("product_name"))
                .quantity(rs.getBigDecimal("quantity"))
                .unitName(rs.getString("unit_name"))
                .location(rs.getString("location"))
                .createdAt(rs.getTimestamp("created_at") != null ? rs.getTimestamp("created_at").toLocalDateTime() : null)
                .build()
        );

        return PendingTasksDTO.builder()
                .pendingStockIns(pendingStockIns)
                .pendingStockOuts(pendingStockOuts)
                .build();
    }
}
