package com.supermarket.backend.repository;

import com.supermarket.backend.entity.Promotion;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PromotionRepository extends JpaRepository<Promotion, Long> {

    List<Promotion> findByStatusIgnoreCase(String status);

    Page<Promotion> findByStatusIgnoreCase(String status, Pageable pageable);

    List<Promotion> findByPromotionNameContainingIgnoreCaseOrPromoCodeContainingIgnoreCase(String nameKeyword, String codeKeyword);

    Page<Promotion> findByPromotionNameContainingIgnoreCaseOrPromoCodeContainingIgnoreCase(String nameKeyword, String codeKeyword, Pageable pageable);

    List<Promotion> findByStatusIgnoreCaseAndPromotionNameContainingIgnoreCaseOrStatusIgnoreCaseAndPromoCodeContainingIgnoreCase(
            String status1, String nameKeyword, String status2, String codeKeyword);

    Page<Promotion> findByStatusIgnoreCaseAndPromotionNameContainingIgnoreCaseOrStatusIgnoreCaseAndPromoCodeContainingIgnoreCase(
            String status1, String nameKeyword, String status2, String codeKeyword, Pageable pageable);

    java.util.Optional<Promotion> findByPromotionNumber(Integer promotionNumber);

    @Query(value = "SELECT p.product_name, p.barcode, p.selling_price " +
                   "FROM products p " +
                   "JOIN promotion_products pp ON p.product_number = pp.product_number " +
                   "WHERE pp.promotion_number = :promotionNumber",
           nativeQuery = true)
    List<Object[]> findAssociatedProducts(@Param("promotionNumber") Integer promotionNumber);

    @Query(value = "SELECT COALESCE(MAX(promotion_number), 0) FROM promotions", nativeQuery = true)
    Integer findMaxPromotionNumber();
}
