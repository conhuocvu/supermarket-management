package com.supermarket.backend.service;

import com.supermarket.backend.dto.SupplierDTO;
import com.supermarket.backend.dto.SupplierProductDTO;
import com.supermarket.backend.dto.ProductAssignmentDTO;
import com.supermarket.backend.entity.Supplier;
import com.supermarket.backend.entity.Product;
import com.supermarket.backend.entity.ProductSupplier;
import com.supermarket.backend.entity.Unit;
import com.supermarket.backend.entity.Category;
import com.supermarket.backend.repository.SupplierRepository;
import com.supermarket.backend.repository.ProductSupplierRepository;
import com.supermarket.backend.repository.ProductRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class SupplierServiceTests {

    @Mock
    private SupplierRepository supplierRepository;

    @Mock
    private ProductSupplierRepository productSupplierRepository;

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private SupplierService supplierService;

    private Supplier supplier;
    private SupplierDTO supplierDTO;
    private Product product;
    private ProductSupplier productSupplier;

    @BeforeEach
    void setUp() {
        supplier = Supplier.builder()
                .supplierNumber(1)
                .supplierName("Coca Cola Vietnam")
                .phone("0123456789")
                .email("contact@coca-cola.vn")
                .status("ACTIVE")
                .contactPerson("Nguyen Van A")
                .address("Hanoi")
                .category("Beverages")
                .build();

        supplierDTO = SupplierDTO.builder()
                .supplierNumber(1)
                .supplierName("Coca Cola Vietnam")
                .phone("0123456789")
                .email("contact@coca-cola.vn")
                .status("ACTIVE")
                .contactPerson("Nguyen Van A")
                .address("Hanoi")
                .category("Beverages")
                .build();

        product = Product.builder()
                .productNumber(100)
                .productName("Coca Cola 320ml")
                .barcode("8930001001001")
                .category(Category.builder().categoryName("Drinks").build())
                .unit(Unit.builder().unitName("Can").build())
                .sellingPrice(BigDecimal.valueOf(10000))
                .status("ACTIVE")
                .build();

        productSupplier = ProductSupplier.builder()
                .productSupplierNumber(50)
                .supplierNumber(1)
                .productNumber(100)
                .importPrice(BigDecimal.valueOf(7000))
                .minimumOrderQuantity(BigDecimal.valueOf(10))
                .build();
    }

    @Test
    void testGetSuppliers_Success() {
        Pageable pageable = PageRequest.of(0, 10);
        Page<Supplier> supplierPage = new PageImpl<>(Collections.singletonList(supplier));

        when(supplierRepository.searchSuppliers(eq("Coca"), eq("ACTIVE"), eq(pageable))).thenReturn(supplierPage);

        Page<SupplierDTO> result = supplierService.getSuppliers("Coca", "ACTIVE", pageable);

        assertNotNull(result);
        assertEquals(1, result.getContent().size());
        assertEquals("Coca Cola Vietnam", result.getContent().get(0).getSupplierName());
    }

    @Test
    void testGetSupplierById_Success() {
        when(supplierRepository.findById(1)).thenReturn(Optional.of(supplier));

        SupplierDTO result = supplierService.getSupplierById(1);

        assertNotNull(result);
        assertEquals("Coca Cola Vietnam", result.getSupplierName());
    }

    @Test
    void testGetSupplierById_NotFound_ThrowsException() {
        when(supplierRepository.findById(99)).thenReturn(Optional.empty());

        assertThrows(RuntimeException.class, () -> supplierService.getSupplierById(99));
    }

    @Test
    void testCreateSupplier_Success() {
        when(supplierRepository.save(any(Supplier.class))).thenReturn(supplier);

        SupplierDTO result = supplierService.createSupplier(supplierDTO);

        assertNotNull(result);
        assertEquals("Coca Cola Vietnam", result.getSupplierName());
        verify(supplierRepository, times(1)).save(any(Supplier.class));
    }

    @Test
    void testCreateSupplier_MissingName_ThrowsException() {
        SupplierDTO invalidDTO = SupplierDTO.builder().supplierName("").build();

        assertThrows(IllegalArgumentException.class, () -> supplierService.createSupplier(invalidDTO));
        verify(supplierRepository, never()).save(any(Supplier.class));
    }

    @Test
    void testUpdateSupplier_Success() {
        when(supplierRepository.findById(1)).thenReturn(Optional.of(supplier));
        when(supplierRepository.save(any(Supplier.class))).thenReturn(supplier);

        SupplierDTO result = supplierService.updateSupplier(1, supplierDTO);

        assertNotNull(result);
        verify(supplierRepository, times(1)).save(any(Supplier.class));
    }

    @Test
    void testUpdateSupplierStatus_Success() {
        when(supplierRepository.findById(1)).thenReturn(Optional.of(supplier));
        when(supplierRepository.save(any(Supplier.class))).thenReturn(supplier);

        SupplierDTO result = supplierService.updateSupplierStatus(1, "INACTIVE");

        assertNotNull(result);
        verify(supplierRepository, times(1)).save(any(Supplier.class));
    }

    @Test
    void testUpdateSupplierStatus_InvalidStatus_ThrowsException() {
        assertThrows(IllegalArgumentException.class, () -> supplierService.updateSupplierStatus(1, "SUSPENDED"));
    }

    @Test
    void testGetAssignedProducts_Success() {
        when(supplierRepository.existsById(1)).thenReturn(true);
        when(productSupplierRepository.findBySupplierNumber(1)).thenReturn(Collections.singletonList(productSupplier));
        when(productRepository.findById(100)).thenReturn(Optional.of(product));

        List<SupplierProductDTO> result = supplierService.getAssignedProducts(1);

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("Coca Cola 320ml", result.get(0).getProductName());
        assertEquals(BigDecimal.valueOf(7000), result.get(0).getImportPrice());
    }

    @Test
    void testAssignProducts_Success() {
        when(supplierRepository.existsById(1)).thenReturn(true);
        when(productRepository.findAllById(Collections.singletonList(100))).thenReturn(Collections.singletonList(product));

        ProductAssignmentDTO assignment = ProductAssignmentDTO.builder()
                .productNumber(100)
                .importPrice(BigDecimal.valueOf(7000))
                .minimumOrderQuantity(BigDecimal.valueOf(10))
                .build();

        supplierService.assignProducts(1, Collections.singletonList(assignment));

        verify(productSupplierRepository, times(1)).deleteBySupplierNumber(1);
        verify(productSupplierRepository, times(1)).saveAll(anyList());
    }

    @Test
    void testUpdateImportPrices_Success() {
        when(supplierRepository.existsById(1)).thenReturn(true);
        when(productSupplierRepository.findBySupplierNumber(1)).thenReturn(Collections.singletonList(productSupplier));

        ProductAssignmentDTO assignment = ProductAssignmentDTO.builder()
                .productNumber(100)
                .importPrice(BigDecimal.valueOf(7200)) // updated price
                .minimumOrderQuantity(BigDecimal.valueOf(15)) // updated qty
                .build();

        supplierService.updateImportPrices(1, Collections.singletonList(assignment));

        verify(productSupplierRepository, times(1)).save(any(ProductSupplier.class));
    }
}
