package com.supermarket.backend.repository;

import com.supermarket.backend.entity.Promotion;
import com.supermarket.backend.entity.PromotionStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PromotionRepository extends JpaRepository<Promotion, Long> {

    List<Promotion> findByStatus(PromotionStatus status);

    List<Promotion> findByCategoryOrderByPromotionNumberDesc(String category);

    Page<Promotion> findByStatus(PromotionStatus status, Pageable pageable);

    List<Promotion> findByPromotionNameContainingIgnoreCaseOrPromoCodeContainingIgnoreCase(String nameKeyword, String codeKeyword);

    Page<Promotion> findByPromotionNameContainingIgnoreCaseOrPromoCodeContainingIgnoreCase(String nameKeyword, String codeKeyword, Pageable pageable);

    List<Promotion> findByStatusAndPromotionNameContainingIgnoreCaseOrStatusAndPromoCodeContainingIgnoreCase(
            PromotionStatus status1, String nameKeyword, PromotionStatus status2, String codeKeyword);

    Page<Promotion> findByStatusAndPromotionNameContainingIgnoreCaseOrStatusAndPromoCodeContainingIgnoreCase(
            PromotionStatus status1, String nameKeyword, PromotionStatus status2, String codeKeyword, Pageable pageable);

    java.util.Optional<Promotion> findByPromotionNumber(Integer promotionNumber);

    long countByStatus(PromotionStatus status);

    @Query("SELECT AVG(p.discountValue) FROM Promotion p")
    Double getAverageDiscountValue();

    @Query(value = "SELECT p.product_name, p.barcode, p.selling_price " +
                   "FROM products p " +
                   "JOIN promotion_products pp ON p.product_number = pp.product_number " +
                   "WHERE pp.promotion_number = :promotionNumber",
           nativeQuery = true)
    List<Object[]> findAssociatedProducts(@Param("promotionNumber") Integer promotionNumber);

    @Query(value = "SELECT COALESCE(MAX(promotion_number), 0) FROM promotions", nativeQuery = true)
    Integer findMaxPromotionNumber();
}
