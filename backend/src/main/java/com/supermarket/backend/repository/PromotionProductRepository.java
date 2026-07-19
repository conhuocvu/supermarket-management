package com.supermarket.backend.repository;

import com.supermarket.backend.entity.PromotionProduct;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PromotionProductRepository extends JpaRepository<PromotionProduct, Integer> {

    @Query("SELECT pp.stockInDetailNumber FROM PromotionProduct pp WHERE pp.stockInDetailNumber IS NOT NULL AND pp.status IN ('PENDING', 'ACTIVE', 'APPROVED')")
    List<Integer> findProposedStockInDetailNumbers();

    List<PromotionProduct> findByPromotionNumber(Integer promotionNumber);
}
