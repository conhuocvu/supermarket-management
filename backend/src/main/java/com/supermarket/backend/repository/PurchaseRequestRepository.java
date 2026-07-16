package com.supermarket.backend.repository;

import com.supermarket.backend.entity.PurchaseRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import jakarta.persistence.LockModeType;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PurchaseRequestRepository extends JpaRepository<PurchaseRequest, Integer> {

    long countByStatus(String status);
    
    Optional<PurchaseRequest> findByCreatedByAndStatus(UUID createdBy, String status);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT pr FROM PurchaseRequest pr WHERE pr.purchaseRequestNumber = ?1")
    Optional<PurchaseRequest> findByIdForUpdate(Integer prNumber);
}

