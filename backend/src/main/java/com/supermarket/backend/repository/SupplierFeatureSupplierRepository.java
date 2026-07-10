package com.supermarket.backend.repository;

import com.supermarket.backend.model.Supplier;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SupplierFeatureSupplierRepository extends JpaRepository<Supplier, Long> {
    Optional<Supplier> findByCodeIgnoreCase(String code);
    boolean existsByCodeIgnoreCase(String code);
    boolean existsByCodeIgnoreCaseAndIdNot(String code, Long id);

    @Query("SELECT s FROM Supplier s " +
           "WHERE (:search IS NULL OR :search = '' OR LOWER(s.name) LIKE LOWER(CONCAT('%', :search, '%')) OR LOWER(s.code) LIKE LOWER(CONCAT('%', :search, '%'))) " +
           "AND (:category IS NULL OR :category = '' OR :category = 'ALL' OR LOWER(s.category) = LOWER(:category))")
    List<Supplier> searchSuppliers(@Param("search") String search, @Param("category") String category);
}
