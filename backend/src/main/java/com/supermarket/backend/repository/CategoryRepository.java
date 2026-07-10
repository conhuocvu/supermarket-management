package com.supermarket.backend.repository;

import com.supermarket.backend.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CategoryRepository extends JpaRepository<Category, Integer> {
    List<Category> findByStatus(String status);
    
    org.springframework.data.domain.Page<Category> findByCategoryNameContainingIgnoreCase(String name, org.springframework.data.domain.Pageable pageable);
    List<Category> findByParentCategoryNumber(Integer parentCategoryNumber);
    
    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.data.jpa.repository.Query("UPDATE Category c SET c.status = :status WHERE c.categoryNumber IN :ids")
    void updateStatusForIds(@org.springframework.data.repository.query.Param("ids") List<Integer> ids, @org.springframework.data.repository.query.Param("status") String status);
}
