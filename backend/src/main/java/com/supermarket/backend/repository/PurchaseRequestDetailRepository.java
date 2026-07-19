package com.supermarket.backend.repository;

import com.supermarket.backend.entity.PurchaseRequestDetail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PurchaseRequestDetailRepository extends JpaRepository<PurchaseRequestDetail, Integer> {
    List<PurchaseRequestDetail> findByPurchaseRequestNumber(Integer purchaseRequestNumber);
    void deleteByPurchaseRequestNumber(Integer purchaseRequestNumber);
}
