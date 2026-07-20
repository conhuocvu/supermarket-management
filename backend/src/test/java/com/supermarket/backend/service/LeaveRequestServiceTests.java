package com.supermarket.backend.service;

import com.supermarket.backend.dto.LeaveRequestDTO;
import com.supermarket.backend.entity.LeaveRequest;
import com.supermarket.backend.repository.LeaveRequestRepository;
import com.supermarket.backend.repository.ProfileRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class LeaveRequestServiceTests {

    @Mock
    private LeaveRequestRepository leaveRequestRepository;

    @Mock
    private ProfileRepository profileRepository;

    @Mock
    private NotificationService notificationService;

    @Spy
    private Clock clock = Clock.fixed(Instant.parse("2026-07-20T10:00:00Z"), ZoneId.of("UTC"));

    @InjectMocks
    private LeaveRequestService leaveRequestService;

    private UUID userId;
    private LeaveRequest leaveRequest;
    private LeaveRequestDTO leaveRequestDTO;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();

        leaveRequest = LeaveRequest.builder()
                .leaveNumber(1)
                .userId(userId)
                .reason("Sick leave")
                .status("PENDING")
                .startDate(LocalDate.now(clock).plusDays(1))
                .endDate(LocalDate.now(clock).plusDays(3))
                .createdDate(LocalDateTime.now(clock))
                .build();

        leaveRequestDTO = LeaveRequestDTO.builder()
                .userId(userId.toString())
                .reason("Sick leave")
                .startDate(LocalDate.now(clock).plusDays(1))
                .endDate(LocalDate.now(clock).plusDays(3))
                .build();
    }

    @Test
    void testGetUserLeaveRequests_ActiveAccount_Success() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(leaveRequestRepository.findByUserIdOrderByCreatedDateDesc(userId))
                .thenReturn(Collections.singletonList(leaveRequest));

        List<LeaveRequestDTO> result = leaveRequestService.getUserLeaveRequests(userId);

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("Sick leave", result.get(0).getReason());
    }

    @Test
    void testGetUserLeaveRequests_InactiveAccount_ThrowsSecurityException() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("INACTIVE");

        assertThrows(SecurityException.class, () -> leaveRequestService.getUserLeaveRequests(userId));
    }

    @Test
    void testCreateLeaveRequest_Success() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(leaveRequestRepository.existsOverlappingRequest(eq(userId), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(false);
        when(leaveRequestRepository.save(any(LeaveRequest.class))).thenAnswer(invocation -> invocation.getArgument(0));

        LeaveRequestDTO result = leaveRequestService.createLeaveRequest(leaveRequestDTO);

        assertNotNull(result);
        assertEquals("PENDING", result.getStatus());
        verify(notificationService, times(1)).createNotification(
                eq(userId), anyString(), contains("pending approval"));
    }

    @Test
    void testCreateLeaveRequest_EndDateBeforeStartDate_ThrowsIllegalArgumentException() {
        leaveRequestDTO.setEndDate(leaveRequestDTO.getStartDate().minusDays(1)); // Invalid date range
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");

        assertThrows(IllegalArgumentException.class, () -> leaveRequestService.createLeaveRequest(leaveRequestDTO));
    }

    @Test
    void testCreateLeaveRequest_StartDateInPast_ThrowsIllegalArgumentException() {
        leaveRequestDTO.setStartDate(LocalDate.now(clock).minusDays(1)); // Past date
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");

        assertThrows(IllegalArgumentException.class, () -> leaveRequestService.createLeaveRequest(leaveRequestDTO));
    }

    @Test
    void testCreateLeaveRequest_OverlappingRequest_ThrowsIllegalStateException() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(leaveRequestRepository.existsOverlappingRequest(eq(userId), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(true); // Overlapping exists

        assertThrows(IllegalStateException.class, () -> leaveRequestService.createLeaveRequest(leaveRequestDTO));
    }

    @Test
    void testCancelLeaveRequest_Success() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(leaveRequestRepository.findById(1)).thenReturn(Optional.of(leaveRequest));

        LeaveRequestDTO result = leaveRequestService.cancelLeaveRequest(1, userId);

        assertNotNull(result);
        assertEquals("CANCELLED", result.getStatus());
        verify(leaveRequestRepository, times(1)).save(leaveRequest);
    }

    @Test
    void testCancelLeaveRequest_NotOwner_ThrowsSecurityException() {
        UUID anotherUser = UUID.randomUUID();
        when(profileRepository.checkAccountStatus(anotherUser)).thenReturn("ACTIVE");
        when(leaveRequestRepository.findById(1)).thenReturn(Optional.of(leaveRequest));

        assertThrows(SecurityException.class, () -> leaveRequestService.cancelLeaveRequest(1, anotherUser));
        verify(leaveRequestRepository, never()).save(any(LeaveRequest.class));
    }

    @Test
    void testCancelLeaveRequest_NotPending_ThrowsIllegalStateException() {
        leaveRequest.setStatus("APPROVED");
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(leaveRequestRepository.findById(1)).thenReturn(Optional.of(leaveRequest));

        assertThrows(IllegalStateException.class, () -> leaveRequestService.cancelLeaveRequest(1, userId));
        verify(leaveRequestRepository, never()).save(any(LeaveRequest.class));
    }
}
