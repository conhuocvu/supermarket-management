package com.supermarket.backend.controller;

import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.dto.ReportsDashboardDTO;
import com.supermarket.backend.service.ReportsService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.Map;

@RestController
@RequestMapping("/api/reports")
@RequiredArgsConstructor
@PreAuthorize("hasRole('MANAGER')")
public class ReportsController {

    private final ReportsService reportsService;

    @GetMapping("/dashboard")
    public ResponseEntity<ApiResponse<ReportsDashboardDTO>> getDashboardData(
            @RequestParam(value = "startDate", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(value = "endDate", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {

        ReportsDashboardDTO data = reportsService.getDashboardData(startDate, endDate);
        return ResponseEntity.ok(ApiResponse.success("Reports dashboard data loaded successfully.", data));
    }

    @GetMapping("/dashboard/download")
    public ResponseEntity<byte[]> downloadPdf(
            @RequestParam(value = "startDate", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(value = "endDate", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {

        ReportsDashboardDTO data = reportsService.getDashboardData(startDate, endDate);
        
        // Generate a text report structured like a PDF and send as PDF mime-type
        StringBuilder sb = new StringBuilder();
        sb.append("%PDF-1.4\n"); // Simple mock PDF header
        sb.append("1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n");
        sb.append("2 0 obj\n<< /Type /Pages /Kids [ 3 0 R ] /Count 1 >>\nendobj\n");
        sb.append("3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [ 0 0 612 792 ] /Contents 4 0 R >>\nendobj\n");
        sb.append("4 0 obj\n<< /Length 200 >>\nstream\n");
        sb.append("BT\n/F1 12 Tf\n72 712 Td\n(Store #402 - Financial and Operational Report) Tj\n");
        sb.append("0 -20 Td\n(Date Range: ").append(startDate).append(" to ").append(endDate).append(") Tj\n");
        sb.append("0 -30 Td\n(Gross Sales: $").append(String.format("%.2f", data.getStatistics().getGrossSales())).append(") Tj\n");
        sb.append("0 -20 Td\n(Average Basket: $").append(String.format("%.2f", data.getStatistics().getAvgBasket())).append(") Tj\n");
        sb.append("0 -20 Td\n(Stock Turn: ").append(data.getStatistics().getStockTurn()).append("x) Tj\n");
        sb.append("0 -20 Td\n(Foot Traffic: ").append(data.getStatistics().getFootTraffic()).append(" patrons) Tj\n");
        sb.append("ET\nendstream\nendobj\nxref\n0 5\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \n0000000212 00000 n \ntrailer\n<< /Size 5 /Root 1 0 R >>\nstartxref\n465\n%%EOF\n");

        byte[] pdfBytes = sb.toString().getBytes();

        return ResponseEntity.ok()
                .header("Content-Disposition", "attachment; filename=\"reports_summary.pdf\"")
                .contentType(MediaType.APPLICATION_PDF)
                .body(pdfBytes);
    }
}
