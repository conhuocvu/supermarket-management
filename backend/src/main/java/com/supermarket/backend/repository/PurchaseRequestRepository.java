package com.supermarket.backend.repository;

import com.supermarket.backend.entity.PurchaseRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PurchaseRequestRepository extends JpaRepository<PurchaseRequest, Integer> {

    long countByStatus(String status);
    
    Optional<PurchaseRequest> findByCreatedByAndStatus(UUID createdBy, String status);
}

