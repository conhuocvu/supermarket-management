package com.supermarket.backend.service;

import com.supermarket.backend.dto.CategoryDTO;
import com.supermarket.backend.dto.InventoryProductDTO;
import com.supermarket.backend.dto.ProductCreateUpdateDTO;
import com.supermarket.backend.dto.UnitDTO;
import com.supermarket.backend.entity.*;
import com.supermarket.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
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

    @Transactional(readOnly = true)
    public Page<InventoryProductDTO> getProducts(String keyword, Integer categoryNumber, Pageable pageable) {
        Page<Product> productsPage = productRepository.findProducts(keyword, categoryNumber, pageable);
        
        return productsPage.map(p -> {
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
                .product(product)
                .totalQuantity(initialQty)
                .availableQuantity(initialQty)
                .lastUpdated(LocalDateTime.now())
                .build();
        inventoryRepository.save(inventory);

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
    }

    @Transactional(readOnly = true)
    public Page<InventoryProductDTO> searchInventoryProducts(String keyword, Integer categoryNumber, Pageable pageable) {
        Page<Product> productsPage = productRepository.findInventoryProductsByCriteria(keyword, categoryNumber, pageable);
        
        return productsPage.map(p -> {
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
}

