package com.supermarket.backend.service;

import com.supermarket.backend.dto.PurchaseRequestDetailDTO;
import com.supermarket.backend.dto.PurchaseRequestListDTO;
import com.supermarket.backend.entity.*;
import com.supermarket.backend.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class InventoryServicePurchaseRequestTests {

    @Mock
    private ProductRepository productRepository;
    @Mock
    private PurchaseRequestRepository purchaseRequestRepository;
    @Mock
    private PurchaseRequestDetailRepository purchaseRequestDetailRepository;
    @Mock
    private ProductSupplierRepository productSupplierRepository;
    @Mock
    private SupplierRepository supplierRepository;
    @Mock
    private JdbcTemplate jdbcTemplate;

    @InjectMocks
    private InventoryService inventoryService;

    private PurchaseRequest purchaseRequest;
    private PurchaseRequestDetail detail1;
    private ProductSupplier productSupplier;
    private Product product;
    private Supplier supplier;

    @BeforeEach
    void setUp() {
        UUID creatorId = UUID.randomUUID();
        UUID approverId = UUID.randomUUID();

        purchaseRequest = PurchaseRequest.builder()
                .purchaseRequestNumber(1)
                .createdBy(creatorId)
                .approvedBy(approverId)
                .status("APPROVED")
                .createdDate(LocalDateTime.now().minusDays(1))
                .approvedDate(LocalDateTime.now())
                .build();

        detail1 = PurchaseRequestDetail.builder()
                .purchaseRequestDetailNumber(10)
                .purchaseRequestNumber(1)
                .productSupplierNumber(5)
                .requestedQuantity(BigDecimal.valueOf(100))
                .build();

        productSupplier = ProductSupplier.builder()
                .productSupplierNumber(5)
                .productNumber(20)
                .supplierNumber(30)
                .importPrice(BigDecimal.valueOf(12.50))
                .build();

        product = Product.builder()
                .productNumber(20)
                .productName("Coca Cola")
                .barcode("8930001112223")
                .unit(Unit.builder().unitName("Can").build())
                .build();

        supplier = Supplier.builder()
                .supplierNumber(30)
                .supplierName("Coca Cola Vietnam")
                .build();
    }

    @Test
    void testGetPurchaseRequests_Success() {
        PurchaseRequestListDTO summary = PurchaseRequestListDTO.builder()
                .purchaseRequestNumber(1)
                .createdBy("Nguyen Van A")
                .status("APPROVED")
                .createdDate(LocalDateTime.now())
                .supplierName("Coca Cola Vietnam")
                .totalQuantity(BigDecimal.valueOf(100))
                .totalItems(1)
                .build();

        when(jdbcTemplate.query(anyString(), any(RowMapper.class))).thenReturn(Collections.singletonList(summary));

        List<PurchaseRequestListDTO> list = inventoryService.getPurchaseRequests();

        assertNotNull(list);
        assertEquals(1, list.size());
        assertEquals("APPROVED", list.get(0).getStatus());
        assertEquals("Coca Cola Vietnam", list.get(0).getSupplierName());
        assertEquals(BigDecimal.valueOf(100), list.get(0).getTotalQuantity());
    }

    @Test
    void testGetPurchaseRequestDetails_Success() {
        when(purchaseRequestRepository.findById(1)).thenReturn(Optional.of(purchaseRequest));
        when(purchaseRequestDetailRepository.findByPurchaseRequestNumber(1)).thenReturn(Collections.singletonList(detail1));
        when(productSupplierRepository.findById(5)).thenReturn(Optional.of(productSupplier));
        when(productRepository.findById(20)).thenReturn(Optional.of(product));
        when(supplierRepository.findById(30)).thenReturn(Optional.of(supplier));

        // Mock creator name and approver name lookups
        when(jdbcTemplate.queryForObject(contains("profiles WHERE user_id"), eq(String.class), eq(purchaseRequest.getCreatedBy())))
                .thenReturn("Nguyen Van A");
        when(jdbcTemplate.queryForObject(contains("profiles WHERE user_id"), eq(String.class), eq(purchaseRequest.getApprovedBy())))
                .thenReturn("Tran Thi B");

        PurchaseRequestDetailDTO dto = inventoryService.getPurchaseRequestDetails(1);

        assertNotNull(dto);
        assertEquals(1, dto.getPurchaseRequestNumber());
        assertEquals("Nguyen Van A", dto.getCreatedBy());
        assertEquals("Tran Thi B", dto.getApprovedBy());
        assertEquals("APPROVED", dto.getStatus());
        assertEquals(1, dto.getItems().size());
        assertEquals("Coca Cola", dto.getItems().get(0).getProductName());
        assertEquals("8930001112223", dto.getItems().get(0).getSku());
        assertEquals(BigDecimal.valueOf(100), dto.getItems().get(0).getRequestedQuantity());
        assertEquals(BigDecimal.valueOf(12.50), dto.getItems().get(0).getImportPrice());
    }

    @Test
    void testGetPurchaseRequestDetails_NotFound_ThrowsException() {
        when(purchaseRequestRepository.findById(999)).thenReturn(Optional.empty());

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            inventoryService.getPurchaseRequestDetails(999);
        });

        assertTrue(exception.getMessage().contains("Purchase request not found"));
    }

    @Test
    void testSubmitPurchaseRequest_Success() {
        PurchaseRequest pr = PurchaseRequest.builder()
                .purchaseRequestNumber(2)
                .status("DRAFT")
                .createdDate(LocalDateTime.now())
                .build();
        when(purchaseRequestRepository.findById(2)).thenReturn(Optional.of(pr));

        inventoryService.submitPurchaseRequest(2);

        assertEquals("PENDING", pr.getStatus());
        assertNotNull(pr.getCreatedDate());
        verify(purchaseRequestRepository, times(1)).save(pr);
    }

    @Test
    void testSubmitPurchaseRequest_InvalidStatus_ThrowsException() {
        PurchaseRequest pr = PurchaseRequest.builder()
                .purchaseRequestNumber(3)
                .status("APPROVED")
                .build();
        when(purchaseRequestRepository.findById(3)).thenReturn(Optional.of(pr));

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            inventoryService.submitPurchaseRequest(3);
        });

        assertTrue(exception.getMessage().contains("Only DRAFT purchase requests can be submitted"));
        verify(purchaseRequestRepository, never()).save(any(PurchaseRequest.class));
    }
}
