package com.supermarket.backend.repository;

import com.supermarket.backend.entity.StockInDetail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.util.List;

@Repository
public interface StockInDetailRepository extends JpaRepository<StockInDetail, Integer> {

    @Query("SELECT COUNT(s) FROM StockInDetail s WHERE s.remainingQuantity > 0 AND s.expiryDate >= :now AND s.expiryDate <= :threshold")
    long countNearExpiry(@Param("now") LocalDate now, @Param("threshold") LocalDate threshold);

    @Query("SELECT s FROM StockInDetail s WHERE s.productNumber = :productNumber AND s.remainingQuantity > 0 ORDER BY s.expiryDate ASC NULLS LAST")
    List<StockInDetail> findLatestStockInDetails(@Param("productNumber") Integer productNumber);

    @Query("SELECT s FROM StockInDetail s WHERE s.remainingQuantity > 0 ORDER BY s.expiryDate ASC NULLS LAST")
    List<StockInDetail> findAllActiveStockInDetails();

    @Query("SELECT s FROM StockInDetail s WHERE s.remainingQuantity > 0 AND s.expiryDate IS NOT NULL AND s.expiryDate <= :maxThreshold ORDER BY s.expiryDate ASC")
    List<StockInDetail> findExpiringStockInDetails(@Param("maxThreshold") LocalDate maxThreshold);

    @Query("SELECT s FROM StockInDetail s WHERE s.productNumber IN :productNumbers AND s.remainingQuantity > 0 ORDER BY s.expiryDate ASC NULLS LAST")
    List<StockInDetail> findActiveStockInDetailsByProductNumbers(@Param("productNumbers") List<Integer> productNumbers);
}

