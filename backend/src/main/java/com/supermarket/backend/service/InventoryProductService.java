package com.supermarket.backend.service;

import com.supermarket.backend.dto.CategoryDTO;
import com.supermarket.backend.dto.InventoryProductDTO;
import com.supermarket.backend.dto.InventoryProductDetailDTO;
import com.supermarket.backend.dto.ProductCreateUpdateDTO;
import com.supermarket.backend.dto.ProductAdjustmentDTO;
import com.supermarket.backend.dto.ProductAdjustmentRequestDTO;
import com.supermarket.backend.dto.SupplierDTO;
import com.supermarket.backend.dto.UnitDTO;
import com.supermarket.backend.entity.*;
import com.supermarket.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class InventoryProductService {

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final ProductSupplierRepository productSupplierRepository;
    private final PurchaseRequestRepository purchaseRequestRepository;
    private final PurchaseRequestDetailRepository purchaseRequestDetailRepository;
    private final UnitRepository unitRepository;
    private final InventoryRepository inventoryRepository;
    private final StockInDetailRepository stockInDetailRepository;
    private final SupplierRepository supplierRepository;
    private final InventoryTransactionRepository inventoryTransactionRepository;

    @Transactional(readOnly = true)
    public Page<InventoryProductDTO> getProducts(String keyword, Integer categoryNumber, Pageable pageable) {
        Page<Product> productsPage = productRepository.findProducts(keyword, categoryNumber, pageable);
        List<Product> productsList = productsPage.getContent();
        
        List<Integer> productNumbers = productsList.stream()
                .map(Product::getProductNumber)
                .collect(Collectors.toList());
                
        Map<Integer, List<StockInDetail>> detailsMap = new java.util.HashMap<>();
        if (!productNumbers.isEmpty()) {
            List<StockInDetail> details = stockInDetailRepository.findActiveStockInDetailsByProductNumbers(productNumbers);
            detailsMap = details.stream().collect(Collectors.groupingBy(StockInDetail::getProductNumber));
        }
        
        final Map<Integer, List<StockInDetail>> finalDetailsMap = detailsMap;
        
        return productsPage.map(p -> {
            List<StockInDetail> pDetails = finalDetailsMap.getOrDefault(p.getProductNumber(), java.util.Collections.emptyList());
            LocalDate expiryDate = pDetails.isEmpty() ? null : pDetails.get(0).getExpiryDate();
            
            BigDecimal stock = BigDecimal.ZERO;
            if (p.getInventory() != null && p.getInventory().getAvailableQuantity() != null) {
                stock = p.getInventory().getAvailableQuantity();
            }
            
            String catName = p.getCategory() != null ? p.getCategory().getCategoryName() : "Uncategorized";
            String unitName = p.getUnit() != null ? p.getUnit().getUnitName() : "Unit";

            return InventoryProductDTO.builder()
                    .productNumber(p.getProductNumber())
                    .productName(p.getProductName())
                    .barcode(p.getBarcode())
                    .categoryName(catName)
                    .unitName(unitName)
                    .stock(stock)
                    .sellingPrice(p.getSellingPrice())
                    .reorderLevel(p.getReorderLevel())
                    .status(p.getStatus())
                    .description(p.getDescription())
                    .imageUrl(p.getImageUrl())
                    .expiryWarningDays(p.getExpiryWarningDays() != null ? p.getExpiryWarningDays() : 30)
                    .expiryDate(expiryDate)
                    .build();
        });
    }

    @Transactional(readOnly = true)
    public List<CategoryDTO> getActiveCategories() {
        List<Category> categories = categoryRepository.findByStatus("ACTIVE");
        return categories.stream()
                .map(c -> CategoryDTO.builder()
                        .categoryNumber(c.getCategoryNumber())
                        .categoryName(c.getCategoryName())
                        .status(c.getStatus())
                        .build())
                .collect(Collectors.toList());
    }

    @Transactional
    public void updateProductStatus(Integer productNumber, String status) {
        Product product = productRepository.findById(productNumber)
                .orElseThrow(() -> new IllegalArgumentException("Product not found with number: " + productNumber));
        product.setStatus(status);
        productRepository.save(product);
    }

    @Transactional
    public void createPurchaseRequest(List<Integer> productNumbers) {
        if (productNumbers == null || productNumbers.isEmpty()) {
            throw new IllegalArgumentException("Product list cannot be empty");
        }

        // 1. Create a new PurchaseRequest
        PurchaseRequest pr = PurchaseRequest.builder()
                .status("PENDING")
                .createdDate(LocalDateTime.now())
                .build();
        pr = purchaseRequestRepository.save(pr);

        // 2. Add details for each selected product
        for (Integer prodNum : productNumbers) {
            Product product = productRepository.findById(prodNum)
                    .orElseThrow(() -> new IllegalArgumentException("Product not found with ID: " + prodNum));

            if (!"ACTIVE".equals(product.getStatus())) {
                throw new IllegalArgumentException("Cannot create purchase request for inactive product: " + product.getProductName());
            }

            // Find mapping in product_suppliers or fallback to creating a default mapping to supplier 1
            List<ProductSupplier> suppliers = productSupplierRepository.findByProductNumber(prodNum);
            ProductSupplier supplier;
            if (suppliers.isEmpty()) {
                BigDecimal importPrice = product.getSellingPrice() != null
                        ? product.getSellingPrice().multiply(BigDecimal.valueOf(0.75))
                        : BigDecimal.valueOf(10000);
                supplier = ProductSupplier.builder()
                        .productNumber(prodNum)
                        .supplierNumber(1) // Default Supplier ID
                        .importPrice(importPrice)
                        .minimumOrderQuantity(BigDecimal.valueOf(10))
                        .build();
                supplier = productSupplierRepository.save(supplier);
            } else {
                supplier = suppliers.get(0);
            }

            // Calculate requested quantity dynamically: (Reorder Level - Stock) or Supplier Min Qty, whichever is higher
            BigDecimal stock = BigDecimal.ZERO;
            if (product.getInventory() != null && product.getInventory().getAvailableQuantity() != null) {
                stock = product.getInventory().getAvailableQuantity();
            }
            BigDecimal reorderLevel = product.getReorderLevel() != null ? product.getReorderLevel() : BigDecimal.ZERO;
            BigDecimal needed = reorderLevel.subtract(stock);

            BigDecimal requestedQty = needed;
            BigDecimal minQty = supplier.getMinimumOrderQuantity() != null ? supplier.getMinimumOrderQuantity() : BigDecimal.valueOf(10);
            if (requestedQty.compareTo(BigDecimal.ZERO) <= 0) {
                requestedQty = minQty;
            } else if (requestedQty.compareTo(minQty) < 0) {
                requestedQty = minQty;
            }

            PurchaseRequestDetail detail = PurchaseRequestDetail.builder()
                    .purchaseRequestNumber(pr.getPurchaseRequestNumber())
                    .productSupplierNumber(supplier.getProductSupplierNumber())
                    .requestedQuantity(requestedQty)
                    .build();
            purchaseRequestDetailRepository.save(detail);
        }
    }

    @Transactional
    public PurchaseRequest addProductsToPurchaseRequest(UUID userId, List<Integer> productNumbers) {
        if (productNumbers == null || productNumbers.isEmpty()) {
            throw new IllegalArgumentException("Danh sách sản phẩm không được trống");
        }

        if (userId == null) {
            userId = UUID.fromString("e3b3ec4a-da0b-40f5-9747-29361993892b");
        }

        final UUID finalUserId = userId;
        PurchaseRequest pr = purchaseRequestRepository.findByCreatedByAndStatus(finalUserId, "PENDING")
                .orElseGet(() -> {
                    PurchaseRequest newPr = PurchaseRequest.builder()
                            .status("PENDING")
                            .createdBy(finalUserId)
                            .createdDate(LocalDateTime.now())
                            .build();
                    return purchaseRequestRepository.save(newPr);
                });

        List<PurchaseRequestDetail> existingDetails = purchaseRequestDetailRepository.findByPurchaseRequestNumber(pr.getPurchaseRequestNumber());
        java.util.Set<Integer> existingSupplierNumbers = existingDetails.stream()
                .map(PurchaseRequestDetail::getProductSupplierNumber)
                .collect(Collectors.toSet());

        for (Integer prodNum : productNumbers) {
            Product product = productRepository.findById(prodNum)
                    .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy sản phẩm có mã: " + prodNum));

            if (!"ACTIVE".equals(product.getStatus())) {
                throw new IllegalArgumentException("Không thể tạo yêu cầu mua hàng cho sản phẩm đã ngừng hoạt động (Inactive): " + product.getProductName());
            }

            List<ProductSupplier> suppliers = productSupplierRepository.findByProductNumber(prodNum);
            ProductSupplier supplier;
            if (suppliers.isEmpty()) {
                BigDecimal importPrice = product.getSellingPrice() != null
                        ? product.getSellingPrice().multiply(BigDecimal.valueOf(0.75))
                        : BigDecimal.valueOf(10000);
                supplier = ProductSupplier.builder()
                        .productNumber(prodNum)
                        .supplierNumber(1)
                        .importPrice(importPrice)
                        .minimumOrderQuantity(BigDecimal.valueOf(10))
                        .build();
                supplier = productSupplierRepository.save(supplier);
            } else {
                supplier = suppliers.get(0);
            }

            if (existingSupplierNumbers.contains(supplier.getProductSupplierNumber())) {
                continue;
            }

            BigDecimal stock = BigDecimal.ZERO;
            if (product.getInventory() != null && product.getInventory().getAvailableQuantity() != null) {
                stock = product.getInventory().getAvailableQuantity();
            }
            BigDecimal reorderLevel = product.getReorderLevel() != null ? product.getReorderLevel() : BigDecimal.ZERO;
            BigDecimal needed = reorderLevel.subtract(stock);

            BigDecimal requestedQty = needed;
            BigDecimal minQty = supplier.getMinimumOrderQuantity() != null ? supplier.getMinimumOrderQuantity() : BigDecimal.valueOf(10);
            if (requestedQty.compareTo(BigDecimal.ZERO) <= 0 || requestedQty.compareTo(minQty) < 0) {
                requestedQty = minQty;
            }

            PurchaseRequestDetail detail = PurchaseRequestDetail.builder()
                    .purchaseRequestNumber(pr.getPurchaseRequestNumber())
                    .productSupplierNumber(supplier.getProductSupplierNumber())
                    .requestedQuantity(requestedQty)
                    .build();
            purchaseRequestDetailRepository.save(detail);
        }

        return pr;
    }


    @Transactional(readOnly = true)
    public List<UnitDTO> getActiveUnits() {
        List<Unit> units = unitRepository.findAll();
        return units.stream()
                .map(u -> UnitDTO.builder()
                        .unitNumber(u.getUnitNumber())
                        .unitName(u.getUnitName())
                        .build())
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<SupplierDTO> getActiveSuppliers() {
        return supplierRepository.findAll().stream()
                .filter(s -> "ACTIVE".equals(s.getStatus()))
                .map(s -> SupplierDTO.builder()
                        .supplierNumber(s.getSupplierNumber())
                        .supplierName(s.getSupplierName())
                        .build())
                .collect(Collectors.toList());
    }

    @Transactional
    public Product createProduct(ProductCreateUpdateDTO dto) {
        if (productRepository.existsByBarcode(dto.getBarcode())) {
            throw new IllegalArgumentException("Mã vạch này đã tồn tại trên hệ thống");
        }

        Product product = Product.builder()
                .productName(dto.getProductName())
                .barcode(dto.getBarcode())
                .categoryNumber(dto.getCategoryNumber())
                .inventoryUnitNumber(dto.getInventoryUnitNumber())
                .sellingPrice(dto.getSellingPrice())
                .reorderLevel(dto.getReorderLevel())
                .status(dto.getStatus() != null ? dto.getStatus() : "ACTIVE")
                .description(dto.getDescription())
                .imageUrl(dto.getImageUrl())
                .expiryWarningDays(dto.getExpiryWarningDays() != null ? dto.getExpiryWarningDays() : 30)
                .build();
        product = productRepository.save(product);

        BigDecimal initialQty = dto.getInitialQuantity() != null ? dto.getInitialQuantity() : BigDecimal.ZERO;
        Inventory inventory = Inventory.builder()
                .productNumber(product.getProductNumber())
                .totalQuantity(initialQty)
                .availableQuantity(initialQty)
                .lastUpdated(LocalDateTime.now())
                .build();
        inventoryRepository.save(inventory);

        if (dto.getSupplierNumber() != null) {
            ProductSupplier ps = ProductSupplier.builder()
                    .productNumber(product.getProductNumber())
                    .supplierNumber(dto.getSupplierNumber())
                    .importPrice(product.getSellingPrice() != null ? product.getSellingPrice().multiply(BigDecimal.valueOf(0.7)) : BigDecimal.ZERO)
                    .minimumOrderQuantity(BigDecimal.valueOf(10))
                    .build();
            productSupplierRepository.save(ps);
        }

        return product;
    }

    @Transactional
    public void updateProduct(Integer productNumber, ProductCreateUpdateDTO dto) {
        Product product = productRepository.findById(productNumber)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy sản phẩm có mã: " + productNumber));

        Product existingWithBarcode = productRepository.findByBarcode(dto.getBarcode());
        if (existingWithBarcode != null && !existingWithBarcode.getProductNumber().equals(productNumber)) {
            throw new IllegalArgumentException("Mã vạch này đã được sử dụng bởi sản phẩm khác");
        }

        product.setProductName(dto.getProductName());
        product.setBarcode(dto.getBarcode());
        product.setCategoryNumber(dto.getCategoryNumber());
        product.setInventoryUnitNumber(dto.getInventoryUnitNumber());
        product.setSellingPrice(dto.getSellingPrice());
        product.setReorderLevel(dto.getReorderLevel());
        if (dto.getStatus() != null) {
            product.setStatus(dto.getStatus());
        }
        product.setDescription(dto.getDescription());
        product.setImageUrl(dto.getImageUrl());
        product.setExpiryWarningDays(dto.getExpiryWarningDays() != null ? dto.getExpiryWarningDays() : 30);

        productRepository.save(product);

        if (dto.getSupplierNumber() != null) {
            List<ProductSupplier> existing = productSupplierRepository.findByProductNumber(productNumber);
            if (!existing.isEmpty()) {
                ProductSupplier ps = existing.get(0);
                ps.setSupplierNumber(dto.getSupplierNumber());
                productSupplierRepository.save(ps);
            } else {
                ProductSupplier ps = ProductSupplier.builder()
                        .productNumber(productNumber)
                        .supplierNumber(dto.getSupplierNumber())
                        .importPrice(product.getSellingPrice() != null ? product.getSellingPrice().multiply(BigDecimal.valueOf(0.7)) : BigDecimal.ZERO)
                        .minimumOrderQuantity(BigDecimal.valueOf(10))
                        .build();
                productSupplierRepository.save(ps);
            }
        }
    }

    @Transactional(readOnly = true)
    public Page<InventoryProductDTO> searchInventoryProducts(String keyword, Integer categoryNumber, Pageable pageable) {
        Page<Product> productsPage = productRepository.findInventoryProductsByCriteria(keyword, categoryNumber, pageable);
        List<Product> productsList = productsPage.getContent();
        
        List<Integer> productNumbers = productsList.stream()
                .map(Product::getProductNumber)
                .collect(Collectors.toList());
                
        Map<Integer, List<StockInDetail>> detailsMap = new java.util.HashMap<>();
        if (!productNumbers.isEmpty()) {
            List<StockInDetail> details = stockInDetailRepository.findActiveStockInDetailsByProductNumbers(productNumbers);
            detailsMap = details.stream().collect(Collectors.groupingBy(StockInDetail::getProductNumber));
        }
        
        final Map<Integer, List<StockInDetail>> finalDetailsMap = detailsMap;
        
        return productsPage.map(p -> {
            List<StockInDetail> pDetails = finalDetailsMap.getOrDefault(p.getProductNumber(), java.util.Collections.emptyList());
            LocalDate expiryDate = pDetails.isEmpty() ? null : pDetails.get(0).getExpiryDate();
            
            BigDecimal stock = BigDecimal.ZERO;
            if (p.getInventory() != null && p.getInventory().getAvailableQuantity() != null) {
                stock = p.getInventory().getAvailableQuantity();
            }
            
            String catName = p.getCategory() != null ? p.getCategory().getCategoryName() : "Uncategorized";
            String unitName = p.getUnit() != null ? p.getUnit().getUnitName() : "Unit";

            return InventoryProductDTO.builder()
                    .productNumber(p.getProductNumber())
                    .productName(p.getProductName())
                    .barcode(p.getBarcode())
                    .categoryName(catName)
                    .unitName(unitName)
                    .stock(stock)
                    .sellingPrice(p.getSellingPrice())
                    .reorderLevel(p.getReorderLevel())
                    .status(p.getStatus())
                    .description(p.getDescription())
                    .imageUrl(p.getImageUrl())
                    .expiryWarningDays(p.getExpiryWarningDays() != null ? p.getExpiryWarningDays() : 30)
                    .expiryDate(expiryDate)
                    .build();
        });
    }

    @Transactional
    public void softDeleteProduct(Integer productNumber) {
        Product product = productRepository.findById(productNumber)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy sản phẩm có mã: " + productNumber));
        product.setStatus("DELETED");
        productRepository.save(product);
    }

    @Transactional(readOnly = true)
    public List<InventoryProductDTO> getProductsByWarning(String warningType) {
        debugLog("getProductsByWarning (OPTIMIZED) called with: " + warningType, true);
        
        Page<Product> productsPage = productRepository.findProducts("", null, Pageable.unpaged());
        List<Product> products = productsPage.getContent();
        debugLog("findAll returned products: " + products.size(), false);

        List<StockInDetail> allActiveDetails = stockInDetailRepository.findAllActiveStockInDetails();
        debugLog("Fetch active stock-in details query finished. Size: " + allActiveDetails.size(), false);

        Map<Integer, List<StockInDetail>> detailsMap = allActiveDetails.stream()
                .collect(Collectors.groupingBy(
                        StockInDetail::getProductNumber,
                        java.util.LinkedHashMap::new,
                        Collectors.toList()
                ));

        List<InventoryProductDTO> result = new ArrayList<>();
        LocalDate now = LocalDate.now();

        for (Product p : products) {
            debugLog("Processing product ID: " + p.getProductNumber() + " (" + p.getProductName() + ")", false);
            if ("DELETED".equals(p.getStatus())) {
                debugLog("  Deleted status, skipping", false);
                continue;
            }

            Inventory inv = p.getInventory();
            debugLog("  Fetched inventory: " + (inv != null), false);
            BigDecimal stock = BigDecimal.ZERO;
            if (inv != null && inv.getAvailableQuantity() != null) {
                stock = inv.getAvailableQuantity();
            }
            debugLog("  Stock: " + stock, false);

            List<StockInDetail> details = detailsMap.getOrDefault(p.getProductNumber(), java.util.Collections.emptyList());
            debugLog("  Fetched details: " + details.size(), false);
            LocalDate expiryDate = null;
            if (!details.isEmpty()) {
                expiryDate = details.get(0).getExpiryDate();
            }
            debugLog("  Expiry date: " + expiryDate, false);

            boolean isLowStock = false;
            if (p.getReorderLevel() != null && stock.compareTo(p.getReorderLevel()) <= 0) {
                isLowStock = true;
            }

            boolean isNearExpiry = false;
            boolean isExpired = false;
            if (expiryDate != null) {
                if (expiryDate.isBefore(now)) {
                    isExpired = true;
                } else {
                    int warningDays = p.getExpiryWarningDays() != null ? p.getExpiryWarningDays() : 30;
                    if (!expiryDate.isAfter(now.plusDays(warningDays))) {
                        isNearExpiry = true;
                    }
                }
            }
            debugLog("  isLowStock: " + isLowStock + ", isNearExpiry: " + isNearExpiry + ", isExpired: " + isExpired, false);

            boolean match = false;
            if ("ALL".equalsIgnoreCase(warningType)) {
                match = isLowStock || isNearExpiry || isExpired;
            } else if ("LOW_STOCK".equalsIgnoreCase(warningType)) {
                match = isLowStock;
            } else if ("NEAR_EXPIRY".equalsIgnoreCase(warningType)) {
                match = isNearExpiry;
            } else if ("EXPIRED".equalsIgnoreCase(warningType)) {
                match = isExpired;
            }
            debugLog("  Match result: " + match, false);

            if (match) {
                String catName = p.getCategory() != null ? p.getCategory().getCategoryName() : "Uncategorized";
                String unitName = p.getUnit() != null ? p.getUnit().getUnitName() : "Unit";

                result.add(InventoryProductDTO.builder()
                        .productNumber(p.getProductNumber())
                        .productName(p.getProductName())
                        .barcode(p.getBarcode())
                        .categoryName(catName)
                        .unitName(unitName)
                        .stock(stock)
                        .sellingPrice(p.getSellingPrice())
                        .reorderLevel(p.getReorderLevel())
                        .status(p.getStatus())
                        .description(p.getDescription())
                        .imageUrl(p.getImageUrl())
                        .expiryWarningDays(p.getExpiryWarningDays() != null ? p.getExpiryWarningDays() : 30)
                        .expiryDate(expiryDate)
                        .build());
                debugLog("  Added DTO to result", false);
            }
        }
        debugLog("getProductsByWarning finished. Returning result size: " + result.size(), false);
        return result;
    }

    @Transactional(readOnly = true)
    public InventoryProductDetailDTO getProductDetails(int productNumber) {
        Product p = productRepository.findById(productNumber)
                .orElseThrow(() -> new IllegalArgumentException("Product not found with ID: " + productNumber));

        List<StockInDetail> pDetails = stockInDetailRepository.findActiveStockInDetailsByProductNumbers(
                java.util.Collections.singletonList(productNumber));
        LocalDate expiryDate = pDetails.isEmpty() ? null : pDetails.get(0).getExpiryDate();

        BigDecimal stock = BigDecimal.ZERO;
        if (p.getInventory() != null && p.getInventory().getAvailableQuantity() != null) {
            stock = p.getInventory().getAvailableQuantity();
        }

        String catName = p.getCategory() != null ? p.getCategory().getCategoryName() : "Uncategorized";
        String unitName = p.getUnit() != null ? p.getUnit().getUnitName() : "Unit";

        String supplierName = "N/A";
        BigDecimal importPrice = null;
        BigDecimal minOrderQty = null;
        Integer supplierNumber = null;

        List<ProductSupplier> prodSuppliers = productSupplierRepository.findByProductNumber(productNumber);
        if (!prodSuppliers.isEmpty()) {
            ProductSupplier ps = prodSuppliers.get(0);
            importPrice = ps.getImportPrice();
            minOrderQty = ps.getMinimumOrderQuantity();
            supplierNumber = ps.getSupplierNumber();

            Optional<Supplier> sOpt = supplierRepository.findById(ps.getSupplierNumber());
            if (sOpt.isPresent()) {
                supplierName = sOpt.get().getSupplierName();
            }
        }

        List<InventoryTransaction> transactions = inventoryTransactionRepository.findByProductProductNumberOrderByCreatedAtDesc(productNumber);
        List<InventoryProductDetailDTO.StockHistoryDTO> stockHistory = new ArrayList<>();
        for (InventoryTransaction t : transactions) {
            String actionName = "Adjustment";
            if ("IN".equals(t.getType())) {
                actionName = "Inbound Restock";
            } else if ("OUT".equals(t.getType())) {
                actionName = t.getReferenceType() != null ? t.getReferenceType() : "Stock Out";
                if ("SALE".equals(actionName) && t.getReferenceId() != null) {
                    actionName = "Order #" + t.getReferenceId();
                }
            }

            BigDecimal qty = t.getQuantity();
            if ("OUT".equals(t.getType())) {
                qty = qty.negate();
            }

            stockHistory.add(InventoryProductDetailDTO.StockHistoryDTO.builder()
                    .date(t.getCreatedAt().toLocalDate().toString())
                    .action(actionName)
                    .quantity(qty)
                    .build());
        }

        return InventoryProductDetailDTO.builder()
                .productNumber(p.getProductNumber())
                .productName(p.getProductName())
                .barcode(p.getBarcode())
                .categoryName(catName)
                .unitName(unitName)
                .stock(stock)
                .sellingPrice(p.getSellingPrice())
                .reorderLevel(p.getReorderLevel())
                .status(p.getStatus())
                .description(p.getDescription() != null ? p.getDescription() : "")
                .imageUrl(p.getImageUrl() != null ? p.getImageUrl() : "")
                .expiryWarningDays(p.getExpiryWarningDays() != null ? p.getExpiryWarningDays() : 30)
                .expiryDate(expiryDate)
                .supplierNumber(supplierNumber)
                .supplierName(supplierName)
                .importPrice(importPrice)
                .minimumOrderQuantity(minOrderQty)
                .stockHistory(stockHistory)
                .build();
    }

    @Transactional(readOnly = true)
    public ProductAdjustmentDTO getProductForAdjustment(int productNumber) {
        Product p = productRepository.findById(productNumber)
                .orElseThrow(() -> new IllegalArgumentException("Product not found with ID: " + productNumber));

        Inventory inv = inventoryRepository.findById(productNumber)
                .orElseThrow(() -> new IllegalArgumentException("Inventory record not found for product: " + productNumber));

        String unitName = p.getUnit() != null ? p.getUnit().getUnitName() : "Unit";

        return ProductAdjustmentDTO.builder()
                .productNumber(p.getProductNumber())
                .productName(p.getProductName())
                .barcode(p.getBarcode())
                .unitName(unitName)
                .availableQuantity(inv.getAvailableQuantity())
                .build();
    }

    @Transactional
    public ProductAdjustmentDTO adjustProductQuantity(int productNumber, String adjustmentType, BigDecimal quantity, String reason) {
        if (quantity == null || quantity.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Adjustment quantity must be greater than zero.");
        }

        Product p = productRepository.findById(productNumber)
                .orElseThrow(() -> new IllegalArgumentException("Product not found with ID: " + productNumber));

        Inventory inv = inventoryRepository.findByIdForUpdate(productNumber)
                .orElseThrow(() -> new IllegalArgumentException("Inventory record not found for product: " + productNumber));

        BigDecimal currentAvailable = inv.getAvailableQuantity() != null ? inv.getAvailableQuantity() : BigDecimal.ZERO;
        BigDecimal currentTotal = inv.getTotalQuantity() != null ? inv.getTotalQuantity() : BigDecimal.ZERO;

        BigDecimal newAvailable;
        BigDecimal newTotal;

        if ("INCREASE".equalsIgnoreCase(adjustmentType)) {
            newAvailable = currentAvailable.add(quantity);
            newTotal = currentTotal.add(quantity);
        } else if ("DECREASE".equalsIgnoreCase(adjustmentType)) {
            if (currentAvailable.compareTo(quantity) < 0) {
                throw new IllegalArgumentException("Inventory quantity cannot be negative.");
            }
            newAvailable = currentAvailable.subtract(quantity);
            newTotal = currentTotal.subtract(quantity);
        } else {
            throw new IllegalArgumentException("Invalid adjustment type. Must be INCREASE or DECREASE.");
        }

        inv.setAvailableQuantity(newAvailable);
        inv.setTotalQuantity(newTotal);
        inv.setLastUpdated(LocalDateTime.now());
        Inventory savedInventory = inventoryRepository.save(inv);

        // Record transaction history
        InventoryTransaction transaction = InventoryTransaction.builder()
                .product(p)
                .type("INCREASE".equalsIgnoreCase(adjustmentType) ? "IN" : "OUT")
                .quantity(quantity)
                .referenceType("ADJUSTMENT")
                .reason(reason)
                .createdAt(LocalDateTime.now())
                .build();
        inventoryTransactionRepository.save(transaction);

        String unitName = p.getUnit() != null ? p.getUnit().getUnitName() : "Unit";

        return ProductAdjustmentDTO.builder()
                .productNumber(p.getProductNumber())
                .productName(p.getProductName())
                .barcode(p.getBarcode())
                .unitName(unitName)
                .availableQuantity(savedInventory.getAvailableQuantity())
                .build();
    }

    private void debugLog(String message, boolean reset) {
        try {
            java.nio.file.Path path = java.nio.file.Paths.get("d:/Ki 8/PRM393/supermarket-management-system/backend/debug.log");
            java.nio.file.StandardOpenOption option = reset ? java.nio.file.StandardOpenOption.TRUNCATE_EXISTING : java.nio.file.StandardOpenOption.APPEND;
            if (reset && !java.nio.file.Files.exists(path)) {
                java.nio.file.Files.createFile(path);
            }
            java.nio.file.Files.write(
                path,
                (message + "\n").getBytes(),
                java.nio.file.StandardOpenOption.WRITE,
                option
            );
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}

