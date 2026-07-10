package com.supermarket.backend.repository;

import com.supermarket.backend.model.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SupplierFeatureProductRepository extends JpaRepository<Product, Long> {
    Optional<Product> findBySkuIgnoreCase(String sku);
    boolean existsBySkuIgnoreCase(String sku);

    @Query("SELECT p FROM Product p " +
           "WHERE (:search IS NULL OR :search = '' OR LOWER(p.name) LIKE LOWER(CONCAT('%', :search, '%')) OR LOWER(p.sku) LIKE LOWER(CONCAT('%', :search, '%'))) " +
           "AND (:category IS NULL OR :category = '' OR :category = 'ALL' OR LOWER(p.category) = LOWER(:category))")
    List<Product> searchProducts(@Param("search") String search, @Param("category") String category);
}
