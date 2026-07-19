package com.supermarket.backend.service;

import com.supermarket.backend.dto.AttendanceDTO;
import com.supermarket.backend.entity.Attendance;
import com.supermarket.backend.repository.AttendanceRepository;
import com.supermarket.backend.repository.ProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AttendanceService {

    public static final String STATUS_CHECKED_IN = "CHECKED_IN";
    public static final String STATUS_CHECKED_OUT = "CHECKED_OUT";

    private final AttendanceRepository attendanceRepository;
    private final ProfileRepository profileRepository;
    private final Clock clock;

    /**
     * Opens a new attendance record for the user. Fails if the account is not
     * ACTIVE or an open (not checked-out) record already exists.
     */
    @Transactional
    public AttendanceDTO checkIn(UUID userId) {
        verifyActiveAccount(userId);

        attendanceRepository.findOpenRecord(userId).ifPresent(open -> {
            throw new IllegalStateException(
                    "You are already checked in since " + open.getCheckInTime() + ". Please check out first.");
        });

        LocalDateTime now = LocalDateTime.now(clock);
        Attendance record = Attendance.builder()
                .userId(userId)
                .workDate(now.toLocalDate())
                .checkInTime(now)
                .build();

        attendanceRepository.save(record);
        return mapToDTO(record);
    }

    /**
     * Closes the user's open attendance record. Fails if there is no open record.
     */
    @Transactional
    public AttendanceDTO checkOut(UUID userId) {
        verifyActiveAccount(userId);

        Attendance record = attendanceRepository.findOpenRecord(userId)
                .orElseThrow(() -> new IllegalStateException("You are not checked in."));

        record.setCheckOutTime(LocalDateTime.now(clock));
        attendanceRepository.save(record);
        return mapToDTO(record);
    }

    /**
     * The user's current attendance state: the open record if checked in,
     * otherwise the most recent record for today, otherwise null.
     */
    public AttendanceDTO getTodayAttendance(UUID userId) {
        verifyActiveAccount(userId);

        return attendanceRepository.findOpenRecord(userId)
                .or(() -> attendanceRepository
                        .findFirstByUserIdAndWorkDateOrderByCheckInTimeDesc(userId, LocalDate.now(clock)))
                .map(this::mapToDTO)
                .orElse(null);
    }

    /**
     * Attendance history for a month (for the Work Schedule calendar).
     */
    public List<AttendanceDTO> getMonthlyAttendance(UUID userId, int year, int month) {
        verifyActiveAccount(userId);

        LocalDate start = LocalDate.of(year, month, 1);
        LocalDate end = start.withDayOfMonth(start.lengthOfMonth());
        return attendanceRepository
                .findByUserIdAndWorkDateBetweenOrderByWorkDateAsc(userId, start, end)
                .stream()
                .map(this::mapToDTO)
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

    private AttendanceDTO mapToDTO(Attendance record) {
        boolean checkedOut = record.getCheckOutTime() != null;
        Long durationMinutes = null;
        if (checkedOut && record.getCheckInTime() != null) {
            durationMinutes = Duration
                    .between(record.getCheckInTime(), record.getCheckOutTime())
                    .toMinutes();
        }
        return AttendanceDTO.builder()
                .attendanceNumber(record.getAttendanceNumber())
                .userId(record.getUserId().toString())
                .workDate(record.getWorkDate())
                .checkInTime(record.getCheckInTime())
                .checkOutTime(record.getCheckOutTime())
                .status(checkedOut ? STATUS_CHECKED_OUT : STATUS_CHECKED_IN)
                .durationMinutes(durationMinutes)
                .build();
    }
}
