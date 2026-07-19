package com.supermarket.backend.service;

import com.supermarket.backend.dto.*;
import com.supermarket.backend.exception.*;
import com.supermarket.backend.repository.StaffRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.TextStyle;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class StaffService {

    private final StaffRepository staffRepository;



    public StaffSummaryDTO getStaffList(String keyword, String workStatus, int page, int size) {
        try {
            String searchPattern = (keyword == null || keyword.trim().isEmpty()) ? null : keyword.trim();
            String statusFilter = (workStatus == null || workStatus.trim().isEmpty()) ? "ALL" : workStatus.trim();

            long totalStaff = staffRepository.countStaffList(searchPattern, statusFilter);
            long onShiftCount = staffRepository.countOnShiftStaffList(searchPattern, statusFilter);

            int limit = size;
            int offset = page * size;
            if (size == Integer.MAX_VALUE) {
                offset = 0;
            }

            List<Object[]> rows = staffRepository.getStaffList(searchPattern, statusFilter, limit, offset);

            List<StaffListDTO> staffList = new ArrayList<>();

            for (Object[] row : rows) {
                String userId     = row[0] != null ? row[0].toString() : null;
                String fullName   = (String) row[1];
                String phone      = row[2] != null ? (String) row[2] : "";
                String avatarUrl  = row[3] != null ? (String) row[3] : null;
                String status     = row[4] != null ? (String) row[4] : "ACTIVE";
                Integer roleNum   = row[5] != null ? ((Number) row[5]).intValue() : null;
                String roleName   = row[6] != null ? (String) row[6] : "Unknown";
                String shiftName  = row[7] != null ? (String) row[7] : null;
                String startTime  = row[8] != null ? (String) row[8] : null;
                String endTime    = row[9] != null ? (String) row[9] : null;
                boolean onLeave   = row[10] != null; // leave_number

                // Determine work status
                String computed;
                if (onLeave) {
                    computed = "ON_LEAVE";
                } else if (shiftName != null) {
                    computed = "ON_DUTY";
                } else {
                    computed = "OFF_DUTY";
                }

                staffList.add(StaffListDTO.builder()
                        .userId(userId)
                        .fullName(fullName)
                        .phone(phone)
                        .avatarUrl(avatarUrl)
                        .status(status)
                        .roleNumber(roleNum)
                        .roleName(roleName)
                        .workStatus(computed)
                        .shiftName(shiftName)
                        .shiftStartTime(startTime)
                        .shiftEndTime(endTime)
                        .build());
            }

            int totalPages = 1;
            if (size > 0 && size != Integer.MAX_VALUE) {
                totalPages = (int) Math.ceil((double) totalStaff / size);
                if (totalPages == 0) {
                    totalPages = 1;
                }
            }

            return StaffSummaryDTO.builder()
                    .totalStaff(totalStaff)
                    .onShiftCount(onShiftCount)
                    .totalPages(totalPages)
                    .staff(staffList)
                    .build();
        } catch (Exception e) {
            throw new StaffListLoadException("Unable to load staff list: " + e.getMessage(), e);
        }
    }

    /**
     * UC-ST-02: Get detailed information of a single staff member.
     */
    public StaffDetailDTO getStaffDetail(String userId) {
        try {
            List<Object[]> pRows = staffRepository.getStaffDetail(userId);
            if (pRows.isEmpty()) {
                throw new RuntimeException("Staff record not found.");
            }

            Object[] pr = pRows.get(0);
            String shiftName  = pr[9] != null ? (String) pr[9] : null;
            boolean onLeave   = pr[12] != null;
            String computed;
            if (onLeave)          computed = "ON_LEAVE";
            else if (shiftName != null) computed = "ON_DUTY";
            else                  computed = "OFF_DUTY";

            List<Object[]> wRows = staffRepository.getWeeklySchedule(userId);
            DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy-MM-dd");

            List<StaffDetailDTO.WeeklyShiftDTO> weekly = new ArrayList<>();
            for (Object[] wr : wRows) {
                Object dateObj = wr[0];
                LocalDate date;
                if (dateObj instanceof java.sql.Date) {
                    date = ((java.sql.Date) dateObj).toLocalDate();
                } else if (dateObj instanceof java.time.LocalDate) {
                    date = (java.time.LocalDate) dateObj;
                } else {
                    date = LocalDate.parse(dateObj.toString());
                }
                weekly.add(StaffDetailDTO.WeeklyShiftDTO.builder()
                        .workDate(date.format(dtf))
                        .dayOfWeek(date.getDayOfWeek().getDisplayName(TextStyle.FULL, Locale.ENGLISH))
                        .shiftNumber(wr[1] != null ? ((Number) wr[1]).intValue() : null)
                        .shiftName(wr[2] != null ? (String) wr[2] : null)
                        .shiftStartTime(wr[3] != null ? (String) wr[3] : null)
                        .shiftEndTime(wr[4] != null ? (String) wr[4] : null)
                        .build());
            }

            return StaffDetailDTO.builder()
                    .userId(pr[0] != null ? pr[0].toString() : null)
                    .fullName((String) pr[1])
                    .phone(pr[2] != null ? (String) pr[2] : "")
                    .avatarUrl(pr[3] != null ? (String) pr[3] : null)
                    .address(pr[4] != null ? (String) pr[4] : null)
                    .status(pr[5] != null ? (String) pr[5] : "ACTIVE")
                    .createdAt(pr[6] != null ? (String) pr[6] : null)
                    .roleNumber(pr[7] != null ? ((Number) pr[7]).intValue() : null)
                    .roleName(pr[8] != null ? (String) pr[8] : "Unknown")
                    .workStatus(computed)
                    .shiftName(shiftName)
                    .shiftStartTime(pr[10] != null ? (String) pr[10] : null)
                    .shiftEndTime(pr[11] != null ? (String) pr[11] : null)
                    .weeklySchedule(weekly)
                    .build();
        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            throw new StaffDetailLoadException("Unable to load staff detail: " + e.getMessage(), e);
        }
    }

    /**
     * UC-ST-03: Update a staff member's role.
     * Only Managers can set staff roles (BR-ST-05).
     */
    @Transactional
    public void setStaffRole(String userId, Integer roleNumber) {
        try {
            if (!RoleNumber.isValid(roleNumber)) {
                throw new IllegalArgumentException("Invalid role number.");
            }
            if (!staffRepository.existsRole(roleNumber)) {
                throw new RuntimeException("Role not found.");
            }

            int updated = staffRepository.updateStaffRole(userId, roleNumber);
            if (updated == 0) {
                throw new RuntimeException("Staff record not found.");
            }
        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            throw new StaffRoleUpdateException("Unable to update staff role.", e);
        }
    }

    /**
     * UC-ST-04: Assign weekly shifts for a staff member.
     * Each staff member can have only one working shift or day off per day (BR-ST-09).
     */
    @Transactional
    public void assignShifts(String userId, AssignShiftsRequestDTO request) {
        try {
            if (request.getSchedule() == null || request.getSchedule().isEmpty()) {
                throw new RuntimeException("No schedule provided.");
            }

            for (AssignShiftsRequestDTO.DayShiftDTO day : request.getSchedule()) {
                if (day.getWorkDate() == null) continue;

                staffRepository.deleteWorkSchedule(userId, day.getWorkDate());

                if (day.getShiftNumber() != null) {
                    staffRepository.insertWorkSchedule(userId, day.getShiftNumber(), day.getWorkDate());
                }
            }
        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            throw new StaffShiftAssignmentException("Unable to save shift assignment.", e);
        }
    }

    /**
     * Get all available roles.
     */
    public List<Object[]> getRoles() {
        try {
            return staffRepository.getRoles();
        } catch (Exception e) {
            throw new StaffMetaLoadException("Unable to load roles.", e);
        }
    }

    /**
     * Get all available shifts.
     */
    public List<Object[]> getShifts() {
        try {
            return staffRepository.getShifts();
        } catch (Exception e) {
            throw new StaffMetaLoadException("Unable to load shifts.", e);
        }
    }
}
