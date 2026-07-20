package com.supermarket.backend.service;

import com.supermarket.backend.dto.AttendanceDTO;
import com.supermarket.backend.entity.Attendance;
import com.supermarket.backend.repository.AttendanceRepository;
import com.supermarket.backend.repository.ProfileRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.*;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class AttendanceServiceTests {

    @Mock
    private AttendanceRepository attendanceRepository;

    @Mock
    private ProfileRepository profileRepository;

    @Spy
    private Clock clock = Clock.fixed(Instant.parse("2026-07-20T10:00:00Z"), ZoneId.of("UTC"));

    @InjectMocks
    private AttendanceService attendanceService;

    private UUID userId;
    private Attendance openRecord;
    private Attendance closedRecord;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();

        openRecord = Attendance.builder()
                .attendanceNumber(1)
                .userId(userId)
                .workDate(LocalDate.now(clock))
                .checkInTime(LocalDateTime.now(clock).minusHours(4))
                .build();

        closedRecord = Attendance.builder()
                .attendanceNumber(1)
                .userId(userId)
                .workDate(LocalDate.now(clock))
                .checkInTime(LocalDateTime.now(clock).minusHours(4))
                .checkOutTime(LocalDateTime.now(clock))
                .build();
    }

    @Test
    void testCheckIn_Success() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(attendanceRepository.findOpenRecord(userId)).thenReturn(Optional.empty());
        when(attendanceRepository.save(any(Attendance.class))).thenAnswer(invocation -> invocation.getArgument(0));

        AttendanceDTO result = attendanceService.checkIn(userId);

        assertNotNull(result);
        assertEquals("CHECKED_IN", result.getStatus());
        assertNull(result.getCheckOutTime());
        assertEquals(LocalDate.now(clock), result.getWorkDate());
        verify(attendanceRepository, times(1)).save(any(Attendance.class));
    }

    @Test
    void testCheckIn_AlreadyCheckedIn_ThrowsIllegalStateException() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(attendanceRepository.findOpenRecord(userId)).thenReturn(Optional.of(openRecord));

        assertThrows(IllegalStateException.class, () -> attendanceService.checkIn(userId));
        verify(attendanceRepository, never()).save(any(Attendance.class));
    }

    @Test
    void testCheckIn_InactiveAccount_ThrowsSecurityException() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("INACTIVE");

        assertThrows(SecurityException.class, () -> attendanceService.checkIn(userId));
    }

    @Test
    void testCheckOut_Success() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(attendanceRepository.findOpenRecord(userId)).thenReturn(Optional.of(openRecord));
        when(attendanceRepository.save(any(Attendance.class))).thenAnswer(invocation -> invocation.getArgument(0));

        AttendanceDTO result = attendanceService.checkOut(userId);

        assertNotNull(result);
        assertEquals("CHECKED_OUT", result.getStatus());
        assertNotNull(result.getCheckOutTime());
        assertEquals(240L, result.getDurationMinutes()); // 4 hours checkin
        verify(attendanceRepository, times(1)).save(openRecord);
    }

    @Test
    void testCheckOut_NotCheckedIn_ThrowsIllegalStateException() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(attendanceRepository.findOpenRecord(userId)).thenReturn(Optional.empty());

        assertThrows(IllegalStateException.class, () -> attendanceService.checkOut(userId));
        verify(attendanceRepository, never()).save(any(Attendance.class));
    }

    @Test
    void testGetTodayAttendance_CheckedIn() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(attendanceRepository.findOpenRecord(userId)).thenReturn(Optional.of(openRecord));

        AttendanceDTO result = attendanceService.getTodayAttendance(userId);

        assertNotNull(result);
        assertEquals("CHECKED_IN", result.getStatus());
    }

    @Test
    void testGetTodayAttendance_CheckedOut() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(attendanceRepository.findOpenRecord(userId)).thenReturn(Optional.empty());
        when(attendanceRepository.findFirstByUserIdAndWorkDateOrderByCheckInTimeDesc(userId, LocalDate.now(clock)))
                .thenReturn(Optional.of(closedRecord));

        AttendanceDTO result = attendanceService.getTodayAttendance(userId);

        assertNotNull(result);
        assertEquals("CHECKED_OUT", result.getStatus());
    }

    @Test
    void testGetTodayAttendance_None() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(attendanceRepository.findOpenRecord(userId)).thenReturn(Optional.empty());
        when(attendanceRepository.findFirstByUserIdAndWorkDateOrderByCheckInTimeDesc(userId, LocalDate.now(clock)))
                .thenReturn(Optional.empty());

        AttendanceDTO result = attendanceService.getTodayAttendance(userId);

        assertNull(result);
    }

    @Test
    void testGetMonthlyAttendance_Success() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        
        LocalDate start = LocalDate.of(2026, 7, 1);
        LocalDate end = LocalDate.of(2026, 7, 31);
        when(attendanceRepository.findByUserIdAndWorkDateBetweenOrderByWorkDateAsc(userId, start, end))
                .thenReturn(Arrays.asList(closedRecord));

        List<AttendanceDTO> result = attendanceService.getMonthlyAttendance(userId, 2026, 7);

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("CHECKED_OUT", result.get(0).getStatus());
    }
}
