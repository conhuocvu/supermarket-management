package com.supermarket.backend.service;

import com.supermarket.backend.dto.*;
import com.supermarket.backend.entity.*;
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
import java.util.UUID;
import java.util.Map;
import java.util.HashMap;
import java.util.Optional;
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

    private final StockInRepository stockInRepository;
    private final PurchaseRequestDetailRepository purchaseRequestDetailRepository;
    private final ProductReportRepository productReportRepository;
    private final ProductSupplierRepository productSupplierRepository;
    private final SupplierRepository supplierRepository;
    private final StockOutRepository stockOutRepository;
    private final StockOutDetailRepository stockOutDetailRepository;

    @org.springframework.beans.factory.annotation.Value("${app.default-user-id:e3b3ec4a-da0b-40f5-9747-29361993892b}")
    private String defaultUserIdStr;

    private UUID getDefaultUserId() {
        return UUID.fromString(defaultUserIdStr);
    }

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

        List<InventoryTransaction> transactions = inventoryTransactionRepository
                .findRecentTransactions(PageRequest.of(0, 10));
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
                "s.supplier_name, s.supplier_number, " +
                "SUM(prd.requested_quantity) as total_items, " +
                "MAX(u.unit_name) as unit_name " +
                "FROM purchase_requests pr " +
                "JOIN purchase_request_details prd ON pr.purchase_request_number = prd.purchase_request_number " +
                "JOIN product_suppliers ps ON prd.product_supplier_number = ps.product_supplier_number " +
                "JOIN suppliers s ON ps.supplier_number = s.supplier_number " +
                "JOIN products p ON ps.product_number = p.product_number " +
                "JOIN units u ON p.inventory_unit_number = u.unit_number " +
                "WHERE pr.status IN ('APPROVED', 'PARTIALLY_RECEIVED') " +
                "GROUP BY pr.purchase_request_number, pr.created_date, pr.status, s.supplier_name, s.supplier_number";

        List<PendingStockInDTO> pendingStockIns = jdbcTemplate.query(stockInSql, (rs, rowNum) -> PendingStockInDTO
                .builder()
                .purchaseRequestNumber(rs.getInt("purchase_request_number"))
                .createdDate(rs.getTimestamp("created_date") != null ? rs.getTimestamp("created_date").toLocalDateTime()
                        : null)
                .supplierName(rs.getString("supplier_name"))
                .supplierNumber(rs.getInt("supplier_number"))
                .totalItems(rs.getBigDecimal("total_items"))
                .unitName(rs.getString("unit_name"))
                .status(rs.getString("status"))
                .build());

        String stockOutSql = "SELECT pr.report_number, p.product_name, pr.quantity, u.unit_name, " +
                "('A-' || p.category_number || '-' || p.product_number) as location, pr.created_at " +
                "FROM product_reports pr " +
                "JOIN products p ON pr.product_number = p.product_number " +
                "JOIN units u ON p.inventory_unit_number = u.unit_number " +
                "WHERE pr.status = 'APPROVED' AND pr.resolved_at IS NULL AND pr.report_type IN ('DAMAGED', 'NEAR_EXPIRY', 'QUALITY_ISSUE')";

        List<PendingStockOutDTO> pendingStockOuts = jdbcTemplate.query(stockOutSql, (rs, rowNum) -> PendingStockOutDTO
                .builder()
                .reportNumber(rs.getInt("report_number"))
                .productName(rs.getString("product_name"))
                .quantity(rs.getBigDecimal("quantity"))
                .unitName(rs.getString("unit_name"))
                .location(rs.getString("location"))
                .createdAt(
                        rs.getTimestamp("created_at") != null ? rs.getTimestamp("created_at").toLocalDateTime() : null)
                .build());

        return PendingTasksDTO.builder()
                .pendingStockIns(pendingStockIns)
                .pendingStockOuts(pendingStockOuts)
                .build();
    }

    @Transactional(readOnly = true)
    public StockInFormDataDTO getPurchaseRequestDetail(Integer prNumber, Integer supplierNumber) {
        PurchaseRequest pr = purchaseRequestRepository.findById(prNumber)
                .orElseThrow(() -> new IllegalArgumentException("Purchase request not found: " + prNumber));

        List<PurchaseRequestDetail> details = purchaseRequestDetailRepository.findByPurchaseRequestNumber(prNumber);
        if (details.isEmpty()) {
            throw new IllegalArgumentException("No items found for purchase request: " + prNumber);
        }

        if (supplierNumber != null) {
            details = details.stream().filter(d -> {
                ProductSupplier ps = productSupplierRepository.findById(d.getProductSupplierNumber()).orElse(null);
                return ps != null && supplierNumber.equals(ps.getSupplierNumber());
            }).collect(Collectors.toList());
            if (details.isEmpty()) {
                throw new IllegalArgumentException("No items found for purchase request: " + prNumber + " and supplier: " + supplierNumber);
            }
        }

        Integer finalSupplierNumber = supplierNumber;
        String supplierName = "Unknown";

        if (finalSupplierNumber == null) {
            // Resolve supplier from the first detail
            Integer psNum = details.get(0).getProductSupplierNumber();
            Optional<ProductSupplier> psOpt = productSupplierRepository.findById(psNum);
            if (psOpt.isPresent()) {
                finalSupplierNumber = psOpt.get().getSupplierNumber();
            }
        }

        if (finalSupplierNumber != null) {
            supplierName = supplierRepository.findById(finalSupplierNumber)
                    .map(s -> s.getSupplierName())
                    .orElse("Unknown");
        }

        List<Integer> psIds = details.stream().map(PurchaseRequestDetail::getProductSupplierNumber).collect(Collectors.toList());
        List<ProductSupplier> productSuppliers = productSupplierRepository.findAllById(psIds);
        Map<Integer, ProductSupplier> psMap = productSuppliers.stream()
                .collect(Collectors.toMap(ProductSupplier::getProductSupplierNumber, s -> s));

        List<Integer> pIds = productSuppliers.stream().map(ProductSupplier::getProductNumber).collect(Collectors.toList());
        List<Product> products = productRepository.findAllById(pIds);
        Map<Integer, Product> pMap = products.stream()
                .collect(Collectors.toMap(Product::getProductNumber, p -> p));

        Map<Integer, BigDecimal> alreadyReceivedMap = jdbcTemplate.query(
                "SELECT sid.product_number, COALESCE(SUM(sid.quantity), 0) as total_qty " +
                        "FROM stock_in_details sid " +
                        "JOIN stock_ins si ON sid.stock_in_number = si.stock_in_number " +
                        "WHERE si.purchase_request_number = ? " +
                        "GROUP BY sid.product_number",
                rs -> {
                    Map<Integer, BigDecimal> map = new java.util.HashMap<>();
                    while (rs.next()) {
                        map.put(rs.getInt("product_number"), rs.getBigDecimal("total_qty"));
                    }
                    return map;
                },
                prNumber
        );

        List<StockInItemDTO> items = details.stream().map(d -> {
            ProductSupplier prodSupplier = psMap.get(d.getProductSupplierNumber());
            if (prodSupplier == null) {
                throw new IllegalArgumentException(
                        "Product supplier mapping not found: " + d.getProductSupplierNumber());
            }

            Product p = pMap.get(prodSupplier.getProductNumber());
            if (p == null) {
                throw new IllegalArgumentException(
                        "Product not found: " + prodSupplier.getProductNumber());
            }

            String unitName = p.getUnit() != null ? p.getUnit().getUnitName() : "Unit";

            BigDecimal alreadyReceived = alreadyReceivedMap != null ? alreadyReceivedMap.getOrDefault(p.getProductNumber(), BigDecimal.ZERO) : BigDecimal.ZERO;

            BigDecimal requestedQty = d.getRequestedQuantity() != null ? d.getRequestedQuantity() : BigDecimal.ZERO;
            BigDecimal remainingQty = requestedQty.subtract(alreadyReceived);
            if (remainingQty.compareTo(BigDecimal.ZERO) < 0) {
                remainingQty = BigDecimal.ZERO;
            }

            return StockInItemDTO.builder()
                    .productNumber(p.getProductNumber())
                    .productName(p.getProductName())
                    .sku(p.getBarcode())
                    .requestedQuantity(remainingQty)
                    .importPrice(prodSupplier.getImportPrice())
                    .unitName(unitName)
                    .build();
        }).collect(Collectors.toList());

        return StockInFormDataDTO.builder()
                .purchaseRequestNumber(pr.getPurchaseRequestNumber())
                .supplierName(supplierName)
                .supplierNumber(finalSupplierNumber)
                .createdDate(pr.getCreatedDate())
                .status(pr.getStatus())
                .items(items)
                .build();
    }

    @Transactional(readOnly = true)
    public CompareQuantitiesResultDTO compareQuantities(CompareQuantitiesRequestDTO request) {
        Integer prNumber = request.getPurchaseRequestNumber();
        Integer supplierNumber = request.getSupplierNumber();
        Map<Integer, BigDecimal> delivered = request.getDeliveredQuantities();

        List<PurchaseRequestDetail> details = purchaseRequestDetailRepository.findByPurchaseRequestNumber(prNumber);
        List<Integer> psIds = details.stream().map(PurchaseRequestDetail::getProductSupplierNumber).collect(Collectors.toList());
        List<ProductSupplier> productSuppliers = productSupplierRepository.findAllById(psIds);
        Map<Integer, ProductSupplier> psMap = productSuppliers.stream()
                .collect(Collectors.toMap(ProductSupplier::getProductSupplierNumber, s -> s));

        if (supplierNumber != null) {
            details = details.stream().filter(d -> {
                ProductSupplier ps = psMap.get(d.getProductSupplierNumber());
                return ps != null && supplierNumber.equals(ps.getSupplierNumber());
            }).collect(Collectors.toList());
        }
        Map<Integer, BigDecimal> differences = new HashMap<>();
        boolean hasDiscrepancy = false;

        Map<Integer, BigDecimal> alreadyReceivedMap = jdbcTemplate.query(
                "SELECT sid.product_number, COALESCE(SUM(sid.quantity), 0) as total_qty " +
                        "FROM stock_in_details sid " +
                        "JOIN stock_ins si ON sid.stock_in_number = si.stock_in_number " +
                        "WHERE si.purchase_request_number = ? " +
                        "GROUP BY sid.product_number",
                rs -> {
                    Map<Integer, BigDecimal> map = new java.util.HashMap<>();
                    while (rs.next()) {
                        map.put(rs.getInt("product_number"), rs.getBigDecimal("total_qty"));
                    }
                    return map;
                },
                prNumber
        );

        for (PurchaseRequestDetail d : details) {
            ProductSupplier prodSupplier = psMap.get(d.getProductSupplierNumber());
            if (prodSupplier == null) {
                throw new IllegalArgumentException(
                        "Product supplier mapping not found: " + d.getProductSupplierNumber());
            }

            Integer prodNum = prodSupplier.getProductNumber();
            BigDecimal alreadyReceived = alreadyReceivedMap != null ? alreadyReceivedMap.getOrDefault(prodNum, BigDecimal.ZERO) : BigDecimal.ZERO;

            BigDecimal requestedQty = d.getRequestedQuantity() != null ? d.getRequestedQuantity() : BigDecimal.ZERO;
            BigDecimal remainingQty = requestedQty.subtract(alreadyReceived);
            if (remainingQty.compareTo(BigDecimal.ZERO) < 0) {
                remainingQty = BigDecimal.ZERO;
            }

            BigDecimal delQty = delivered != null && delivered.containsKey(prodNum) ? delivered.get(prodNum)
                    : BigDecimal.ZERO;

            BigDecimal diff = remainingQty.subtract(delQty);
            differences.put(prodNum, diff);

            if (diff.compareTo(BigDecimal.ZERO) != 0) {
                hasDiscrepancy = true;
            }
        }

        return CompareQuantitiesResultDTO.builder()
                .hasDiscrepancy(hasDiscrepancy)
                .differences(differences)
                .matched(!hasDiscrepancy)
                .build();
    }

    @Transactional
    public void validateAndSaveDeliveryIssue(DeliveryIssueRequestDTO request) {
        if (request.getPurchaseRequestNumber() == null) {
            throw new IllegalArgumentException("Purchase request number is required.");
        }
        if (request.getProductNumber() == null) {
            throw new IllegalArgumentException("Product number is required.");
        }
        if (request.getQuantity() == null || request.getQuantity().compareTo(BigDecimal.ZERO) == 0) {
            throw new IllegalArgumentException("Discrepancy quantity is required.");
        }
        if (request.getIssueType() == null || request.getIssueType().trim().isEmpty()) {
            throw new IllegalArgumentException("Issue type is required.");
        }
        if (request.getDescription() == null || request.getDescription().trim().isEmpty()) {
            throw new IllegalArgumentException("Description is required.");
        }

        UUID reportedBy = null;
        if (request.getReportedBy() != null && !request.getReportedBy().trim().isEmpty()) {
            reportedBy = UUID.fromString(request.getReportedBy());
        } else {
            reportedBy = getDefaultUserId();
        }

        String prefixedDescription = "[PR-" + request.getPurchaseRequestNumber() + "] " + request.getDescription();

        ProductReport report = ProductReport.builder()
                .reportedBy(reportedBy)
                .productNumber(request.getProductNumber())
                .reportType("DELIVERY_DISCREPANCY")
                .issueType(request.getIssueType().toUpperCase())
                .quantity(request.getQuantity().abs())
                .description(prefixedDescription)
                .status("PENDING")
                .createdAt(LocalDateTime.now())
                .build();

        productReportRepository.save(report);
    }

    @Transactional
    public void recordStockIn(StockInRequestDTO request) {
        if (request.getPurchaseRequestNumber() == null) {
            throw new IllegalArgumentException("Purchase request number is required.");
        }
        if (request.getItems() == null || request.getItems().isEmpty()) {
            throw new IllegalArgumentException("Stock-in items list cannot be empty.");
        }

        // 1. Load and lock purchase request
        PurchaseRequest pr = purchaseRequestRepository.findByIdForUpdate(request.getPurchaseRequestNumber())
                .orElseThrow(() -> new IllegalArgumentException(
                        "Purchase request not found: " + request.getPurchaseRequestNumber()));

        // 2. Check status
        if (!"APPROVED".equals(pr.getStatus()) && !"PARTIALLY_RECEIVED".equals(pr.getStatus())) {
            throw new IllegalArgumentException(
                    "Purchase request is not in an eligible status for stock-in: " + pr.getStatus());
        }

        // 3. Load purchase request details
        List<PurchaseRequestDetail> allPrDetails = purchaseRequestDetailRepository
                .findByPurchaseRequestNumber(request.getPurchaseRequestNumber());
        if (allPrDetails.isEmpty()) {
            throw new IllegalArgumentException(
                    "No items found for purchase request: " + request.getPurchaseRequestNumber());
        }

        // 4. Verify and filter details by supplier
        Integer requestSupplierNum = request.getSupplierNumber();
        if (requestSupplierNum == null) {
            throw new IllegalArgumentException("Supplier number is required for Stock-In.");
        }

        List<Integer> allPsIds = allPrDetails.stream().map(PurchaseRequestDetail::getProductSupplierNumber).collect(Collectors.toList());
        List<ProductSupplier> allProductSuppliers = productSupplierRepository.findAllById(allPsIds);
        Map<Integer, ProductSupplier> allPsMap = allProductSuppliers.stream()
                .collect(Collectors.toMap(ProductSupplier::getProductSupplierNumber, s -> s));

        List<PurchaseRequestDetail> prDetails = allPrDetails.stream().filter(prd -> {
            ProductSupplier ps = allPsMap.get(prd.getProductSupplierNumber());
            return ps != null && requestSupplierNum.equals(ps.getSupplierNumber());
        }).collect(Collectors.toList());

        if (prDetails.isEmpty()) {
            throw new IllegalArgumentException("No items found in purchase request " + request.getPurchaseRequestNumber() +
                    " for supplier " + requestSupplierNum);
        }

        // 5. Build Map of product outstanding quantities
        Map<Integer, BigDecimal> prProductOutstanding = new HashMap<>();
        Map<Integer, BigDecimal> alreadyReceivedMap = jdbcTemplate.query(
                "SELECT sid.product_number, COALESCE(SUM(sid.quantity), 0) as total_qty " +
                        "FROM stock_in_details sid " +
                        "JOIN stock_ins si ON sid.stock_in_number = si.stock_in_number " +
                        "WHERE si.purchase_request_number = ? " +
                        "GROUP BY sid.product_number",
                rs -> {
                    Map<Integer, BigDecimal> map = new java.util.HashMap<>();
                    while (rs.next()) {
                        map.put(rs.getInt("product_number"), rs.getBigDecimal("total_qty"));
                    }
                    return map;
                },
                request.getPurchaseRequestNumber()
        );

        for (PurchaseRequestDetail prd : prDetails) {
            ProductSupplier ps = allPsMap.get(prd.getProductSupplierNumber());
            if (ps == null) {
                throw new IllegalArgumentException(
                        "Product supplier mapping not found: " + prd.getProductSupplierNumber());
            }
            Integer productNum = ps.getProductNumber();

            BigDecimal requestedQty = prd.getRequestedQuantity() != null ? prd.getRequestedQuantity() : BigDecimal.ZERO;
            BigDecimal alreadyReceived = alreadyReceivedMap != null ? alreadyReceivedMap.getOrDefault(productNum, BigDecimal.ZERO) : BigDecimal.ZERO;

            BigDecimal remainingQty = requestedQty.subtract(alreadyReceived);
            if (remainingQty.compareTo(BigDecimal.ZERO) < 0) {
                remainingQty = BigDecimal.ZERO;
            }

            prProductOutstanding.put(productNum,
                    prProductOutstanding.getOrDefault(productNum, BigDecimal.ZERO).add(remainingQty));
        }

        // 6. Check items delivered quantities against outstanding
        Map<Integer, BigDecimal> requestProductDelivered = new HashMap<>();
        for (StockInDetailRequestDTO item : request.getItems()) {
            if (item.getProductNumber() == null) {
                throw new IllegalArgumentException("Product number is required for all items.");
            }
            if (item.getDeliveredQuantity() == null || item.getDeliveredQuantity().compareTo(BigDecimal.ZERO) < 0) {
                throw new IllegalArgumentException("Delivered quantity must be 0 or positive.");
            }
            if (item.getManufacturingDate() != null && item.getExpiryDate() != null) {
                if (item.getExpiryDate().isBefore(item.getManufacturingDate())) {
                    throw new IllegalArgumentException("Expiry date cannot be before manufacturing date.");
                }
            }
            requestProductDelivered.put(item.getProductNumber(),
                    requestProductDelivered.getOrDefault(item.getProductNumber(), BigDecimal.ZERO)
                            .add(item.getDeliveredQuantity()));
        }

        for (Map.Entry<Integer, BigDecimal> entry : requestProductDelivered.entrySet()) {
            Integer productNum = entry.getKey();
            BigDecimal totalDelivered = entry.getValue();

            if (!prProductOutstanding.containsKey(productNum)) {
                throw new IllegalArgumentException("Product " + productNum + " is not part of the purchase request.");
            }

            BigDecimal outstandingQty = prProductOutstanding.get(productNum);
            if (totalDelivered.compareTo(outstandingQty) > 0) {
                throw new IllegalArgumentException("Over-delivery not allowed for product " + productNum +
                        ". Outstanding: " + outstandingQty + ", Delivered: " + totalDelivered);
            }
        }

        // Mutation starts only after all validations pass
        UUID createdBy = null;
        if (request.getCreatedBy() != null && !request.getCreatedBy().trim().isEmpty()) {
            createdBy = UUID.fromString(request.getCreatedBy());
        } else {
            createdBy = getDefaultUserId();
        }

        StockIn stockIn = StockIn.builder()
                .purchaseRequestNumber(request.getPurchaseRequestNumber())
                .supplierNumber(request.getSupplierNumber())
                .createdBy(createdBy)
                .stockInDate(LocalDateTime.now())
                .status("APPROVED")
                .build();
        stockIn = stockInRepository.save(stockIn);
        Integer stockInNumber = stockIn.getStockInNumber();

        List<Integer> itemProductIds = request.getItems().stream().map(StockInDetailRequestDTO::getProductNumber).collect(Collectors.toList());
        List<Product> itemProductsList = productRepository.findAllById(itemProductIds);
        Map<Integer, Product> itemProductsMap = itemProductsList.stream()
                .collect(Collectors.toMap(Product::getProductNumber, p -> p));

        for (StockInDetailRequestDTO item : request.getItems()) {
            String batchNumber = "BATCH-" + request.getPurchaseRequestNumber() + "-" + item.getProductNumber() + "-"
                    + java.util.UUID.randomUUID().toString().substring(0, 8);

            StockInDetail detail = StockInDetail.builder()
                    .stockInNumber(stockInNumber)
                    .productNumber(item.getProductNumber())
                    .batchNumber(batchNumber)
                    .quantity(item.getDeliveredQuantity())
                    .remainingQuantity(item.getDeliveredQuantity())
                    .importPrice(item.getImportPrice() != null ? item.getImportPrice() : BigDecimal.ZERO)
                    .manufacturingDate(item.getManufacturingDate())
                    .expiryDate(item.getExpiryDate())
                    .build();
            detail = stockInDetailRepository.save(detail);

            Inventory inv = inventoryRepository.findByIdForUpdate(item.getProductNumber())
                    .orElseGet(() -> {
                        Inventory newInv = Inventory.builder()
                                .productNumber(item.getProductNumber())
                                .availableQuantity(BigDecimal.ZERO)
                                .totalQuantity(BigDecimal.ZERO)
                                .build();
                        return inventoryRepository.save(newInv);
                    });

            BigDecimal currentAvailable = inv.getAvailableQuantity() != null ? inv.getAvailableQuantity()
                    : BigDecimal.ZERO;
            BigDecimal currentTotal = inv.getTotalQuantity() != null ? inv.getTotalQuantity() : BigDecimal.ZERO;

            inv.setAvailableQuantity(currentAvailable.add(item.getDeliveredQuantity()));
            inv.setTotalQuantity(currentTotal.add(item.getDeliveredQuantity()));
            inv.setLastUpdated(LocalDateTime.now());
            inventoryRepository.save(inv);

            InventoryTransaction tx = InventoryTransaction.builder()
                    .product(itemProductsMap.get(item.getProductNumber()))
                    .stockInDetailNumber(detail.getStockInDetailNumber())
                    .type("IN")
                    .quantity(item.getDeliveredQuantity())
                    .referenceType("STOCK_IN")
                    .referenceId(stockInNumber)
                    .reason(item.getNotes() != null && !item.getNotes().trim().isEmpty() ? item.getNotes()
                            : "Stock-in from purchase request #" + request.getPurchaseRequestNumber())
                    .createdBy(createdBy)
                    .createdAt(LocalDateTime.now())
                    .build();
            inventoryTransactionRepository.save(tx);

            final Integer currentProductNumber = item.getProductNumber();
            final Integer currentDetailNumber = detail.getStockInDetailNumber();
            final String prPrefix = "[PR-" + request.getPurchaseRequestNumber() + "]";
            List<ProductReport> reports = productReportRepository.findDeliveryDiscrepancies(
                    currentProductNumber,
                    prPrefix + "%"
            );

            for (ProductReport report : reports) {
                report.setStockInDetailNumber(currentDetailNumber);
                productReportRepository.save(report);
            }
        }

        Map<Integer, BigDecimal> updatedReceivedMap = jdbcTemplate.query(
                "SELECT sid.product_number, COALESCE(SUM(sid.quantity), 0) as total_qty " +
                        "FROM stock_in_details sid " +
                        "JOIN stock_ins si ON sid.stock_in_number = si.stock_in_number " +
                        "WHERE si.purchase_request_number = ? " +
                        "GROUP BY sid.product_number",
                rs -> {
                    Map<Integer, BigDecimal> map = new java.util.HashMap<>();
                    while (rs.next()) {
                        map.put(rs.getInt("product_number"), rs.getBigDecimal("total_qty"));
                    }
                    return map;
                },
                request.getPurchaseRequestNumber()
        );

        boolean allPrItemsCompleted = true;
        for (PurchaseRequestDetail prd : prDetails) {
            ProductSupplier prodSupplier = allPsMap.get(prd.getProductSupplierNumber());
            if (prodSupplier != null) {
                Integer prodNum = prodSupplier.getProductNumber();
                BigDecimal reqQty = prd.getRequestedQuantity() != null ? prd.getRequestedQuantity() : BigDecimal.ZERO;
                BigDecimal totalDelivered = updatedReceivedMap != null ? updatedReceivedMap.getOrDefault(prodNum, BigDecimal.ZERO) : BigDecimal.ZERO;

                if (totalDelivered.compareTo(reqQty) < 0) {
                    allPrItemsCompleted = false;
                }
            }
        }

        if (allPrItemsCompleted) {
            pr.setStatus("COMPLETED");
        } else {
            pr.setStatus("PARTIALLY_RECEIVED");
        }
        purchaseRequestRepository.save(pr);
    }

    @Transactional(readOnly = true)
    public StockOutFormDataDTO getStockOutFormData(Integer reportNumber) {
        ProductReport report = productReportRepository.findById(reportNumber)
                .orElseThrow(() -> new IllegalArgumentException("Product report not found: " + reportNumber));

        Product product = productRepository.findById(report.getProductNumber())
                .orElseThrow(() -> new IllegalArgumentException("Product not found: " + report.getProductNumber()));

        Inventory inventory = inventoryRepository.findById(product.getProductNumber())
                .orElse(null);

        BigDecimal availableQty = inventory != null && inventory.getAvailableQuantity() != null
                ? inventory.getAvailableQuantity()
                : BigDecimal.ZERO;

        String unitName = product.getUnit() != null ? product.getUnit().getUnitName() : "Unit";
        String location = "A-" + (product.getCategoryNumber() != null ? product.getCategoryNumber() : "0") + "-"
                + product.getProductNumber();

        return StockOutFormDataDTO.builder()
                .reportNumber(report.getReportNumber())
                .productNumber(product.getProductNumber())
                .productName(product.getProductName())
                .sku(product.getBarcode())
                .quantity(report.getQuantity())
                .unitName(unitName)
                .location(location)
                .description(report.getDescription())
                .reportType(report.getReportType())
                .issueType(report.getIssueType())
                .availableQuantity(availableQty)
                .build();
    }

    @Transactional
    public void recordStockOut(StockOutRequestDTO request) {
        if (request.getReportNumber() == null) {
            throw new IllegalArgumentException("Report number is required.");
        }
        if (request.getQuantity() == null || request.getQuantity().compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Stock-out quantity must be greater than zero.");
        }

        ProductReport report = productReportRepository.findById(request.getReportNumber())
                .orElseThrow(
                        () -> new IllegalArgumentException("Product report not found: " + request.getReportNumber()));

        String reportType = report.getReportType();
        if (!"DAMAGED".equals(reportType) && !"NEAR_EXPIRY".equals(reportType) && !"QUALITY_ISSUE".equals(reportType)) {
            throw new IllegalArgumentException("Report type is not eligible for stock-out: " + reportType);
        }

        if (!"APPROVED".equals(report.getStatus())) {
            throw new IllegalArgumentException("Product report is not approved for stock-out.");
        }
        if (report.getResolvedAt() != null) {
            throw new IllegalArgumentException("Stock-out has already been recorded for this report.");
        }

        Integer productNumber = report.getProductNumber();
        BigDecimal quantityToStockOut = request.getQuantity();

        Inventory inventory = inventoryRepository.findByIdForUpdate(productNumber)
                .orElseThrow(
                        () -> new IllegalArgumentException("Inventory record not found for product: " + productNumber));

        BigDecimal availableQty = inventory.getAvailableQuantity() != null ? inventory.getAvailableQuantity()
                : BigDecimal.ZERO;
        if (availableQty.compareTo(quantityToStockOut) < 0) {
            throw new IllegalArgumentException("Insufficient inventory to record stock-out. Available: "
                    + availableQty + ", Requested: " + quantityToStockOut);
        }

        List<StockInDetail> availableBatches = stockInDetailRepository.findLatestStockInDetails(productNumber);
        BigDecimal remainingToDeduct = quantityToStockOut;

        UUID createdBy = null;
        if (request.getCreatedBy() != null && !request.getCreatedBy().trim().isEmpty()) {
            createdBy = UUID.fromString(request.getCreatedBy());
        } else {
            createdBy = getDefaultUserId();
        }

        StockOut stockOut = StockOut.builder()
                .createdBy(createdBy)
                .reason(request.getReason() != null ? request.getReason()
                        : "Stock-out for report #" + request.getReportNumber())
                .createdDate(LocalDateTime.now())
                .build();
        stockOut = stockOutRepository.save(stockOut);
        Integer stockOutNumber = stockOut.getStockOutNumber();

        for (StockInDetail batch : availableBatches) {
            if (remainingToDeduct.compareTo(BigDecimal.ZERO) <= 0) {
                break;
            }

            BigDecimal batchRemaining = batch.getRemainingQuantity() != null ? batch.getRemainingQuantity()
                    : BigDecimal.ZERO;
            if (batchRemaining.compareTo(BigDecimal.ZERO) <= 0) {
                continue;
            }

            BigDecimal deductAmount;
            if (batchRemaining.compareTo(remainingToDeduct) >= 0) {
                deductAmount = remainingToDeduct;
                batch.setRemainingQuantity(batchRemaining.subtract(deductAmount));
                remainingToDeduct = BigDecimal.ZERO;
            } else {
                deductAmount = batchRemaining;
                batch.setRemainingQuantity(BigDecimal.ZERO);
                remainingToDeduct = remainingToDeduct.subtract(deductAmount);
            }

            stockInDetailRepository.save(batch);

            StockOutDetail detail = StockOutDetail.builder()
                    .stockOutNumber(stockOutNumber)
                    .stockInDetailNumber(batch.getStockInDetailNumber())
                    .productNumber(productNumber)
                    .quantity(deductAmount)
                    .build();
            stockOutDetailRepository.save(detail);
        }

        if (remainingToDeduct.compareTo(BigDecimal.ZERO) > 0) {
            throw new IllegalArgumentException("Insufficient batch inventory. Missing quantity: " + remainingToDeduct);
        }

        BigDecimal totalQty = inventory.getTotalQuantity() != null ? inventory.getTotalQuantity() : BigDecimal.ZERO;
        inventory.setAvailableQuantity(availableQty.subtract(quantityToStockOut));
        inventory.setTotalQuantity(totalQty.subtract(quantityToStockOut));
        inventory.setLastUpdated(LocalDateTime.now());
        inventoryRepository.save(inventory);

        InventoryTransaction tx = InventoryTransaction.builder()
                .product(productRepository.findById(productNumber).orElse(null))
                .type("OUT")
                .quantity(quantityToStockOut)
                .referenceType("STOCK_OUT")
                .referenceId(stockOutNumber)
                .reason(request.getNotes() != null && !request.getNotes().trim().isEmpty()
                        ? request.getNotes()
                        : (request.getReason() != null ? request.getReason()
                                : "Stock-out from report #" + request.getReportNumber()))
                .createdBy(createdBy)
                .createdAt(LocalDateTime.now())
                .build();
        inventoryTransactionRepository.save(tx);

        report.setResolvedBy(createdBy);
        report.setResolvedAt(LocalDateTime.now());
        productReportRepository.save(report);
    }

    @Transactional(readOnly = true)
    public List<PurchaseRequestListDTO> getPurchaseRequests() {
        String sql = "SELECT pr.purchase_request_number, pr.status, pr.created_date, pr.approved_date, " +
                "p1.full_name as creator_name, p2.full_name as approver_name, " +
                "MAX(s.supplier_name) as supplier_name, " +
                "COALESCE(SUM(prd.requested_quantity), 0) as total_quantity, " +
                "COUNT(prd.purchase_request_detail_number) as total_items " +
                "FROM purchase_requests pr " +
                "LEFT JOIN profiles p1 ON pr.created_by = p1.user_id " +
                "LEFT JOIN profiles p2 ON pr.approved_by = p2.user_id " +
                "LEFT JOIN purchase_request_details prd ON pr.purchase_request_number = prd.purchase_request_number " +
                "LEFT JOIN product_suppliers ps ON prd.product_supplier_number = ps.product_supplier_number " +
                "LEFT JOIN suppliers s ON ps.supplier_number = s.supplier_number " +
                "GROUP BY pr.purchase_request_number, pr.status, pr.created_date, pr.approved_date, p1.full_name, p2.full_name "
                +
                "ORDER BY pr.created_date DESC";

        return jdbcTemplate.query(sql, (rs, rowNum) -> PurchaseRequestListDTO.builder()
                .purchaseRequestNumber(rs.getInt("purchase_request_number"))
                .createdBy(rs.getString("creator_name") != null ? rs.getString("creator_name") : "System")
                .status(rs.getString("status"))
                .createdDate(rs.getTimestamp("created_date") != null ? rs.getTimestamp("created_date").toLocalDateTime()
                        : null)
                .approvedBy(rs.getString("approver_name"))
                .approvedDate(
                        rs.getTimestamp("approved_date") != null ? rs.getTimestamp("approved_date").toLocalDateTime()
                                : null)
                .supplierName(rs.getString("supplier_name") != null ? rs.getString("supplier_name") : "Various")
                .totalQuantity(rs.getBigDecimal("total_quantity"))
                .totalItems(rs.getInt("total_items"))
                .build());
    }

    @Transactional(readOnly = true)
    public PurchaseRequestDetailDTO getPurchaseRequestDetails(Integer prNumber) {
        PurchaseRequest pr = purchaseRequestRepository.findById(prNumber)
                .orElseThrow(() -> new IllegalArgumentException("Purchase request not found: " + prNumber));

        String creatorName = "System";
        if (pr.getCreatedBy() != null) {
            try {
                creatorName = jdbcTemplate.queryForObject(
                        "SELECT COALESCE(full_name, 'System') FROM profiles WHERE user_id = ?",
                        String.class,
                        pr.getCreatedBy());
            } catch (Exception e) {
                // Ignore
            }
        }

        String approverName = null;
        if (pr.getApprovedBy() != null) {
            try {
                approverName = jdbcTemplate.queryForObject(
                        "SELECT full_name FROM profiles WHERE user_id = ?",
                        String.class,
                        pr.getApprovedBy());
            } catch (Exception e) {
                // Ignore
            }
        }

        List<PurchaseRequestDetail> details = purchaseRequestDetailRepository.findByPurchaseRequestNumber(prNumber);

        if (details.isEmpty()) {
            return PurchaseRequestDetailDTO.builder()
                    .purchaseRequestNumber(pr.getPurchaseRequestNumber())
                    .createdBy(creatorName)
                    .createdDate(pr.getCreatedDate())
                    .approvedBy(approverName)
                    .approvedDate(pr.getApprovedDate())
                    .status(pr.getStatus())
                    .expectedDeliveryDate(pr.getExpectedDeliveryDate())
                    .items(java.util.Collections.emptyList())
                    .build();
        }

        // Collect IDs needed
        List<Integer> productSupplierIds = details.stream()
                .map(PurchaseRequestDetail::getProductSupplierNumber)
                .collect(Collectors.toList());

        // Bulk load product-suppliers
        Map<Integer, ProductSupplier> psMap = productSupplierRepository.findAllById(productSupplierIds).stream()
                .collect(Collectors.toMap(ProductSupplier::getProductSupplierNumber, ps -> ps));

        List<Integer> productIds = psMap.values().stream()
                .map(ProductSupplier::getProductNumber)
                .distinct()
                .collect(Collectors.toList());

        List<Integer> supplierIds = psMap.values().stream()
                .map(ProductSupplier::getSupplierNumber)
                .distinct()
                .collect(Collectors.toList());

        // Bulk load products, inventories, and suppliers
        Map<Integer, Product> productMap = productRepository.findAllById(productIds).stream()
                .collect(Collectors.toMap(Product::getProductNumber, p -> p));

        Map<Integer, Inventory> inventoryMap = inventoryRepository.findAllById(productIds).stream()
                .collect(Collectors.toMap(Inventory::getProductNumber, inv -> inv));

        Map<Integer, String> supplierNameMap = supplierRepository.findAllById(supplierIds).stream()
                .collect(Collectors.toMap(Supplier::getSupplierNumber, Supplier::getSupplierName));

        List<PurchaseRequestItemDTO> items = details.stream().map(d -> {
            ProductSupplier prodSupplier = psMap.get(d.getProductSupplierNumber());
            if (prodSupplier == null) return null;

            Product p = productMap.get(prodSupplier.getProductNumber());
            if (p == null) return null;

            String unitName = p.getUnit() != null ? p.getUnit().getUnitName() : "Unit";
            String supplierName = supplierNameMap.getOrDefault(prodSupplier.getSupplierNumber(), "Unknown");
            Inventory inv = inventoryMap.get(p.getProductNumber());
            BigDecimal stock = inv != null ? inv.getAvailableQuantity() : BigDecimal.ZERO;

            return PurchaseRequestItemDTO.builder()
                    .productNumber(p.getProductNumber())
                    .productName(p.getProductName())
                    .sku(p.getBarcode())
                    .requestedQuantity(d.getRequestedQuantity())
                    .importPrice(prodSupplier.getImportPrice())
                    .unitName(unitName)
                    .supplierName(supplierName)
                    .reason(d.getReason())
                    .notes(d.getNotes())
                    .currentStock(stock)
                    .reorderLevel(p.getReorderLevel() != null ? p.getReorderLevel() : BigDecimal.ZERO)
                    .build();
        }).filter(item -> item != null).collect(Collectors.toList());

        return PurchaseRequestDetailDTO.builder()
                .purchaseRequestNumber(pr.getPurchaseRequestNumber())
                .createdBy(creatorName)
                .createdDate(pr.getCreatedDate())
                .approvedBy(approverName)
                .approvedDate(pr.getApprovedDate())
                .status(pr.getStatus())
                .expectedDeliveryDate(pr.getExpectedDeliveryDate())
                .items(items)
                .build();
    }

    @Transactional
    public void submitPurchaseRequest(Integer prNumber) {
        PurchaseRequest pr = purchaseRequestRepository.findById(prNumber)
                .orElseThrow(() -> new IllegalArgumentException("Purchase request not found: " + prNumber));

        if (!"DRAFT".equals(pr.getStatus())) {
            throw new IllegalArgumentException(
                    "Only DRAFT purchase requests can be submitted. Current status: " + pr.getStatus());
        }

        pr.setStatus("PENDING");
        purchaseRequestRepository.save(pr);
    }

    @Transactional(readOnly = true)
    public PurchaseRequestFormDataDTO getPurchaseRequestFormData() {
        // Load ALL data in bulk (4 queries total) to avoid N+1 problem
        Map<Integer, Supplier> supplierMap = supplierRepository.findAll().stream()
                .collect(Collectors.toMap(Supplier::getSupplierNumber, s -> s));

        List<SupplierDTO> activeSuppliersDTO = supplierMap.values().stream()
                .filter(s -> "ACTIVE".equals(s.getStatus()))
                .map(s -> SupplierDTO.builder()
                        .supplierNumber(s.getSupplierNumber())
                        .supplierName(s.getSupplierName())
                        .build())
                .collect(Collectors.toList());

        List<Product> activeProducts = productRepository.findAll().stream()
                .filter(p -> "ACTIVE".equals(p.getStatus()))
                .collect(Collectors.toList());

        // Bulk load all product-supplier mappings and group by productNumber
        Map<Integer, List<ProductSupplier>> productSupplierMap = productSupplierRepository.findAll().stream()
                .collect(Collectors.groupingBy(ProductSupplier::getProductNumber));

        // Bulk load all inventories and index by productNumber
        Map<Integer, Inventory> inventoryMap = inventoryRepository.findAll().stream()
                .collect(Collectors.toMap(Inventory::getProductNumber, inv -> inv));

        List<PurchaseRequestFormProductDTO> productDTOs = new java.util.ArrayList<>();
        for (Product p : activeProducts) {
            List<ProductSupplier> prodSuppliers = productSupplierMap.getOrDefault(p.getProductNumber(), java.util.Collections.emptyList());
            if (prodSuppliers.isEmpty()) {
                continue;
            }

            List<ProductSupplierInfoDTO> supplierInfos = prodSuppliers.stream()
                    .map(ps -> {
                        Supplier sup = supplierMap.get(ps.getSupplierNumber());
                        String supplierName = sup != null ? sup.getSupplierName() : "Unknown Supplier";
                        return ProductSupplierInfoDTO.builder()
                                .supplierNumber(ps.getSupplierNumber())
                                .supplierName(supplierName)
                                .importPrice(ps.getImportPrice())
                                .minimumOrderQuantity(ps.getMinimumOrderQuantity())
                                .build();
                    })
                    .collect(Collectors.toList());

            String unitName = p.getUnit() != null ? p.getUnit().getUnitName() : "Unit";
            Inventory inv = inventoryMap.get(p.getProductNumber());
            BigDecimal stock = inv != null ? inv.getAvailableQuantity() : BigDecimal.ZERO;

            productDTOs.add(PurchaseRequestFormProductDTO.builder()
                    .productNumber(p.getProductNumber())
                    .productName(p.getProductName())
                    .barcode(p.getBarcode())
                    .unitName(unitName)
                    .currentStock(stock)
                    .reorderLevel(p.getReorderLevel() != null ? p.getReorderLevel() : BigDecimal.ZERO)
                    .suppliers(supplierInfos)
                    .build());
        }

        return PurchaseRequestFormDataDTO.builder()
                .suppliers(activeSuppliersDTO)
                .products(productDTOs)
                .build();
    }

    @Transactional
    public PurchaseRequest saveDraftPurchaseRequest(UUID userId, PurchaseRequestSaveDraftDTO dto) {
        if (userId == null) {
            userId = getDefaultUserId();
        }

        final UUID finalUserId = userId;
        PurchaseRequest pr = purchaseRequestRepository.findByCreatedByAndStatus(finalUserId, "DRAFT")
                .orElseGet(() -> {
                    PurchaseRequest newPr = PurchaseRequest.builder()
                            .status("DRAFT")
                            .createdBy(finalUserId)
                            .createdDate(LocalDateTime.now())
                            .build();
                    return purchaseRequestRepository.save(newPr);
                });

        pr.setExpectedDeliveryDate(dto.getExpectedDeliveryDate());
        purchaseRequestRepository.save(pr);

        purchaseRequestDetailRepository.deleteByPurchaseRequestNumber(pr.getPurchaseRequestNumber());

        if (dto.getItems() != null) {
            for (PurchaseRequestSaveDraftItemDTO item : dto.getItems()) {
                ProductSupplier productSupplier = productSupplierRepository.findByProductNumber(item.getProductNumber()).stream()
                        .filter(ps -> ps.getSupplierNumber().equals(item.getSupplierNumber()))
                        .findFirst()
                        .orElseGet(() -> {
                            Product p = productRepository.findById(item.getProductNumber())
                                    .orElseThrow(() -> new IllegalArgumentException("Product not found: " + item.getProductNumber()));
                            BigDecimal importPrice = p.getSellingPrice() != null
                                    ? p.getSellingPrice().multiply(BigDecimal.valueOf(0.75))
                                    : BigDecimal.valueOf(10000);
                            ProductSupplier newPs = ProductSupplier.builder()
                                    .productNumber(item.getProductNumber())
                                    .supplierNumber(item.getSupplierNumber())
                                    .importPrice(importPrice)
                                    .minimumOrderQuantity(BigDecimal.valueOf(1))
                                    .build();
                            return productSupplierRepository.save(newPs);
                        });

                PurchaseRequestDetail detail = PurchaseRequestDetail.builder()
                        .purchaseRequestNumber(pr.getPurchaseRequestNumber())
                        .productSupplierNumber(productSupplier.getProductSupplierNumber())
                        .requestedQuantity(item.getRequestedQuantity())
                        .reason(item.getReason())
                        .notes(item.getNotes())
                        .build();
                purchaseRequestDetailRepository.save(detail);
            }
        }

        return pr;
    }
}
