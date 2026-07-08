package com.supermarket.backend.repository;

import com.supermarket.backend.entity.ProductSupplier;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProductSupplierRepository extends JpaRepository<ProductSupplier, Integer> {
    List<ProductSupplier> findByProductNumber(Integer productNumber);
}
