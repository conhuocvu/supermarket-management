package com.supermarket.backend.repository;

import com.supermarket.backend.entity.ProductReport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ProductReportRepository extends JpaRepository<ProductReport, Integer> {

    @Query("SELECT r FROM ProductReport r " +
            "WHERE r.reportType = 'DELIVERY_DISCREPANCY' " +
            "AND r.productNumber = :productNumber " +
            "AND r.stockInDetailNumber IS NULL " +
            "AND r.description LIKE :descriptionPrefix")
    List<ProductReport> findDeliveryDiscrepancies(
            @Param("productNumber") Integer productNumber,
            @Param("descriptionPrefix") String descriptionPrefix);
}
