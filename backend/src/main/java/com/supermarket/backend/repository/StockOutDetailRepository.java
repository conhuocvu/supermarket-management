package com.supermarket.backend.repository;

import com.supermarket.backend.entity.StockOutDetail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface StockOutDetailRepository extends JpaRepository<StockOutDetail, Integer> {
    List<StockOutDetail> findByStockOutNumber(Integer stockOutNumber);
}
