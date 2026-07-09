package com.supermarket.backend.service;

import com.supermarket.backend.dto.*;
import com.supermarket.backend.model.*;
import com.supermarket.backend.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class SupplierService {

    private final SupplierRepository supplierRepository;
    private final ProductRepository productRepository;
    private final SupplierProductRepository supplierProductRepository;

    @Autowired
    public SupplierService(SupplierRepository supplierRepository,
                           ProductRepository productRepository,
                           SupplierProductRepository supplierProductRepository) {
        this.supplierRepository = supplierRepository;
        this.productRepository = productRepository;
        this.supplierProductRepository = supplierProductRepository;
    }

    @Transactional(readOnly = true)
    public List<SupplierDto> getAllSuppliers(String search, String category) {
        List<Supplier> suppliers = supplierRepository.searchSuppliers(search, category);
        return suppliers.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public SupplierDto getSupplierById(Long id) {
        Supplier supplier = supplierRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Supplier not found with id: " + id));
        return convertToDto(supplier);
    }

    @Transactional
    public SupplierDto createSupplier(SupplierCreateDto dto) {
        if (supplierRepository.existsByCodeIgnoreCase(dto.getCode())) {
            throw new IllegalArgumentException("Supplier with code " + dto.getCode() + " already exists.");
        }

        Supplier supplier = Supplier.builder()
                .code(dto.getCode())
                .name(dto.getName())
                .category(dto.getCategory())
                .nextDelivery(dto.getNextDelivery())
                .status(dto.getStatus() != null ? dto.getStatus() : "Reliable")
                .contactType(dto.getContactType())
                .contactValue(dto.getContactValue())
                .onTimeDeliveryRate(dto.getOnTimeDeliveryRate() != null ? dto.getOnTimeDeliveryRate() : 95.0)
                .averageRating(dto.getAverageRating() != null ? dto.getAverageRating() : 4.5)
                .notes(dto.getNotes())
                .certification(dto.getCertification())
                .build();

        Supplier saved = supplierRepository.save(supplier);
        return convertToDto(saved);
    }

    @Transactional
    public SupplierDto updateSupplier(Long id, SupplierCreateDto dto) {
        Supplier supplier = supplierRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Supplier not found with id: " + id));

        if (supplierRepository.existsByCodeIgnoreCaseAndIdNot(dto.getCode(), id)) {
            throw new IllegalArgumentException("Supplier with code " + dto.getCode() + " already exists.");
        }

        supplier.setCode(dto.getCode());
        supplier.setName(dto.getName());
        supplier.setCategory(dto.getCategory());
        supplier.setNextDelivery(dto.getNextDelivery());
        if (dto.getStatus() != null) {
            supplier.setStatus(dto.getStatus());
        }
        supplier.setContactType(dto.getContactType());
        supplier.setContactValue(dto.getContactValue());
        if (dto.getOnTimeDeliveryRate() != null) {
            supplier.setOnTimeDeliveryRate(dto.getOnTimeDeliveryRate());
        }
        if (dto.getAverageRating() != null) {
            supplier.setAverageRating(dto.getAverageRating());
        }
        supplier.setNotes(dto.getNotes());
        supplier.setCertification(dto.getCertification());

        Supplier saved = supplierRepository.save(supplier);
        return convertToDto(saved);
    }

    @Transactional
    public SupplierDto updateSupplierStatus(Long id, String status) {
        Supplier supplier = supplierRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Supplier not found with id: " + id));
        
        supplier.setStatus(status);
        Supplier saved = supplierRepository.save(supplier);
        return convertToDto(saved);
    }

    @Transactional(readOnly = true)
    public List<SupplierProductDto> getSupplierProducts(Long supplierId) {
        Supplier supplier = supplierRepository.findById(supplierId)
                .orElseThrow(() -> new IllegalArgumentException("Supplier not found with id: " + supplierId));

        // Get all products in the system
        List<Product> allProducts = productRepository.findAll();
        
        // Get all assigned products for this supplier
        List<SupplierProduct> assignedList = supplierProductRepository.findBySupplierId(supplierId);
        Map<Long, SupplierProduct> assignedMap = assignedList.stream()
                .collect(Collectors.toMap(sp -> sp.getProduct().getId(), sp -> sp));

        return allProducts.stream()
                .map(product -> {
                    SupplierProduct sp = assignedMap.get(product.getId());
                    boolean assigned = sp != null;
                    Double importPrice = assigned ? sp.getImportPrice() : product.getBasePrice();
                    Long mappingId = assigned ? sp.getId() : null;

                    return SupplierProductDto.builder()
                            .id(mappingId)
                            .productId(product.getId())
                            .sku(product.getSku())
                            .name(product.getName())
                            .category(product.getCategory())
                            .basePrice(product.getBasePrice())
                            .importPrice(importPrice)
                            .unit(product.getUnit())
                            .imageUrl(product.getImageUrl())
                            .assigned(assigned)
                            .build();
                })
                .collect(Collectors.toList());
    }

    @Transactional
    public List<SupplierProductDto> assignProducts(Long supplierId, List<SupplierProductAssignDto> assignments) {
        Supplier supplier = supplierRepository.findById(supplierId)
                .orElseThrow(() -> new IllegalArgumentException("Supplier not found with id: " + supplierId));

        // Clear existing product assignments
        supplierProductRepository.deleteBySupplierId(supplierId);
        supplierProductRepository.flush();

        // Create new assignments
        List<SupplierProduct> newMappings = new ArrayList<>();
        for (SupplierProductAssignDto assign : assignments) {
            Product product = productRepository.findById(assign.getProductId())
                    .orElseThrow(() -> new IllegalArgumentException("Product not found with id: " + assign.getProductId()));
            
            SupplierProduct sp = SupplierProduct.builder()
                    .supplier(supplier)
                    .product(product)
                    .importPrice(assign.getImportPrice())
                    .build();
            newMappings.add(sp);
        }

        supplierProductRepository.saveAll(newMappings);
        
        // Return updated list
        return getSupplierProducts(supplierId);
    }

    private SupplierDto convertToDto(Supplier supplier) {
        int skuCount = supplierProductRepository.countActiveSkusBySupplierId(supplier.getId());
        return SupplierDto.builder()
                .id(supplier.getId())
                .code(supplier.getCode())
                .name(supplier.getName())
                .category(supplier.getCategory())
                .nextDelivery(supplier.getNextDelivery())
                .status(supplier.getStatus())
                .contactType(supplier.getContactType())
                .contactValue(supplier.getContactValue())
                .onTimeDeliveryRate(supplier.getOnTimeDeliveryRate())
                .averageRating(supplier.getAverageRating())
                .notes(supplier.getNotes())
                .certification(supplier.getCertification())
                .activeSkus(skuCount)
                .build();
    }
}
