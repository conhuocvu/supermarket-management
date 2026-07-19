package com.supermarket.backend.repository;

import com.supermarket.backend.entity.Product;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ProductRepository extends JpaRepository<Product, Integer> {

    @Query("SELECT p FROM Product p " +
           "LEFT JOIN FETCH p.category c " +
           "LEFT JOIN FETCH p.unit u " +
           "LEFT JOIN FETCH p.inventory i " +
           "WHERE (:keyword IS NULL OR :keyword = '' OR LOWER(p.productName) LIKE LOWER(CONCAT('%', :keyword, '%')) OR LOWER(p.barcode) LIKE LOWER(CONCAT('%', :keyword, '%'))) " +
           "AND (:categoryNumber IS NULL OR p.categoryNumber = :categoryNumber) " +
           "AND p.status <> 'DELETED'")
    Page<Product> findProducts(@Param("keyword") String keyword, 
                               @Param("categoryNumber") Integer categoryNumber, 
                               Pageable pageable);

    @Query("SELECT p FROM Product p " +
           "LEFT JOIN FETCH p.category c " +
           "LEFT JOIN FETCH p.unit u " +
           "LEFT JOIN FETCH p.inventory i " +
           "WHERE (:keyword IS NULL OR :keyword = '' OR LOWER(p.productName) LIKE LOWER(CONCAT('%', :keyword, '%')) OR LOWER(p.barcode) LIKE LOWER(CONCAT('%', :keyword, '%'))) " +
           "AND (:categoryNumber IS NULL OR p.categoryNumber = :categoryNumber) " +
           "AND p.status <> 'DELETED'")
    Page<Product> findInventoryProductsByCriteria(@Param("keyword") String keyword, 
                                                  @Param("categoryNumber") Integer categoryNumber, 
                                                  Pageable pageable);

    Product findByBarcode(String barcode);

    boolean existsByBarcode(String barcode);

    @Query("SELECT p FROM Product p " +
           "LEFT JOIN FETCH p.unit u " +
           "LEFT JOIN FETCH p.inventory i " +
           "WHERE p.status = :status")
    java.util.List<Product> findByStatusWithRelationships(@Param("status") String status);

    @Override
    @Query("SELECT p FROM Product p " +
           "LEFT JOIN FETCH p.unit u " +
           "LEFT JOIN FETCH p.inventory i " +
           "WHERE p.productNumber IN :ids")
    java.util.List<Product> findAllById(@Param("ids") Iterable<Integer> ids);
}



