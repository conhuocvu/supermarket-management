package com.supermarket.backend.repository;

import com.supermarket.backend.model.Employee;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface EmployeeRepository extends JpaRepository<Employee, Long> {
    
    List<Employee> findByNameContainingIgnoreCase(String name);
    
    List<Employee> findByStatus(String status);
    
    List<Employee> findByStatusAndNameContainingIgnoreCase(String status, String name);
    
    long countByStatus(String status);

    boolean existsByEmailIgnoreCase(String email);
}
