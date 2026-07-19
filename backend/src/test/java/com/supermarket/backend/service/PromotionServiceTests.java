package com.supermarket.backend.service;

import com.supermarket.backend.dto.PromotionDTO;
import com.supermarket.backend.dto.PromotionSummaryDTO;
import com.supermarket.backend.entity.Promotion;
import com.supermarket.backend.entity.PromotionStatus;
import com.supermarket.backend.repository.PromotionRepository;
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

import java.time.LocalDate;
import java.util.Collections;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class PromotionServiceTests {

    @Mock
    private PromotionRepository promotionRepository;

    @InjectMocks
    private PromotionService promotionService;

    private Promotion promotion;

    @BeforeEach
    void setUp() {
        promotion = Promotion.builder()
                .id(1L)
                .promotionNumber(1)
                .promotionName("Summer Sale")
                .discountValue(15.0)
                .status(PromotionStatus.ACTIVE)
                .startDate(LocalDate.now())
                .endDate(LocalDate.now().plusDays(10))
                .build();
    }

    @Test
    void testGetPromotionsSummary_Success() {
        Pageable pageable = PageRequest.of(0, 10);
        Page<Promotion> page = new PageImpl<>(Collections.singletonList(promotion));

        // Mock repository calls
        when(promotionRepository.findAll(any(Pageable.class))).thenReturn(page);
        when(promotionRepository.countByStatus(PromotionStatus.ACTIVE)).thenReturn(5L);
        when(promotionRepository.countByStatus(PromotionStatus.SCHEDULED)).thenReturn(2L);
        when(promotionRepository.countByStatus(PromotionStatus.EXPIRED)).thenReturn(3L);
        when(promotionRepository.getAverageDiscountValue()).thenReturn(15.0);

        PromotionSummaryDTO summary = promotionService.getPromotionsSummary(null, "ALL", pageable);

        assertNotNull(summary);
        assertEquals(1, summary.getPromotions().size());
        assertEquals(5, summary.getActiveCount());
        assertEquals(2, summary.getScheduledCount());
        assertEquals(3, summary.getExpiredCount());
        assertEquals(15.0, summary.getAvgDiscount());

        // Verify no findAll() was run for fetching counts (O(N) full table scan removed)
        verify(promotionRepository, never()).findAll();
    }

    @Test
    void testDeactivatePromotion_Success() {
        when(promotionRepository.findByPromotionNumber(1)).thenReturn(Optional.of(promotion));
        when(promotionRepository.save(any(Promotion.class))).thenReturn(promotion);

        promotionService.deactivatePromotion(1);

        assertEquals(PromotionStatus.EXPIRED, promotion.getStatus());
        verify(promotionRepository, times(1)).save(promotion);
    }
}
