package com.supermarket.backend.service;

import com.supermarket.backend.dto.CreateProductReportDTO;
import com.supermarket.backend.dto.ProductReportDTO;
import com.supermarket.backend.dto.SuggestProductUpdateDTO;
import com.supermarket.backend.entity.Notification;
import com.supermarket.backend.entity.Product;
import com.supermarket.backend.entity.ProductReport;
import com.supermarket.backend.entity.Profile;
import com.supermarket.backend.repository.NotificationRepository;
import com.supermarket.backend.repository.ProductReportRepository;
import com.supermarket.backend.repository.ProductRepository;
import com.supermarket.backend.repository.ProfileRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class ProductReportServiceTests {

    @Mock
    private ProductReportRepository productReportRepository;

    @Mock
    private ProductRepository productRepository;

    @Mock
    private ProfileRepository profileRepository;

    @Mock
    private NotificationRepository notificationRepository;

    @InjectMocks
    private ProductReportService productReportService;

    private UUID userId;
    private Product product;
    private ProductReport report;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        product = Product.builder()
                .productNumber(10)
                .productName("Milk")
                .barcode("123456789")
                .build();

        report = ProductReport.builder()
                .reportNumber(100)
                .productNumber(10)
                .reportedBy(userId)
                .reportType("INVENTORY_ISSUE")
                .issueType("DAMAGED")
                .quantity(BigDecimal.valueOf(2))
                .description("Leaking container")
                .status("PENDING")
                .createdAt(LocalDateTime.now())
                .build();
    }

    @Test
    void testCreateInventoryIssue_Success() {
        CreateProductReportDTO dto = CreateProductReportDTO.builder()
                .productNumber(10)
                .issueType("DAMAGED")
                .quantity(BigDecimal.valueOf(2))
                .description("Leaking container")
                .build();

        when(productRepository.findById(10)).thenReturn(Optional.of(product));
        when(productReportRepository.save(any(ProductReport.class))).thenReturn(report);
        
        Profile activeStockController = Profile.builder().userId(UUID.randomUUID()).build();
        when(profileRepository.findActiveByRoleNumber(3)).thenReturn(Collections.singletonList(activeStockController));

        ProductReportDTO result = productReportService.createInventoryIssue(dto, userId);

        assertNotNull(result);
        assertEquals("DAMAGED", result.getIssueType());
        assertEquals("Milk", result.getProductName());
        verify(productReportRepository, times(1)).save(any(ProductReport.class));
        verify(notificationRepository, times(1)).save(any(Notification.class));
    }

    @Test
    void testCreateInventoryIssue_ProductNotFound_ThrowsException() {
        CreateProductReportDTO dto = CreateProductReportDTO.builder()
                .productNumber(99)
                .issueType("DAMAGED")
                .quantity(BigDecimal.valueOf(2))
                .build();

        when(productRepository.findById(99)).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class, () -> productReportService.createInventoryIssue(dto, userId));
    }

    @Test
    void testCreateInventoryIssue_InvalidQuantity_ThrowsException() {
        CreateProductReportDTO dto = CreateProductReportDTO.builder()
                .productNumber(10)
                .issueType("DAMAGED")
                .quantity(BigDecimal.valueOf(-1)) // Negative quantity
                .build();

        assertThrows(IllegalArgumentException.class, () -> productReportService.createInventoryIssue(dto, userId));
    }

    @Test
    void testCreateUpdateSuggestion_Success() {
        SuggestProductUpdateDTO dto = SuggestProductUpdateDTO.builder()
                .productNumber(10)
                .suggestedName("Skimmed Milk")
                .suggestedSellingPrice(BigDecimal.valueOf(12000))
                .reason("Competitor lower price")
                .build();

        when(productRepository.findById(10)).thenReturn(Optional.of(product));
        
        ProductReport suggestionReport = ProductReport.builder()
                .reportNumber(101)
                .productNumber(10)
                .reportedBy(userId)
                .reportType("UPDATE_SUGGESTION")
                .description("Name: Skimmed Milk; Selling price: 12000; Reason: Competitor lower price")
                .status("PENDING")
                .build();

        when(productReportRepository.save(any(ProductReport.class))).thenReturn(suggestionReport);

        Profile activeManager = Profile.builder().userId(UUID.randomUUID()).build();
        when(profileRepository.findActiveByRoleNumber(2)).thenReturn(Collections.singletonList(activeManager));

        ProductReportDTO result = productReportService.createUpdateSuggestion(dto, userId);

        assertNotNull(result);
        assertEquals("UPDATE_SUGGESTION", result.getReportType());
        assertTrue(result.getDescription().contains("Skimmed Milk"));
    }

    @Test
    void testCreateUpdateSuggestion_NoChanges_ThrowsException() {
        SuggestProductUpdateDTO dto = SuggestProductUpdateDTO.builder()
                .productNumber(10)
                .build(); // No fields set

        when(productRepository.findById(10)).thenReturn(Optional.of(product));

        assertThrows(IllegalArgumentException.class, () -> productReportService.createUpdateSuggestion(dto, userId));
    }

    @Test
    void testGetUserReports_All_Success() {
        when(productReportRepository.findByReportedByOrderByCreatedAtDesc(userId))
                .thenReturn(Collections.singletonList(report));
        when(productRepository.findById(10)).thenReturn(Optional.of(product));

        List<ProductReportDTO> result = productReportService.getUserReports(userId, null);

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("Milk", result.get(0).getProductName());
    }

    @Test
    void testGetUserReports_Filtered_Success() {
        when(productReportRepository.findByReportedByAndReportTypeOrderByCreatedAtDesc(userId, "INVENTORY_ISSUE"))
                .thenReturn(Collections.singletonList(report));
        when(productRepository.findById(10)).thenReturn(Optional.of(product));

        List<ProductReportDTO> result = productReportService.getUserReports(userId, "INVENTORY_ISSUE");

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("INVENTORY_ISSUE", result.get(0).getReportType());
    }

    @Test
    void testGetReport_Success() {
        when(productReportRepository.findById(100)).thenReturn(Optional.of(report));
        when(productRepository.findById(10)).thenReturn(Optional.of(product));

        ProductReportDTO result = productReportService.getReport(100, userId);

        assertNotNull(result);
        assertEquals("DAMAGED", result.getIssueType());
    }

    @Test
    void testGetReport_NotOwner_ThrowsSecurityException() {
        when(productReportRepository.findById(100)).thenReturn(Optional.of(report));

        assertThrows(SecurityException.class, () -> productReportService.getReport(100, UUID.randomUUID()));
    }
}
