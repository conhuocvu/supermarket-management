package com.supermarket.backend.repository;

import com.supermarket.backend.entity.InventoryTransaction;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface InventoryTransactionRepository extends JpaRepository<InventoryTransaction, Integer> {

    @Query("SELECT t FROM InventoryTransaction t JOIN FETCH t.product ORDER BY t.createdAt DESC")
    List<InventoryTransaction> findRecentTransactions(Pageable pageable);

    List<InventoryTransaction> findByProductProductNumberOrderByCreatedAtDesc(Integer productNumber);
}
