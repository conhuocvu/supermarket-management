package com.supermarket.backend.controller;

import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.dto.ManagerDashboardDataDTO;
import com.supermarket.backend.service.ManagerDashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/manager")
@RequiredArgsConstructor
public class ManagerDashboardController {

    private final ManagerDashboardService managerDashboardService;

    @GetMapping("/dashboard")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<ManagerDashboardDataDTO>> getDashboardData() {
        ManagerDashboardDataDTO dashboardData = managerDashboardService.getManagerDashboardData();
        return ResponseEntity.ok(ApiResponse.success("Manager dashboard data loaded successfully.", dashboardData));
    }
}
