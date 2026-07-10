package com.supermarket.backend.repository;

import com.supermarket.backend.entity.Inventory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import jakarta.persistence.LockModeType;
import java.util.Optional;

@Repository
public interface InventoryRepository extends JpaRepository<Inventory, Integer> {

    @Query("SELECT COUNT(i) FROM Inventory i WHERE i.availableQuantity <= i.product.reorderLevel")
    long countLowStock();

    @Query("SELECT SUM(i.availableQuantity) FROM Inventory i")
    java.math.BigDecimal sumAvailableQuantity();

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT i FROM Inventory i WHERE i.productNumber = ?1")
    Optional<Inventory> findByIdForUpdate(Integer productNumber);
}

