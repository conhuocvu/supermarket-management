package com.supermarket.backend.service;

import com.supermarket.backend.dto.ManagerDashboardDataDTO;
import com.supermarket.backend.dto.RecentActivityDTO;
import com.supermarket.backend.repository.InventoryRepository;
import com.supermarket.backend.repository.ManagerDashboardRepository;
import com.supermarket.backend.repository.ProductRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class ManagerDashboardServiceTests {

    @Mock
    private ProductRepository productRepository;

    @Mock
    private InventoryRepository inventoryRepository;

    @Mock
    private ManagerDashboardRepository managerDashboardRepository;

    @InjectMocks
    private ManagerDashboardService managerDashboardService;

    @Test
    void testGetManagerDashboardData_Success() {
        // Setup base repository mocks
        when(productRepository.count()).thenReturn(10L);
        when(inventoryRepository.countLowStock()).thenReturn(2L);
        when(managerDashboardRepository.countStaff()).thenReturn(15L);
        when(managerDashboardRepository.countCustomers()).thenReturn(150L);
        when(managerDashboardRepository.countSuppliers()).thenReturn(8L);
        when(managerDashboardRepository.sumTotalRevenue()).thenReturn(500000.0);
        when(managerDashboardRepository.sumRevenueToday()).thenReturn(12000.0);
        when(managerDashboardRepository.countActiveOrdersToday()).thenReturn(18L);

        // Weekly revenue mock
        List<Object[]> weeklyData = new ArrayList<>();
        weeklyData.add(new Object[]{LocalDate.now(), 5000.0});
        weeklyData.add(new Object[]{LocalDate.now().minusDays(1), 7000.0});
        when(managerDashboardRepository.getWeeklyRevenue(any(LocalDate.class))).thenReturn(weeklyData);

        // Distribution mock
        List<Object[]> distData = new ArrayList<>();
        distData.add(new Object[]{"Fresh Food", 40.0});
        distData.add(new Object[]{"Beverages", 60.0});
        when(managerDashboardRepository.getInventoryDistribution()).thenReturn(distData);

        // Recent Activities mocks
        LocalDateTime time = LocalDateTime.now();
        
        List<Object[]> promoData = new ArrayList<>();
        promoData.add(new Object[]{"Summer Sale", 20.0, Timestamp.valueOf(time.minusHours(1))});
        when(managerDashboardRepository.findRecentPromotions()).thenReturn(promoData);

        List<Object[]> deliveryData = new ArrayList<>();
        deliveryData.add(new Object[]{"Pepsi Co", Timestamp.valueOf(time.minusHours(2))});
        when(managerDashboardRepository.findRecentDeliveries()).thenReturn(deliveryData);

        List<Object[]> staffData = new ArrayList<>();
        staffData.add(new Object[]{"Nguyen Van A", "Cashier", Timestamp.valueOf(time.minusHours(3))});
        when(managerDashboardRepository.findRecentProfiles()).thenReturn(staffData);

        List<Object[]> reportData = new ArrayList<>();
        reportData.add(new Object[]{"Damaged Milk Carton", Timestamp.valueOf(time.minusHours(4))});
        when(managerDashboardRepository.findRecentReports()).thenReturn(reportData);

        // Run
        ManagerDashboardDataDTO data = managerDashboardService.getManagerDashboardData();

        // Verify counts
        assertNotNull(data);
        assertEquals(10L, data.getTotalProducts());
        assertEquals(15L, data.getTotalStaff());
        assertEquals(150L, data.getTotalCustomers());
        assertEquals(8L, data.getTotalSuppliers());
        assertEquals(500000.0, data.getTotalRevenue());
        assertEquals(12000.0, data.getRevenueToday());
        assertEquals(18L, data.getActiveOrdersCount());

        // Stock Level Calculation: ((10 - 2) / 10) * 100 = 80.0
        assertEquals(80.0, data.getStockLevel());
        assertEquals(2L, data.getLowStockCount());

        // Distribution Check
        assertEquals(2, data.getInventoryDistribution().size());
        assertEquals("Fresh Food", data.getInventoryDistribution().get(0).getCategoryName());
        assertEquals(40.0, data.getInventoryDistribution().get(0).getPercentage());
        assertEquals("Beverages", data.getInventoryDistribution().get(1).getCategoryName());
        assertEquals(60.0, data.getInventoryDistribution().get(1).getPercentage());

        // Activities sorted by time and capped to 5
        assertEquals(4, data.getRecentActivities().size());
        assertEquals("Promotion Scheduled", data.getRecentActivities().get(0).getAction());
        assertEquals("Supplier Delivery Received", data.getRecentActivities().get(1).getAction());
        assertEquals("New Staff Onboarded", data.getRecentActivities().get(2).getAction());
        assertEquals("Inventory Warning", data.getRecentActivities().get(3).getAction());
    }
}
