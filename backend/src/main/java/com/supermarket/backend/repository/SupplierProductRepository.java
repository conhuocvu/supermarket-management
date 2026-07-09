package com.supermarket.backend.repository;

import com.supermarket.backend.model.SupplierProduct;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SupplierProductRepository extends JpaRepository<SupplierProduct, Long> {
    List<SupplierProduct> findBySupplierId(Long supplierId);
    Optional<SupplierProduct> findBySupplierIdAndProductId(Long supplierId, Long productId);
    void deleteBySupplierId(Long supplierId);
    void deleteBySupplierIdAndProductId(Long supplierId, Long productId);

    @Query("SELECT COUNT(sp) FROM SupplierProduct sp WHERE sp.supplier.id = :supplierId")
    int countActiveSkusBySupplierId(@Param("supplierId") Long supplierId);
}
