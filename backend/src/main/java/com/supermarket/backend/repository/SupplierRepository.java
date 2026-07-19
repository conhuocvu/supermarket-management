package com.supermarket.backend.repository;

import com.supermarket.backend.entity.Supplier;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

@Repository
public interface SupplierRepository extends JpaRepository<Supplier, Integer> {

    @Query("SELECT s FROM Supplier s WHERE " +
           "(:keyword IS NULL OR :keyword = '' OR " +
           " LOWER(s.supplierName) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
           " LOWER(s.phone) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
           " LOWER(s.email) LIKE LOWER(CONCAT('%', :keyword, '%'))) " +
           "AND (:status IS NULL OR s.status = :status)")
    Page<Supplier> searchSuppliers(
            @Param("keyword") String keyword,
            @Param("status") String status,
            Pageable pageable);
}
