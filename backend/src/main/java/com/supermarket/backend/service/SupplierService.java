package com.supermarket.backend.service;

import com.supermarket.backend.dto.SupplierDTO;
import com.supermarket.backend.dto.SupplierProductDTO;
import com.supermarket.backend.dto.ProductAssignmentDTO;
import com.supermarket.backend.entity.Supplier;
import com.supermarket.backend.entity.Product;
import com.supermarket.backend.entity.ProductSupplier;
import com.supermarket.backend.repository.SupplierRepository;
import com.supermarket.backend.repository.ProductSupplierRepository;
import com.supermarket.backend.repository.ProductRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SupplierService {

    private final SupplierRepository supplierRepository;
    private final ProductSupplierRepository productSupplierRepository;
    private final ProductRepository productRepository;

    @Transactional(readOnly = true)
    public Page<SupplierDTO> getSuppliers(String keyword, String status, Pageable pageable) {
        String cleanKeyword = (keyword != null && !keyword.trim().isEmpty()) ? keyword.trim() : null;
        String cleanStatus = (status != null && !status.trim().isEmpty() && !status.equalsIgnoreCase("ALL")) ? status.trim().toUpperCase() : null;

        Page<Supplier> suppliers = supplierRepository.searchSuppliers(cleanKeyword, cleanStatus, pageable);
        return suppliers.map(this::mapToDTO);
    }

    @Transactional(readOnly = true)
    public SupplierDTO getSupplierById(Integer supplierNumber) {
        Supplier supplier = supplierRepository.findById(supplierNumber)
                .orElseThrow(() -> new RuntimeException("Supplier not found"));
        return mapToDTO(supplier);
    }

    @Transactional
    public SupplierDTO createSupplier(SupplierDTO supplierDTO) {
        if (supplierDTO.getSupplierName() == null || supplierDTO.getSupplierName().trim().isEmpty()) {
            throw new IllegalArgumentException("Supplier name is required");
        }

        Supplier supplier = Supplier.builder()
                .supplierName(supplierDTO.getSupplierName().trim())
                .phone(supplierDTO.getPhone() != null ? supplierDTO.getPhone().trim() : null)
                .email(supplierDTO.getEmail() != null ? supplierDTO.getEmail().trim() : null)
                .status(supplierDTO.getStatus() != null ? supplierDTO.getStatus().trim().toUpperCase() : "ACTIVE")
                .contactPerson(supplierDTO.getContactPerson() != null ? supplierDTO.getContactPerson().trim() : null)
                .address(supplierDTO.getAddress() != null ? supplierDTO.getAddress().trim() : null)
                .category(supplierDTO.getCategory() != null ? supplierDTO.getCategory().trim() : null)
                .notes(supplierDTO.getNotes() != null ? supplierDTO.getNotes().trim() : null)
                .build();

        supplier = supplierRepository.save(supplier);
        return mapToDTO(supplier);
    }

    @Transactional
    public SupplierDTO updateSupplier(Integer supplierNumber, SupplierDTO supplierDTO) {
        Supplier supplier = supplierRepository.findById(supplierNumber)
                .orElseThrow(() -> new RuntimeException("Supplier not found"));

        if (supplierDTO.getSupplierName() == null || supplierDTO.getSupplierName().trim().isEmpty()) {
            throw new IllegalArgumentException("Supplier name is required");
        }

        supplier.setSupplierName(supplierDTO.getSupplierName().trim());
        supplier.setPhone(supplierDTO.getPhone() != null ? supplierDTO.getPhone().trim() : null);
        supplier.setEmail(supplierDTO.getEmail() != null ? supplierDTO.getEmail().trim() : null);
        if (supplierDTO.getStatus() != null) {
            supplier.setStatus(supplierDTO.getStatus().trim().toUpperCase());
        }
        supplier.setContactPerson(supplierDTO.getContactPerson() != null ? supplierDTO.getContactPerson().trim() : null);
        supplier.setAddress(supplierDTO.getAddress() != null ? supplierDTO.getAddress().trim() : null);
        supplier.setCategory(supplierDTO.getCategory() != null ? supplierDTO.getCategory().trim() : null);
        supplier.setNotes(supplierDTO.getNotes() != null ? supplierDTO.getNotes().trim() : null);

        supplier = supplierRepository.save(supplier);
        return mapToDTO(supplier);
    }

    @Transactional
    public SupplierDTO updateSupplierStatus(Integer supplierNumber, String newStatus) {
        if (newStatus == null || newStatus.trim().isEmpty()) {
            throw new IllegalArgumentException("Status is required");
        }

        newStatus = newStatus.trim().toUpperCase();
        if (!newStatus.equals("ACTIVE") && !newStatus.equals("INACTIVE")) {
            throw new IllegalArgumentException("Invalid status value. Allowed values are ACTIVE or INACTIVE.");
        }

        Supplier supplier = supplierRepository.findById(supplierNumber)
                .orElseThrow(() -> new RuntimeException("Supplier not found"));

        supplier.setStatus(newStatus);
        supplier = supplierRepository.save(supplier);

        return mapToDTO(supplier);
    }

    @Transactional(readOnly = true)
    public List<SupplierProductDTO> getAssignedProducts(Integer supplierNumber) {
        if (!supplierRepository.existsById(supplierNumber)) {
            throw new RuntimeException("Supplier not found");
        }
        
        List<ProductSupplier> productSuppliers = productSupplierRepository.findBySupplierNumber(supplierNumber);
        return productSuppliers.stream().map(ps -> {
            Product product = productRepository.findById(ps.getProductNumber()).orElse(null);
            if (product == null) return null;
            return SupplierProductDTO.builder()
                    .productNumber(product.getProductNumber())
                    .productName(product.getProductName())
                    .barcode(product.getBarcode())
                    .categoryName(product.getCategory() != null ? product.getCategory().getCategoryName() : null)
                    .unitName(product.getUnit() != null ? product.getUnit().getUnitName() : null)
                    .sellingPrice(product.getSellingPrice())
                    .status(product.getStatus())
                    .imageUrl(product.getImageUrl())
                    .importPrice(ps.getImportPrice())
                    .minimumOrderQuantity(ps.getMinimumOrderQuantity())
                    .build();
        }).filter(dto -> dto != null).collect(Collectors.toList());
    }

    @Transactional
    public void assignProducts(Integer supplierNumber, List<ProductAssignmentDTO> assignments) {
        if (!supplierRepository.existsById(supplierNumber)) {
            throw new RuntimeException("Supplier not found");
        }

        productSupplierRepository.deleteBySupplierNumber(supplierNumber);

        if (assignments == null || assignments.isEmpty()) return;

        List<Integer> productNumbers = assignments.stream()
                .map(ProductAssignmentDTO::getProductNumber)
                .collect(Collectors.toList());

        List<Product> products = productRepository.findAllById(productNumbers);
        if (products.size() != productNumbers.size()) {
            List<Integer> foundIds = products.stream()
                    .map(Product::getProductNumber)
                    .collect(Collectors.toList());
            List<Integer> missingIds = productNumbers.stream()
                    .filter(id -> !foundIds.contains(id))
                    .collect(Collectors.toList());
            throw new RuntimeException("Products not found: " + missingIds);
        }

        List<ProductSupplier> psList = assignments.stream()
                .map(assignment -> ProductSupplier.builder()
                        .supplierNumber(supplierNumber)
                        .productNumber(assignment.getProductNumber())
                        .importPrice(assignment.getImportPrice())
                        .minimumOrderQuantity(assignment.getMinimumOrderQuantity())
                        .build())
                .collect(Collectors.toList());

        productSupplierRepository.saveAll(psList);
    }

    @Transactional
    public void updateImportPrices(Integer supplierNumber, List<ProductAssignmentDTO> assignments) {
        if (!supplierRepository.existsById(supplierNumber)) {
            throw new RuntimeException("Supplier not found");
        }

        if (assignments == null || assignments.isEmpty()) return;

        for (ProductAssignmentDTO assignment : assignments) {
            List<ProductSupplier> existing = productSupplierRepository.findBySupplierNumber(supplierNumber);
            Optional<ProductSupplier> match = existing.stream()
                    .filter(ps -> ps.getProductNumber().equals(assignment.getProductNumber()))
                    .findFirst();

            if (match.isPresent()) {
                ProductSupplier ps = match.get();
                ps.setImportPrice(assignment.getImportPrice());
                ps.setMinimumOrderQuantity(assignment.getMinimumOrderQuantity());
                productSupplierRepository.save(ps);
            } else {
                ProductSupplier ps = ProductSupplier.builder()
                        .supplierNumber(supplierNumber)
                        .productNumber(assignment.getProductNumber())
                        .importPrice(assignment.getImportPrice())
                        .minimumOrderQuantity(assignment.getMinimumOrderQuantity())
                        .build();
                productSupplierRepository.save(ps);
            }
        }
    }

    private SupplierDTO mapToDTO(Supplier supplier) {
        return SupplierDTO.builder()
                .supplierNumber(supplier.getSupplierNumber())
                .supplierName(supplier.getSupplierName())
                .phone(supplier.getPhone())
                .email(supplier.getEmail())
                .status(supplier.getStatus())
                .contactPerson(supplier.getContactPerson())
                .address(supplier.getAddress())
                .category(supplier.getCategory())
                .notes(supplier.getNotes())
                .build();
    }
}
