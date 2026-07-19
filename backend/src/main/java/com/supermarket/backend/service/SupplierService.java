package com.supermarket.backend.service;

import com.supermarket.backend.dto.SupplierDTO;
import com.supermarket.backend.entity.Supplier;
import com.supermarket.backend.repository.SupplierRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class SupplierService {

    private final SupplierRepository supplierRepository;

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

    private SupplierDTO mapToDTO(Supplier supplier) {
        return SupplierDTO.builder()
                .supplierNumber(supplier.getSupplierNumber())
                .supplierName(supplier.getSupplierName())
                .phone(supplier.getPhone())
                .email(supplier.getEmail())
                .status(supplier.getStatus())
                .build();
    }
}
