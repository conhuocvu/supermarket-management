package com.supermarket.backend.repository;

import com.supermarket.backend.entity.Promotion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PromotionRepository extends JpaRepository<Promotion, Long> {

    List<Promotion> findByStatusIgnoreCase(String status);

    List<Promotion> findByPromotionNameContainingIgnoreCaseOrPromoCodeContainingIgnoreCase(String nameKeyword, String codeKeyword);

    List<Promotion> findByStatusIgnoreCaseAndPromotionNameContainingIgnoreCaseOrStatusIgnoreCaseAndPromoCodeContainingIgnoreCase(
            String status1, String nameKeyword, String status2, String codeKeyword);
}
