package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PendingTasksDTO {
    private List<PendingStockInDTO> pendingStockIns;
    private List<PendingStockOutDTO> pendingStockOuts;
}
