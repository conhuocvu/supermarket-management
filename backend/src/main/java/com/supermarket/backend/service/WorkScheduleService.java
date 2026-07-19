package com.supermarket.backend.service;

import com.supermarket.backend.dto.WorkScheduleDTO;
import com.supermarket.backend.repository.ProfileRepository;
import com.supermarket.backend.repository.WorkScheduleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class WorkScheduleService {

    private final WorkScheduleRepository workScheduleRepository;
    private final ProfileRepository profileRepository;

    /**
     * Assigned shifts for a month, straight from work_schedules joined with
     * shifts. Status is the schedule_status enum value stored on the row
     * (ASSIGNED / COMPLETED / CANCELLED / MISSED).
     */
    public List<WorkScheduleDTO> getMonthlySchedule(UUID userId, int year, int month) {
        verifyActiveAccount(userId);

        LocalDate start = LocalDate.of(year, month, 1);
        LocalDate end = start.withDayOfMonth(start.lengthOfMonth());

        return workScheduleRepository.findScheduleForPeriod(userId, start, end)
                .stream()
                .map(row -> WorkScheduleDTO.builder()
                        .scheduleNumber(row.getScheduleNumber())
                        .workDate(row.getWorkDate())
                        .status(row.getStatus())
                        .shiftNumber(row.getShiftNumber())
                        .shiftName(row.getShiftName())
                        .startTime(row.getStartTime())
                        .endTime(row.getEndTime())
                        .build())
                .toList();
    }

    private void verifyActiveAccount(UUID userId) {
        String status = profileRepository.checkAccountStatus(userId);
        if (status == null) {
            throw new IllegalArgumentException("Profile not found");
        }
        if (!"ACTIVE".equalsIgnoreCase(status)) {
            throw new SecurityException("Account inactive");
        }
    }
}
