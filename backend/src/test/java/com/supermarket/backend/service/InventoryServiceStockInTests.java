package com.supermarket.backend.service;

import com.supermarket.backend.dto.*;
import com.supermarket.backend.entity.*;
import com.supermarket.backend.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.ResultSetExtractor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class InventoryServiceStockInTests {

    @Mock
    private ProductRepository productRepository;
    @Mock
    private InventoryRepository inventoryRepository;
    @Mock
    private StockInDetailRepository stockInDetailRepository;
    @Mock
    private PromotionProductRepository promotionProductRepository;
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
    private UnitRepository unitRepository;
    @Mock
    private ProfileRepository profileRepository;
    @Mock
    private CategoryRepository categoryRepository;
    @Mock
    private JdbcTemplate jdbcTemplate;

    @InjectMocks
    private InventoryService inventoryService;

    private PurchaseRequest pr;
    private PurchaseRequestDetail detailA;
    private PurchaseRequestDetail detailB;
    private ProductSupplier prodSupplierA;
    private ProductSupplier prodSupplierB;
    private Product productA;
    private Product productB;
    private Inventory inventoryA;
    private Inventory inventoryB;

    @BeforeEach
    void setUp() {
        pr = PurchaseRequest.builder()
                .purchaseRequestNumber(100)
                .status("APPROVED")
                .createdBy(UUID.randomUUID())
                .createdDate(LocalDateTime.now().minusDays(1))
                .expectedDeliveryDate(LocalDate.now().plusDays(2))
                .build();

        detailA = PurchaseRequestDetail.builder()
                .purchaseRequestDetailNumber(1)
                .purchaseRequestNumber(100)
                .productSupplierNumber(10)
                .requestedQuantity(BigDecimal.valueOf(100))
                .build();

        detailB = PurchaseRequestDetail.builder()
                .purchaseRequestDetailNumber(2)
                .purchaseRequestNumber(100)
                .productSupplierNumber(11)
                .requestedQuantity(BigDecimal.valueOf(50))
                .build();

        prodSupplierA = ProductSupplier.builder()
                .productSupplierNumber(10)
                .productNumber(200)
                .supplierNumber(300)
                .minimumOrderQuantity(BigDecimal.valueOf(10))
                .importPrice(BigDecimal.valueOf(15.0))
                .build();

        prodSupplierB = ProductSupplier.builder()
                .productSupplierNumber(11)
                .productNumber(201)
                .supplierNumber(300)
                .minimumOrderQuantity(BigDecimal.valueOf(5))
                .importPrice(BigDecimal.valueOf(25.0))
                .build();

        productA = Product.builder()
                .productNumber(200)
                .productName("Organic Apples")
                .barcode("8930001001001")
                .build();

        productB = Product.builder()
                .productNumber(201)
                .productName("Organic Bananas")
                .barcode("8930001001002")
                .build();

        inventoryA = Inventory.builder()
                .productNumber(200)
                .availableQuantity(BigDecimal.valueOf(10))
                .totalQuantity(BigDecimal.valueOf(10))
                .build();

        inventoryB = Inventory.builder()
                .productNumber(201)
                .availableQuantity(BigDecimal.valueOf(5))
                .totalQuantity(BigDecimal.valueOf(5))
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
    void testRecordStockIn_Success_MarksCompleted() {
        when(purchaseRequestRepository.findByIdForUpdate(100)).thenReturn(Optional.of(pr));
        when(purchaseRequestDetailRepository.findByPurchaseRequestNumber(100))
                .thenReturn(Arrays.asList(detailA, detailB));
        
        when(productSupplierRepository.findAllById(Arrays.asList(10, 11)))
                .thenReturn(Arrays.asList(prodSupplierA, prodSupplierB));

        // Mock already received maps to return 0
        when(jdbcTemplate.query(anyString(), any(ResultSetExtractor.class), eq(100)))
                .thenReturn(new HashMap<>()) // First query: already received
                .thenReturn(new HashMap<Integer, BigDecimal>() {{
                    put(200, BigDecimal.valueOf(100));
                    put(201, BigDecimal.valueOf(50));
                }}); // Second query inside recordStockIn: updatedReceivedMap

        StockInRequestDTO request = StockInRequestDTO.builder()
                .purchaseRequestNumber(100)
                .supplierNumber(300)
                .createdBy("e3b3ec4a-da0b-40f5-9747-29361993892b")
                .items(Arrays.asList(
                        StockInDetailRequestDTO.builder()
                                .productNumber(200)
                                .deliveredQuantity(BigDecimal.valueOf(100))
                                .importPrice(BigDecimal.valueOf(15.0))
                                .notes("Batch A")
                                .build(),
                        StockInDetailRequestDTO.builder()
                                .productNumber(201)
                                .deliveredQuantity(BigDecimal.valueOf(50))
                                .importPrice(BigDecimal.valueOf(25.0))
                                .notes("Batch B")
                                .build()
                ))
                .build();

        StockIn savedStockIn = StockIn.builder().stockInNumber(500).build();
        when(stockInRepository.save(any(StockIn.class))).thenReturn(savedStockIn);

        when(productRepository.findAllById(Arrays.asList(200, 201)))
                .thenReturn(Arrays.asList(productA, productB));

        StockInDetail savedDetailA = StockInDetail.builder().stockInDetailNumber(1000).build();
        StockInDetail savedDetailB = StockInDetail.builder().stockInDetailNumber(1001).build();
        when(stockInDetailRepository.save(any(StockInDetail.class)))
                .thenReturn(savedDetailA)
                .thenReturn(savedDetailB);

        when(inventoryRepository.findByIdForUpdate(200)).thenReturn(Optional.of(inventoryA));
        when(inventoryRepository.findByIdForUpdate(201)).thenReturn(Optional.of(inventoryB));

        // Mock report discrepancies check to prevent NPE
        when(productReportRepository.findDeliveryDiscrepancies(anyInt(), anyString()))
                .thenReturn(Collections.emptyList());

        // Execute
        inventoryService.recordStockIn(request);

        // Verify status is COMPLETED because all items are fully received
        assertEquals("COMPLETED", pr.getStatus());
        verify(purchaseRequestRepository, times(1)).save(pr);

        // Verify inventory quantities were incremented
        assertEquals(BigDecimal.valueOf(110), inventoryA.getAvailableQuantity());
        assertEquals(BigDecimal.valueOf(55), inventoryB.getAvailableQuantity());

        verify(inventoryRepository, times(1)).save(inventoryA);
        verify(inventoryRepository, times(1)).save(inventoryB);
        verify(inventoryTransactionRepository, times(2)).save(any(InventoryTransaction.class));
    }

    @Test
    void testRecordStockIn_Success_MarksPartiallyReceived() {
        when(purchaseRequestRepository.findByIdForUpdate(100)).thenReturn(Optional.of(pr));
        when(purchaseRequestDetailRepository.findByPurchaseRequestNumber(100))
                .thenReturn(Arrays.asList(detailA, detailB));
        
        when(productSupplierRepository.findAllById(Arrays.asList(10, 11)))
                .thenReturn(Arrays.asList(prodSupplierA, prodSupplierB));

        // Mock already received maps
        when(jdbcTemplate.query(anyString(), any(ResultSetExtractor.class), eq(100)))
                .thenReturn(new HashMap<>()) // First query: already received
                .thenReturn(new HashMap<Integer, BigDecimal>() {{
                    put(200, BigDecimal.valueOf(100));
                    put(201, BigDecimal.valueOf(20)); // Only 20 out of 50 received
                }}); // Second query: updatedReceivedMap

        StockInRequestDTO request = StockInRequestDTO.builder()
                .purchaseRequestNumber(100)
                .supplierNumber(300)
                .createdBy("e3b3ec4a-da0b-40f5-9747-29361993892b")
                .items(Arrays.asList(
                        StockInDetailRequestDTO.builder()
                                .productNumber(200)
                                .deliveredQuantity(BigDecimal.valueOf(100))
                                .importPrice(BigDecimal.valueOf(15.0))
                                .notes("Batch A")
                                .build(),
                        StockInDetailRequestDTO.builder()
                                .productNumber(201)
                                .deliveredQuantity(BigDecimal.valueOf(20))
                                .importPrice(BigDecimal.valueOf(25.0))
                                .notes("Batch B partial")
                                .build()
                ))
                .build();

        StockIn savedStockIn = StockIn.builder().stockInNumber(500).build();
        when(stockInRepository.save(any(StockIn.class))).thenReturn(savedStockIn);

        when(productRepository.findAllById(Arrays.asList(200, 201)))
                .thenReturn(Arrays.asList(productA, productB));

        StockInDetail savedDetailA = StockInDetail.builder().stockInDetailNumber(1000).build();
        StockInDetail savedDetailB = StockInDetail.builder().stockInDetailNumber(1001).build();
        when(stockInDetailRepository.save(any(StockInDetail.class)))
                .thenReturn(savedDetailA)
                .thenReturn(savedDetailB);

        when(inventoryRepository.findByIdForUpdate(200)).thenReturn(Optional.of(inventoryA));
        when(inventoryRepository.findByIdForUpdate(201)).thenReturn(Optional.of(inventoryB));

        // Mock report discrepancies check to prevent NPE
        when(productReportRepository.findDeliveryDiscrepancies(anyInt(), anyString()))
                .thenReturn(Collections.emptyList());

        // Execute
        inventoryService.recordStockIn(request);

        // Verify status is PARTIALLY_RECEIVED because bananas are not fully received (20 < 50)
        assertEquals("PARTIALLY_RECEIVED", pr.getStatus());
        verify(purchaseRequestRepository, times(1)).save(pr);
    }

    @Test
    void testRecordStockIn_Success_CreatesNewInventory() {
        when(purchaseRequestRepository.findByIdForUpdate(100)).thenReturn(Optional.of(pr));
        when(purchaseRequestDetailRepository.findByPurchaseRequestNumber(100))
                .thenReturn(Collections.singletonList(detailA));
        
        when(productSupplierRepository.findAllById(Collections.singletonList(10)))
                .thenReturn(Collections.singletonList(prodSupplierA));

        when(jdbcTemplate.query(anyString(), any(ResultSetExtractor.class), eq(100)))
                .thenReturn(new HashMap<>())
                .thenReturn(new HashMap<Integer, BigDecimal>() {{
                    put(200, BigDecimal.valueOf(100));
                }});

        StockInRequestDTO request = StockInRequestDTO.builder()
                .purchaseRequestNumber(100)
                .supplierNumber(300)
                .items(Collections.singletonList(
                        StockInDetailRequestDTO.builder()
                                .productNumber(200)
                                .deliveredQuantity(BigDecimal.valueOf(100))
                                .build()
                ))
                .build();

        StockIn savedStockIn = StockIn.builder().stockInNumber(500).build();
        when(stockInRepository.save(any(StockIn.class))).thenReturn(savedStockIn);
        when(productRepository.findAllById(Collections.singletonList(200))).thenReturn(Collections.singletonList(productA));
        when(stockInDetailRepository.save(any(StockInDetail.class))).thenReturn(StockInDetail.builder().build());

        // Mock empty inventory lookup so it triggers creating a new one
        when(inventoryRepository.findByIdForUpdate(200)).thenReturn(Optional.empty());
        when(inventoryRepository.save(any(Inventory.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Mock report discrepancies check to prevent NPE
        when(productReportRepository.findDeliveryDiscrepancies(anyInt(), anyString()))
                .thenReturn(Collections.emptyList());

        inventoryService.recordStockIn(request);

        verify(inventoryRepository, times(2)).save(any(Inventory.class)); // 1 for creation, 1 for update
    }

    @Test
    void testRecordStockIn_ValidationError_OverDeliveryThrowsException() {
        when(purchaseRequestRepository.findByIdForUpdate(100)).thenReturn(Optional.of(pr));
        when(purchaseRequestDetailRepository.findByPurchaseRequestNumber(100))
                .thenReturn(Collections.singletonList(detailA));
        
        when(productSupplierRepository.findAllById(Collections.singletonList(10)))
                .thenReturn(Collections.singletonList(prodSupplierA));

        when(jdbcTemplate.query(anyString(), any(ResultSetExtractor.class), eq(100)))
                .thenReturn(new HashMap<>());

        StockInRequestDTO request = StockInRequestDTO.builder()
                .purchaseRequestNumber(100)
                .supplierNumber(300)
                .items(Collections.singletonList(
                        StockInDetailRequestDTO.builder()
                                .productNumber(200)
                                .deliveredQuantity(BigDecimal.valueOf(120)) // 120 > 100 requested
                                .build()
                ))
                .build();

        assertThrows(IllegalArgumentException.class, () -> inventoryService.recordStockIn(request));
        verify(stockInRepository, never()).save(any(StockIn.class));
    }

    @Test
    void testRecordStockIn_PRNotFound_ThrowsException() {
        when(purchaseRequestRepository.findByIdForUpdate(999)).thenReturn(Optional.empty());

        StockInRequestDTO request = StockInRequestDTO.builder()
                .purchaseRequestNumber(999)
                .supplierNumber(300)
                .items(Collections.singletonList(StockInDetailRequestDTO.builder().build()))
                .build();

        assertThrows(IllegalArgumentException.class, () -> inventoryService.recordStockIn(request));
    }

    @Test
    void testRecordStockIn_InvalidPRStatus_ThrowsException() {
        pr.setStatus("DRAFT"); // Only APPROVED or PARTIALLY_RECEIVED allowed
        when(purchaseRequestRepository.findByIdForUpdate(100)).thenReturn(Optional.of(pr));

        StockInRequestDTO request = StockInRequestDTO.builder()
                .purchaseRequestNumber(100)
                .supplierNumber(300)
                .items(Collections.singletonList(StockInDetailRequestDTO.builder().build()))
                .build();

        assertThrows(IllegalArgumentException.class, () -> inventoryService.recordStockIn(request));
    }

    @Test
    void testRecordStockIn_PRDetailsEmpty_ThrowsException() {
        when(purchaseRequestRepository.findByIdForUpdate(100)).thenReturn(Optional.of(pr));
        when(purchaseRequestDetailRepository.findByPurchaseRequestNumber(100)).thenReturn(Collections.emptyList());

        StockInRequestDTO request = StockInRequestDTO.builder()
                .purchaseRequestNumber(100)
                .supplierNumber(300)
                .items(Collections.singletonList(StockInDetailRequestDTO.builder().build()))
                .build();

        assertThrows(IllegalArgumentException.class, () -> inventoryService.recordStockIn(request));
    }

    @Test
    void testRecordStockIn_MissingSupplierNumber_ThrowsException() {
        when(purchaseRequestRepository.findByIdForUpdate(100)).thenReturn(Optional.of(pr));
        when(purchaseRequestDetailRepository.findByPurchaseRequestNumber(100))
                .thenReturn(Collections.singletonList(detailA));

        StockInRequestDTO request = StockInRequestDTO.builder()
                .purchaseRequestNumber(100)
                .supplierNumber(null) // supplier is required
                .items(Collections.singletonList(StockInDetailRequestDTO.builder().build()))
                .build();

        assertThrows(IllegalArgumentException.class, () -> inventoryService.recordStockIn(request));
    }

    @Test
    void testRecordStockIn_NoItemsForSupplier_ThrowsException() {
        when(purchaseRequestRepository.findByIdForUpdate(100)).thenReturn(Optional.of(pr));
        when(purchaseRequestDetailRepository.findByPurchaseRequestNumber(100))
                .thenReturn(Collections.singletonList(detailA));
        
        when(productSupplierRepository.findAllById(Collections.singletonList(10)))
                .thenReturn(Collections.singletonList(prodSupplierA)); // belongs to supplier 300

        StockInRequestDTO request = StockInRequestDTO.builder()
                .purchaseRequestNumber(100)
                .supplierNumber(999) // mismatched supplier
                .items(Collections.singletonList(StockInDetailRequestDTO.builder().productNumber(200).deliveredQuantity(BigDecimal.TEN).build()))
                .build();

        assertThrows(IllegalArgumentException.class, () -> inventoryService.recordStockIn(request));
    }

    @Test
    void testRecordStockIn_NegativeDeliveredQuantity_ThrowsException() {
        when(purchaseRequestRepository.findByIdForUpdate(100)).thenReturn(Optional.of(pr));
        when(purchaseRequestDetailRepository.findByPurchaseRequestNumber(100))
                .thenReturn(Collections.singletonList(detailA));
        when(productSupplierRepository.findAllById(Collections.singletonList(10)))
                .thenReturn(Collections.singletonList(prodSupplierA));

        StockInRequestDTO request = StockInRequestDTO.builder()
                .purchaseRequestNumber(100)
                .supplierNumber(300)
                .items(Collections.singletonList(
                        StockInDetailRequestDTO.builder()
                                .productNumber(200)
                                .deliveredQuantity(BigDecimal.valueOf(-5)) // negative quantity
                                .build()
                ))
                .build();

        assertThrows(IllegalArgumentException.class, () -> inventoryService.recordStockIn(request));
    }

    @Test
    void testRecordStockIn_ExpiryBeforeMfg_ThrowsException() {
        when(purchaseRequestRepository.findByIdForUpdate(100)).thenReturn(Optional.of(pr));
        when(purchaseRequestDetailRepository.findByPurchaseRequestNumber(100))
                .thenReturn(Collections.singletonList(detailA));
        when(productSupplierRepository.findAllById(Collections.singletonList(10)))
                .thenReturn(Collections.singletonList(prodSupplierA));

        StockInRequestDTO request = StockInRequestDTO.builder()
                .purchaseRequestNumber(100)
                .supplierNumber(300)
                .items(Collections.singletonList(
                        StockInDetailRequestDTO.builder()
                                .productNumber(200)
                                .deliveredQuantity(BigDecimal.TEN)
                                .manufacturingDate(LocalDate.now())
                                .expiryDate(LocalDate.now().minusDays(5)) // expiry before mfg
                                .build()
                ))
                .build();

        assertThrows(IllegalArgumentException.class, () -> inventoryService.recordStockIn(request));
    }

    @Test
    void testCompareQuantities_Matched() {
        when(purchaseRequestDetailRepository.findByPurchaseRequestNumber(100))
                .thenReturn(Collections.singletonList(detailA));
        when(productSupplierRepository.findAllById(Collections.singletonList(10)))
                .thenReturn(Collections.singletonList(prodSupplierA));

        when(jdbcTemplate.query(anyString(), any(ResultSetExtractor.class), eq(100)))
                .thenReturn(new HashMap<Integer, BigDecimal>() {{
                    put(200, BigDecimal.valueOf(20));
                }});

        CompareQuantitiesRequestDTO request = CompareQuantitiesRequestDTO.builder()
                .purchaseRequestNumber(100)
                .supplierNumber(300)
                .deliveredQuantities(new HashMap<Integer, BigDecimal>() {{
                    put(200, BigDecimal.valueOf(80));
                }})
                .build();

        CompareQuantitiesResultDTO result = inventoryService.compareQuantities(request);

        assertNotNull(result);
        assertTrue(result.isMatched());
        assertFalse(result.isHasDiscrepancy());
        assertEquals(BigDecimal.ZERO, result.getDifferences().get(200));
    }

    @Test
    void testCompareQuantities_Discrepancy() {
        when(purchaseRequestDetailRepository.findByPurchaseRequestNumber(100))
                .thenReturn(Collections.singletonList(detailA));
        when(productSupplierRepository.findAllById(Collections.singletonList(10)))
                .thenReturn(Collections.singletonList(prodSupplierA));

        when(jdbcTemplate.query(anyString(), any(ResultSetExtractor.class), eq(100)))
                .thenReturn(new HashMap<Integer, BigDecimal>() {{
                    put(200, BigDecimal.valueOf(20));
                }});

        CompareQuantitiesRequestDTO request = CompareQuantitiesRequestDTO.builder()
                .purchaseRequestNumber(100)
                .supplierNumber(300)
                .deliveredQuantities(new HashMap<Integer, BigDecimal>() {{
                    put(200, BigDecimal.valueOf(50));
                }})
                .build();

        CompareQuantitiesResultDTO result = inventoryService.compareQuantities(request);

        assertNotNull(result);
        assertFalse(result.isMatched());
        assertTrue(result.isHasDiscrepancy());
        assertEquals(BigDecimal.valueOf(30), result.getDifferences().get(200));
    }

    @Test
    void testGetPurchaseRequestDetail_Success() {
        when(purchaseRequestRepository.findById(100)).thenReturn(Optional.of(pr));
        when(purchaseRequestDetailRepository.findByPurchaseRequestNumber(100)).thenReturn(Collections.singletonList(detailA));
        when(productSupplierRepository.findById(10)).thenReturn(Optional.of(prodSupplierA));
        when(supplierRepository.findById(300)).thenReturn(Optional.of(Supplier.builder().supplierName("Coca").build()));
        when(productSupplierRepository.findAllById(Collections.singletonList(10))).thenReturn(Collections.singletonList(prodSupplierA));
        when(productRepository.findAllById(Collections.singletonList(200))).thenReturn(Collections.singletonList(productA));

        StockInFormDataDTO result = inventoryService.getPurchaseRequestDetail(100, 300);

        assertNotNull(result);
        assertEquals("Coca", result.getSupplierName());
        assertEquals(1, result.getItems().size());
        assertEquals("Organic Apples", result.getItems().get(0).getProductName());
    }

    @Test
    void testGetPurchaseRequestDetail_PRNotFound_ThrowsException() {
        when(purchaseRequestRepository.findById(999)).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class, () -> inventoryService.getPurchaseRequestDetail(999, 300));
    }

    @Test
    void testGetPurchaseRequestDetail_DetailsEmpty_ThrowsException() {
        when(purchaseRequestRepository.findById(100)).thenReturn(Optional.of(pr));
        when(purchaseRequestDetailRepository.findByPurchaseRequestNumber(100)).thenReturn(Collections.emptyList());
        assertThrows(IllegalArgumentException.class, () -> inventoryService.getPurchaseRequestDetail(100, 300));
    }
}
