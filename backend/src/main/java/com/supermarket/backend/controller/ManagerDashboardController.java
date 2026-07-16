package com.supermarket.backend.controller;

import com.supermarket.backend.dto.ManagerDashboardDataDTO;
import com.supermarket.backend.service.ManagerDashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/manager")
@RequiredArgsConstructor
public class ManagerDashboardController {

    private final ManagerDashboardService managerDashboardService;

    @GetMapping("/dashboard")
    public ResponseEntity<Map<String, Object>> getDashboardData() {
        ManagerDashboardDataDTO dashboardData = managerDashboardService.getManagerDashboardData();

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Manager dashboard data loaded successfully.");
        response.put("data", dashboardData);

        return ResponseEntity.ok(response);
    }
}
