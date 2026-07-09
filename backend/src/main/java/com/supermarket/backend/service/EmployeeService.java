package com.supermarket.backend.service;

import com.supermarket.backend.dto.*;
import com.supermarket.backend.model.Certification;
import com.supermarket.backend.model.Employee;
import com.supermarket.backend.model.Shift;
import com.supermarket.backend.repository.CertificationRepository;
import com.supermarket.backend.repository.EmployeeRepository;
import com.supermarket.backend.repository.ShiftRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class EmployeeService {

    private final EmployeeRepository employeeRepository;
    private final ShiftRepository shiftRepository;
    private final CertificationRepository certificationRepository;

    @Autowired
    public EmployeeService(EmployeeRepository employeeRepository,
                           ShiftRepository shiftRepository,
                           CertificationRepository certificationRepository) {
        this.employeeRepository = employeeRepository;
        this.shiftRepository = shiftRepository;
        this.certificationRepository = certificationRepository;
    }

    public List<EmployeeDto> getAllEmployees(String search, String status) {
        List<Employee> employees;

        boolean hasSearch = search != null && !search.trim().isEmpty();
        boolean hasStatus = status != null && !status.trim().isEmpty() && !status.equalsIgnoreCase("ALL");

        if (hasSearch && hasStatus) {
            employees = employeeRepository.findByStatusAndNameContainingIgnoreCase(status.toUpperCase(), search.trim());
        } else if (hasSearch) {
            employees = employeeRepository.findByNameContainingIgnoreCase(search.trim());
        } else if (hasStatus) {
            employees = employeeRepository.findByStatus(status.toUpperCase());
        } else {
            employees = employeeRepository.findAll();
        }

        return employees.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public EmployeeDto getEmployeeById(Long id) {
        Employee employee = employeeRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Employee not found with id: " + id));
        return convertToDto(employee);
    }

    public EmployeeStatsDto getEmployeeStats() {
        int totalStaff = (int) employeeRepository.count();
        // For 'live' on shift, count employees who have status ON_DUTY
        int onShift = (int) employeeRepository.countByStatus("ON_DUTY");
        
        return EmployeeStatsDto.builder()
                .totalStaffCount(totalStaff)
                .onShiftCount(onShift)
                .staffCountGrowth("+3 this month") // Mock dynamic text or compute based on recent hires
                .build();
    }

    public EmployeeDto createEmployee(EmployeeCreateDto dto) {
        if (employeeRepository.existsByEmailIgnoreCase(dto.getEmail())) {
            throw new IllegalArgumentException("Email already exists: " + dto.getEmail());
        }

        Employee employee = Employee.builder()
                .name(dto.getName())
                .email(dto.getEmail())
                .phone(dto.getPhone())
                .location(dto.getLocation())
                .role(dto.getRole().toUpperCase())
                .status("OFF_DUTY") // Default to Off Duty initially
                .joinedDate(LocalDate.now())
                .attendanceRate(100.0) // initial
                .completedShifts(0)
                .performanceScore(5.0) // default initial
                .imageUrl(dto.getImageUrl() != null ? dto.getImageUrl() : "")
                .build();

        Employee saved = employeeRepository.save(employee);
        return convertToDto(saved);
    }

    public EmployeeDto updateEmployeeRole(Long id, String role) {
        validateManagerOrAdmin();

        Employee employee = employeeRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Employee not found with id: " + id));

        employee.setRole(role.toUpperCase());
        Employee saved = employeeRepository.save(employee);
        return convertToDto(saved);
    }

    public ShiftDto assignShift(Long employeeId, ShiftAssignDto dto) {
        validateManagerOrAdmin();

        Employee employee = employeeRepository.findById(employeeId)
                .orElseThrow(() -> new IllegalArgumentException("Employee not found with id: " + employeeId));

        if ("ON_LEAVE".equalsIgnoreCase(employee.getStatus())) {
            throw new IllegalArgumentException("Employee is currently on leave and cannot be scheduled.");
        }

        // Overlap Check
        List<Shift> existingShifts = shiftRepository.findByEmployeeIdAndDate(employeeId, dto.getDate());
        for (Shift existing : existingShifts) {
            if (isOverlapping(dto.getStartTime(), dto.getEndTime(), existing.getStartTime(), existing.getEndTime())) {
                throw new IllegalArgumentException("Shift overlaps with another scheduled shift on " + dto.getDate());
            }
        }

        Shift shift = Shift.builder()
                .employee(employee)
                .date(dto.getDate())
                .startTime(dto.getStartTime())
                .endTime(dto.getEndTime())
                .shiftType(dto.getShiftType().toUpperCase())
                .register(dto.getRegister())
                .completed(false) // Scheduled shifts are initially incomplete
                .build();

        Shift saved = shiftRepository.save(shift);
        return convertToShiftDto(saved);
    }

    // Helper: Permission check
    private void validateManagerOrAdmin() {
        org.springframework.security.core.Authentication authentication = 
                org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new IllegalArgumentException("Permission Denied: Unauthenticated user.");
        }
        boolean isManagerOrAdmin = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equalsIgnoreCase("ROLE_ADMIN") || a.getAuthority().equalsIgnoreCase("ROLE_MANAGER"));
        if (!isManagerOrAdmin) {
            throw new IllegalArgumentException("Permission Denied: Only Admins or Managers can perform this action.");
        }
    }

    // Helper: Time overlap calculation
    private boolean isOverlapping(LocalTime start1, LocalTime end1, LocalTime start2, LocalTime end2) {
        return start1.isBefore(end2) && start2.isBefore(end1);
    }

    // Convert Entity to DTO
    private EmployeeDto convertToDto(Employee employee) {
        List<Shift> shifts = shiftRepository.findByEmployeeIdOrderByDateDescStartTimeDesc(employee.getId());
        List<Certification> certs = certificationRepository.findByEmployeeId(employee.getId());

        List<ShiftDto> shiftDtos = shifts.stream()
                .map(this::convertToShiftDto)
                .collect(Collectors.toList());

        List<CertificationDto> certDtos = certs.stream()
                .map(this::convertToCertDto)
                .collect(Collectors.toList());

        String employeeCode = "EMP-" + String.format("%03d", employee.getId());

        return EmployeeDto.builder()
                .id(employee.getId())
                .employeeCode(employeeCode)
                .name(employee.getName())
                .email(employee.getEmail())
                .phone(employee.getPhone())
                .location(employee.getLocation())
                .joinedDate(employee.getJoinedDate())
                .role(employee.getRole())
                .status(employee.getStatus())
                .attendanceRate(employee.getAttendanceRate())
                .completedShifts(employee.getCompletedShifts())
                .performanceScore(employee.getPerformanceScore())
                .managersNote(employee.getManagersNote())
                .returnsDate(employee.getReturnsDate())
                .imageUrl(employee.getImageUrl())
                .recentShifts(shiftDtos)
                .certifications(certDtos)
                .build();
    }

    private ShiftDto convertToShiftDto(Shift shift) {
        return ShiftDto.builder()
                .id(shift.getId())
                .date(shift.getDate())
                .startTime(shift.getStartTime())
                .endTime(shift.getEndTime())
                .shiftType(shift.getShiftType())
                .register(shift.getRegister())
                .completed(shift.isCompleted())
                .build();
    }

    private CertificationDto convertToCertDto(Certification cert) {
        return CertificationDto.builder()
                .id(cert.getId())
                .name(cert.getName())
                .obtainedDate(cert.getObtainedDate())
                .expiryDate(cert.getExpiryDate())
                .build();
    }
}
