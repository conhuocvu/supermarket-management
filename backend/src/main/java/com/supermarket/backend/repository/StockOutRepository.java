package com.supermarket.backend.repository;

import com.supermarket.backend.entity.StockOut;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface StockOutRepository extends JpaRepository<StockOut, Integer> {
}
