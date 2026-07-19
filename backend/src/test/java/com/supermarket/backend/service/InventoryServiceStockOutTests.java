package com.supermarket.backend.service;

import com.supermarket.backend.dto.StockOutFormDataDTO;
import com.supermarket.backend.dto.StockOutRequestDTO;
import com.supermarket.backend.dto.StockInRequestDTO;
import com.supermarket.backend.dto.StockInDetailRequestDTO;
import com.supermarket.backend.dto.DeliveryIssueRequestDTO;
import com.supermarket.backend.entity.*;
import com.supermarket.backend.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;

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
    @Mock
    private JdbcTemplate jdbcTemplate;

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

        try {
            java.lang.reflect.Field field = InventoryService.class.getDeclaredField("defaultUserIdStr");
            field.setAccessible(true);
            field.set(inventoryService, "e3b3ec4a-da0b-40f5-9747-29361993892b");
        } catch (Exception e) {
            e.printStackTrace();
        }
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

        // Verify FIFO: Batch 1 (30 remaining) should be completely cleared (remaining =
        // 0)
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

    @Test
    void testRecordStockOut_ReportTypeNotEligible_ThrowsException() {
        report.setReportType("LOW_STOCK");
        when(productReportRepository.findById(4)).thenReturn(Optional.of(report));

        StockOutRequestDTO request = StockOutRequestDTO.builder()
                .reportNumber(4)
                .quantity(BigDecimal.valueOf(10))
                .reason("LOW_STOCK")
                .build();

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            inventoryService.recordStockOut(request);
        });

        assertTrue(exception.getMessage().contains("is not eligible for stock-out"));
    }

    @Test
    void testValidateAndSaveDeliveryIssue_Success() {
        DeliveryIssueRequestDTO request = DeliveryIssueRequestDTO.builder()
                .purchaseRequestNumber(12)
                .productNumber(6)
                .reportedBy("e3b3ec4a-da0b-40f5-9747-29361993892b")
                .issueType("SHORTAGE")
                .quantity(BigDecimal.valueOf(5))
                .description("Short of 5 boxes")
                .build();

        inventoryService.validateAndSaveDeliveryIssue(request);

        verify(productReportRepository, times(1)).save(argThat(r -> "DELIVERY_DISCREPANCY".equals(r.getReportType()) &&
                r.getProductNumber().equals(6) &&
                r.getQuantity().compareTo(BigDecimal.valueOf(5)) == 0 &&
                "[PR-12] Short of 5 boxes".equals(r.getDescription())));
    }

    @Test
    void testValidateAndSaveDeliveryIssue_MissingPurchaseRequestNumber_ThrowsException() {
        DeliveryIssueRequestDTO request = DeliveryIssueRequestDTO.builder()
                .productNumber(6)
                .reportedBy("e3b3ec4a-da0b-40f5-9747-29361993892b")
                .issueType("SHORTAGE")
                .quantity(BigDecimal.valueOf(5))
                .description("Short of 5 boxes")
                .build();

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            inventoryService.validateAndSaveDeliveryIssue(request);
        });

        assertTrue(exception.getMessage().contains("Purchase request number is required"));
    }

    @Test
    void testRecordStockIn_AssociatesOnlyCorrectDiscrepancyReports() {
        StockInDetailRequestDTO itemRequest = StockInDetailRequestDTO.builder()
                .productNumber(6)
                .deliveredQuantity(BigDecimal.valueOf(100))
                .importPrice(BigDecimal.valueOf(10.0))
                .build();

        StockInRequestDTO request = StockInRequestDTO.builder()
                .purchaseRequestNumber(12)
                .supplierNumber(30)
                .createdBy("e3b3ec4a-da0b-40f5-9747-29361993892b")
                .items(Collections.singletonList(itemRequest))
                .build();

        StockIn stockIn = StockIn.builder().stockInNumber(100).build();
        when(stockInRepository.save(any(StockIn.class))).thenReturn(stockIn);

        StockInDetail savedDetail = StockInDetail.builder().stockInDetailNumber(200).build();
        when(stockInDetailRepository.save(any(StockInDetail.class))).thenReturn(savedDetail);

        Inventory inv = Inventory.builder().productNumber(6).availableQuantity(BigDecimal.ZERO)
                .totalQuantity(BigDecimal.ZERO).build();
        when(inventoryRepository.findByIdForUpdate(6)).thenReturn(Optional.of(inv));
        when(productRepository.findAllById(any())).thenReturn(Collections.singletonList(Product.builder().productNumber(6).build()));

        ProductReport reportMatching = ProductReport.builder()
                .reportNumber(1)
                .productNumber(6)
                .reportType("DELIVERY_DISCREPANCY")
                .description("[PR-12] Shortage report")
                .stockInDetailNumber(null)
                .build();

        ProductReport reportOtherPR = ProductReport.builder()
                .reportNumber(2)
                .productNumber(6)
                .reportType("DELIVERY_DISCREPANCY")
                .description("[PR-99] Shortage report")
                .stockInDetailNumber(null)
                .build();

        ProductReport reportOtherProduct = ProductReport.builder()
                .reportNumber(3)
                .productNumber(999)
                .reportType("DELIVERY_DISCREPANCY")
                .description("[PR-12] Shortage report")
                .stockInDetailNumber(null)
                .build();

        when(productReportRepository.findDeliveryDiscrepancies(eq(6), contains("[PR-12]")))
                .thenReturn(Collections.singletonList(reportMatching));

        PurchaseRequestDetail prd = PurchaseRequestDetail.builder().productSupplierNumber(5)
                .requestedQuantity(BigDecimal.valueOf(100)).build();
        when(purchaseRequestDetailRepository.findByPurchaseRequestNumber(12))
                .thenReturn(Collections.singletonList(prd));

        ProductSupplier ps = ProductSupplier.builder().productSupplierNumber(5).productNumber(6).supplierNumber(30).build();
        when(productSupplierRepository.findAllById(any())).thenReturn(Collections.singletonList(ps));

        Map<Integer, BigDecimal> alreadyReceivedMap = new HashMap<>();
        alreadyReceivedMap.put(6, BigDecimal.ZERO);
        Map<Integer, BigDecimal> updatedReceivedMap = new HashMap<>();
        updatedReceivedMap.put(6, BigDecimal.valueOf(100));
        when(jdbcTemplate.query(anyString(), any(org.springframework.jdbc.core.ResultSetExtractor.class), any()))
                .thenReturn(alreadyReceivedMap, updatedReceivedMap);

        PurchaseRequest pr = PurchaseRequest.builder().purchaseRequestNumber(12).status("APPROVED").build();
        when(purchaseRequestRepository.findByIdForUpdate(12)).thenReturn(Optional.of(pr));

        inventoryService.recordStockIn(request);

        verify(productReportRepository, times(1)).save(reportMatching);
        assertEquals(200, reportMatching.getStockInDetailNumber());

        verify(productReportRepository, never()).save(reportOtherPR);
        verify(productReportRepository, never()).save(reportOtherProduct);
    }

    @Test
    void testRecordStockIn_PurchaseRequestNotFound_ThrowsException() {
        when(purchaseRequestRepository.findByIdForUpdate(99)).thenReturn(Optional.empty());

        StockInRequestDTO request = StockInRequestDTO.builder()
                .purchaseRequestNumber(99)
                .items(Collections.singletonList(StockInDetailRequestDTO.builder().productNumber(6)
                        .deliveredQuantity(BigDecimal.valueOf(10)).build()))
                .build();

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            inventoryService.recordStockIn(request);
        });

        assertTrue(exception.getMessage().contains("Purchase request not found"));
    }

    @Test
    void testRecordStockIn_PurchaseRequestIneligibleStatus_ThrowsException() {
        PurchaseRequest pr = PurchaseRequest.builder().purchaseRequestNumber(12).status("DRAFT").build();
        when(purchaseRequestRepository.findByIdForUpdate(12)).thenReturn(Optional.of(pr));

        StockInRequestDTO request = StockInRequestDTO.builder()
                .purchaseRequestNumber(12)
                .items(Collections.singletonList(StockInDetailRequestDTO.builder().productNumber(6)
                        .deliveredQuantity(BigDecimal.valueOf(10)).build()))
                .build();

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            inventoryService.recordStockIn(request);
        });

        assertTrue(exception.getMessage().contains("is not in an eligible status for stock-in"));
    }

    @Test
    void testRecordStockIn_SupplierMismatch_ThrowsException() {
        PurchaseRequest pr = PurchaseRequest.builder().purchaseRequestNumber(12).status("APPROVED").build();
        when(purchaseRequestRepository.findByIdForUpdate(12)).thenReturn(Optional.of(pr));

        PurchaseRequestDetail prd = PurchaseRequestDetail.builder().productSupplierNumber(5)
                .requestedQuantity(BigDecimal.valueOf(100)).build();
        when(purchaseRequestDetailRepository.findByPurchaseRequestNumber(12))
                .thenReturn(Collections.singletonList(prd));

        ProductSupplier ps = ProductSupplier.builder().productSupplierNumber(5).productNumber(6).supplierNumber(30).build();
        when(productSupplierRepository.findAllById(any())).thenReturn(Collections.singletonList(ps));

        StockInRequestDTO request = StockInRequestDTO.builder()
                .purchaseRequestNumber(12)
                .supplierNumber(40)
                .items(Collections.singletonList(StockInDetailRequestDTO.builder().productNumber(6)
                        .deliveredQuantity(BigDecimal.valueOf(10)).build()))
                .build();

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            inventoryService.recordStockIn(request);
        });

        assertTrue(exception.getMessage().contains("Supplier mismatch")
                || exception.getMessage().contains("No items found"));
    }

    @Test
    void testRecordStockIn_ProductNotPartOfPR_ThrowsException() {
        PurchaseRequest pr = PurchaseRequest.builder().purchaseRequestNumber(12).status("APPROVED").build();
        when(purchaseRequestRepository.findByIdForUpdate(12)).thenReturn(Optional.of(pr));

        PurchaseRequestDetail prd = PurchaseRequestDetail.builder().productSupplierNumber(5)
                .requestedQuantity(BigDecimal.valueOf(100)).build();
        when(purchaseRequestDetailRepository.findByPurchaseRequestNumber(12))
                .thenReturn(Collections.singletonList(prd));

        ProductSupplier ps = ProductSupplier.builder().productSupplierNumber(5).productNumber(6).supplierNumber(30).build();
        when(productSupplierRepository.findAllById(any())).thenReturn(Collections.singletonList(ps));

        Map<Integer, BigDecimal> alreadyReceivedMap = new HashMap<>();
        alreadyReceivedMap.put(6, BigDecimal.ZERO);
        when(jdbcTemplate.query(anyString(), any(org.springframework.jdbc.core.ResultSetExtractor.class), any()))
                .thenReturn(alreadyReceivedMap);

        StockInRequestDTO request = StockInRequestDTO.builder()
                .purchaseRequestNumber(12)
                .supplierNumber(30)
                .items(Collections.singletonList(StockInDetailRequestDTO.builder().productNumber(999)
                        .deliveredQuantity(BigDecimal.valueOf(10)).build()))
                .build();

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            inventoryService.recordStockIn(request);
        });

        assertTrue(exception.getMessage().contains("is not part of the purchase request"));
    }

    @Test
    void testRecordStockIn_OverDelivery_ThrowsException() {
        PurchaseRequest pr = PurchaseRequest.builder().purchaseRequestNumber(12).status("APPROVED").build();
        when(purchaseRequestRepository.findByIdForUpdate(12)).thenReturn(Optional.of(pr));

        PurchaseRequestDetail prd = PurchaseRequestDetail.builder().productSupplierNumber(5)
                .requestedQuantity(BigDecimal.valueOf(100)).build();
        when(purchaseRequestDetailRepository.findByPurchaseRequestNumber(12))
                .thenReturn(Collections.singletonList(prd));

        ProductSupplier ps = ProductSupplier.builder().productSupplierNumber(5).productNumber(6).supplierNumber(30).build();
        when(productSupplierRepository.findAllById(any())).thenReturn(Collections.singletonList(ps));

        Map<Integer, BigDecimal> alreadyReceivedMap = new HashMap<>();
        alreadyReceivedMap.put(6, BigDecimal.valueOf(80));
        when(jdbcTemplate.query(anyString(), any(org.springframework.jdbc.core.ResultSetExtractor.class), any()))
                .thenReturn(alreadyReceivedMap);

        StockInRequestDTO request = StockInRequestDTO.builder()
                .purchaseRequestNumber(12)
                .supplierNumber(30)
                .items(Collections.singletonList(StockInDetailRequestDTO.builder().productNumber(6)
                        .deliveredQuantity(BigDecimal.valueOf(30)).build()))
                .build();

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            inventoryService.recordStockIn(request);
        });

        assertTrue(exception.getMessage().contains("Over-delivery not allowed"));
    }
}
