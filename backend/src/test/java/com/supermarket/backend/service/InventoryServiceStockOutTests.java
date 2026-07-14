package com.supermarket.backend.service;

import com.supermarket.backend.dto.StockOutFormDataDTO;
import com.supermarket.backend.dto.StockOutRequestDTO;
import com.supermarket.backend.entity.*;
import com.supermarket.backend.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class InventoryServiceStockOutTests {

    @Mock
    private ProductRepository productRepository;
    @Mock
    private InventoryRepository inventoryRepository;
    @Mock
    private StockInDetailRepository stockInDetailRepository;
    @Mock
    private PurchaseRequestRepository purchaseRequestRepository;
    @Mock
    private InventoryTransactionRepository inventoryTransactionRepository;
    @Mock
    private StockInRepository stockInRepository;
    @Mock
    private PurchaseRequestDetailRepository purchaseRequestDetailRepository;
    @Mock
    private ProductReportRepository productReportRepository;
    @Mock
    private ProductSupplierRepository productSupplierRepository;
    @Mock
    private SupplierRepository supplierRepository;
    @Mock
    private StockOutRepository stockOutRepository;
    @Mock
    private StockOutDetailRepository stockOutDetailRepository;

    @InjectMocks
    private InventoryService inventoryService;

    private ProductReport report;
    private Product product;
    private Inventory inventory;
    private StockInDetail batch1;
    private StockInDetail batch2;

    @BeforeEach
    void setUp() {
        report = ProductReport.builder()
                .reportNumber(4)
                .productNumber(6)
                .quantity(BigDecimal.valueOf(50))
                .status("APPROVED")
                .reportType("NEAR_EXPIRY")
                .issueType("EXPIRED")
                .description("Vinamilk Milk is expired.")
                .build();

        Unit unit = Unit.builder().unitNumber(1).unitName("Carton").build();

        product = Product.builder()
                .productNumber(6)
                .categoryNumber(3)
                .productName("Vinamilk Milk")
                .barcode("8934567890123")
                .unit(unit)
                .build();

        inventory = Inventory.builder()
                .productNumber(6)
                .availableQuantity(BigDecimal.valueOf(100))
                .totalQuantity(BigDecimal.valueOf(100))
                .build();

        batch1 = StockInDetail.builder()
                .stockInDetailNumber(10)
                .productNumber(6)
                .remainingQuantity(BigDecimal.valueOf(30))
                .expiryDate(LocalDate.now().plusDays(5))
                .build();

        batch2 = StockInDetail.builder()
                .stockInDetailNumber(11)
                .productNumber(6)
                .remainingQuantity(BigDecimal.valueOf(40))
                .expiryDate(LocalDate.now().plusDays(10))
                .build();
    }

    @Test
    void testGetStockOutFormData_Success() {
        when(productReportRepository.findById(4)).thenReturn(Optional.of(report));
        when(productRepository.findById(6)).thenReturn(Optional.of(product));
        when(inventoryRepository.findById(6)).thenReturn(Optional.of(inventory));

        StockOutFormDataDTO formData = inventoryService.getStockOutFormData(4);

        assertNotNull(formData);
        assertEquals(4, formData.getReportNumber());
        assertEquals(6, formData.getProductNumber());
        assertEquals("Vinamilk Milk", formData.getProductName());
        assertEquals("8934567890123", formData.getSku());
        assertEquals(BigDecimal.valueOf(50), formData.getQuantity());
        assertEquals("Carton", formData.getUnitName());
        assertEquals("A-3-6", formData.getLocation());
        assertEquals("Vinamilk Milk is expired.", formData.getDescription());
        assertEquals(BigDecimal.valueOf(100), formData.getAvailableQuantity());
    }

    @Test
    void testRecordStockOut_Success_FIFODeduction() {
        when(productReportRepository.findById(4)).thenReturn(Optional.of(report));
        when(inventoryRepository.findByIdForUpdate(6)).thenReturn(Optional.of(inventory));
        when(stockInDetailRepository.findLatestStockInDetails(6)).thenReturn(Arrays.asList(batch1, batch2));
        
        StockOut savedStockOut = StockOut.builder().stockOutNumber(100).build();
        when(stockOutRepository.save(any(StockOut.class))).thenReturn(savedStockOut);

        StockOutRequestDTO request = StockOutRequestDTO.builder()
                .reportNumber(4)
                .quantity(BigDecimal.valueOf(50))
                .reason("EXPIRED")
                .notes("Deducting expired milk batches")
                .createdBy("e3b3ec4a-da0b-40f5-9747-29361993892b")
                .build();

        inventoryService.recordStockOut(request);

        // Verify FIFO: Batch 1 (30 remaining) should be completely cleared (remaining = 0)
        assertEquals(BigDecimal.ZERO, batch1.getRemainingQuantity());
        // Batch 2 (40 remaining) should have 20 deducted (remaining = 20)
        assertEquals(BigDecimal.valueOf(20), batch2.getRemainingQuantity());

        // Verify inventory updated: 100 - 50 = 50 available & total quantity
        assertEquals(BigDecimal.valueOf(50), inventory.getAvailableQuantity());
        assertEquals(BigDecimal.valueOf(50), inventory.getTotalQuantity());

        // Verify repositories save was called
        verify(stockInDetailRepository, times(2)).save(any(StockInDetail.class));
        verify(stockOutRepository, times(1)).save(any(StockOut.class));
        verify(stockOutDetailRepository, times(2)).save(any(StockOutDetail.class));
        verify(inventoryRepository, times(1)).save(inventory);
        verify(inventoryTransactionRepository, times(1)).save(any(InventoryTransaction.class));
        verify(productReportRepository, times(1)).save(report);

        // Verify report is marked resolved
        assertNotNull(report.getResolvedAt());
        assertEquals(UUID.fromString("e3b3ec4a-da0b-40f5-9747-29361993892b"), report.getResolvedBy());
    }

    @Test
    void testRecordStockOut_InsufficientInventory_ThrowsException() {
        when(productReportRepository.findById(4)).thenReturn(Optional.of(report));
        when(inventoryRepository.findByIdForUpdate(6)).thenReturn(Optional.of(inventory));

        StockOutRequestDTO request = StockOutRequestDTO.builder()
                .reportNumber(4)
                .quantity(BigDecimal.valueOf(150)) // Exceeds available 100
                .reason("EXPIRED")
                .build();

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            inventoryService.recordStockOut(request);
        });

        assertTrue(exception.getMessage().contains("Insufficient inventory"));
    }

    @Test
    void testRecordStockOut_ReportNotApproved_ThrowsException() {
        report.setStatus("PENDING");
        when(productReportRepository.findById(4)).thenReturn(Optional.of(report));

        StockOutRequestDTO request = StockOutRequestDTO.builder()
                .reportNumber(4)
                .quantity(BigDecimal.valueOf(10))
                .reason("EXPIRED")
                .build();

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            inventoryService.recordStockOut(request);
        });

        assertTrue(exception.getMessage().contains("is not approved for stock-out"));
    }
}
