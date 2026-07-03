package com.supermarket.backend.controller;

import com.supermarket.backend.dto.*;
import com.supermarket.backend.service.EmployeeService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/employees")
public class EmployeeController {

    private final EmployeeService employeeService;

    @Autowired
    public EmployeeController(EmployeeService employeeService) {
        this.employeeService = employeeService;
    }

    @GetMapping
    public ApiResponse<List<EmployeeDto>> getEmployees(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String status) {
        List<EmployeeDto> list = employeeService.getAllEmployees(search, status);
        return ApiResponse.success("Fetched employees successfully.", list);
    }

    @GetMapping("/stats")
    public ApiResponse<EmployeeStatsDto> getEmployeeStats() {
        EmployeeStatsDto stats = employeeService.getEmployeeStats();
        return ApiResponse.success("Fetched stats successfully.", stats);
    }

    @GetMapping("/{id}")
    public ApiResponse<EmployeeDto> getEmployeeById(@PathVariable Long id) {
        EmployeeDto employee = employeeService.getEmployeeById(id);
        return ApiResponse.success("Fetched employee details successfully.", employee);
    }

    @PostMapping
    public ApiResponse<EmployeeDto> createEmployee(
            @Valid @RequestBody EmployeeCreateDto dto) {
        EmployeeDto created = employeeService.createEmployee(dto);
        return ApiResponse.success("Employee hired successfully.", created);
    }

    @PatchMapping("/{id}/role")
    public ApiResponse<EmployeeDto> updateEmployeeRole(
            @PathVariable Long id,
            @Valid @RequestBody RoleUpdateDto dto,
            @RequestHeader(value = "X-User-Role", defaultValue = "MANAGER") String updaterRole) {
        EmployeeDto updated = employeeService.updateEmployeeRole(id, dto.getRole(), updaterRole);
        return ApiResponse.success("Employee role updated successfully.", updated);
    }

    @PostMapping("/{id}/shifts")
    public ApiResponse<ShiftDto> assignShift(
            @PathVariable Long id,
            @Valid @RequestBody ShiftAssignDto dto,
            @RequestHeader(value = "X-User-Role", defaultValue = "MANAGER") String updaterRole) {
        ShiftDto shift = employeeService.assignShift(id, dto, updaterRole);
        return ApiResponse.success("Shift assigned successfully.", shift);
    }
}
