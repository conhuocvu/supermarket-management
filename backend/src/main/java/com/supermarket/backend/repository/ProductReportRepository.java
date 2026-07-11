package com.supermarket.backend.repository;

import com.supermarket.backend.entity.ProductReport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ProductReportRepository extends JpaRepository<ProductReport, Integer> {
}
