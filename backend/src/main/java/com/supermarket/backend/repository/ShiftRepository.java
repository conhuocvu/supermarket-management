package com.supermarket.backend.repository;

import com.supermarket.backend.model.Shift;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.util.List;

@Repository
public interface ShiftRepository extends JpaRepository<Shift, Long> {
    
    List<Shift> findByEmployeeIdOrderByDateDescStartTimeDesc(Long employeeId);
    
    List<Shift> findByEmployeeIdAndDate(Long employeeId, LocalDate date);
    
    List<Shift> findByDate(LocalDate date);
}
