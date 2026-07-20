package com.supermarket.backend.service;

import com.supermarket.backend.dto.ShiftChangeRequestDTO;
import com.supermarket.backend.entity.ShiftChangeRequest;
import com.supermarket.backend.repository.ProfileRepository;
import com.supermarket.backend.repository.ShiftChangeRequestRepository;
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
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class ShiftChangeRequestServiceTests {

    @Mock
    private ShiftChangeRequestRepository shiftChangeRequestRepository;

    @Mock
    private ProfileRepository profileRepository;

    @Mock
    private NotificationService notificationService;

    @Spy
    private Clock clock = Clock.fixed(Instant.parse("2026-07-20T10:00:00Z"), ZoneId.of("UTC"));

    @InjectMocks
    private ShiftChangeRequestService shiftChangeRequestService;

    private UUID userId;
    private ShiftChangeRequest request;
    private ShiftChangeRequestDTO requestDTO;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();

        request = ShiftChangeRequest.builder()
                .requestNumber(1)
                .userId(userId)
                .reason("Doctor appointment")
                .status("PENDING")
                .createdDate(LocalDateTime.now(clock))
                .currentShiftDate(LocalDate.now().plusDays(1))
                .currentShiftType("MORNING")
                .currentShiftStart(LocalTime.of(8, 0))
                .currentShiftEnd(LocalTime.of(12, 0))
                .targetShiftDate(LocalDate.now().plusDays(1))
                .targetShiftType("AFTERNOON")
                .targetShiftStart(LocalTime.of(13, 0))
                .targetShiftEnd(LocalTime.of(17, 0))
                .build();

        requestDTO = ShiftChangeRequestDTO.builder()
                .userId(userId.toString())
                .reason("Doctor appointment")
                .currentShiftDate(LocalDate.now().plusDays(1))
                .currentShiftType("MORNING")
                .currentShiftStart(LocalTime.of(8, 0))
                .currentShiftEnd(LocalTime.of(12, 0))
                .targetShiftDate(LocalDate.now().plusDays(1))
                .targetShiftType("AFTERNOON")
                .targetShiftStart(LocalTime.of(13, 0))
                .targetShiftEnd(LocalTime.of(17, 0))
                .build();
    }

    @Test
    void testGetUserRequests_ActiveAccount_Success() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(shiftChangeRequestRepository.findByUserIdOrderByCreatedDateDesc(userId))
                .thenReturn(Collections.singletonList(request));

        List<ShiftChangeRequestDTO> result = shiftChangeRequestService.getUserRequests(userId);

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("Doctor appointment", result.get(0).getReason());
    }

    @Test
    void testGetUserRequests_InactiveAccount_ThrowsSecurityException() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("INACTIVE");

        assertThrows(SecurityException.class, () -> shiftChangeRequestService.getUserRequests(userId));
        verify(shiftChangeRequestRepository, never()).findByUserIdOrderByCreatedDateDesc(any(UUID.class));
    }

    @Test
    void testCreateRequest_Success() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(shiftChangeRequestRepository.save(any(ShiftChangeRequest.class))).thenAnswer(invocation -> invocation.getArgument(0));

        ShiftChangeRequestDTO result = shiftChangeRequestService.createRequest(requestDTO);

        assertNotNull(result);
        assertEquals("PENDING", result.getStatus());
        verify(notificationService, times(1)).createNotification(
                eq(userId), anyString(), contains("pending approval"));
    }

    @Test
    void testCancelRequest_Success() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(shiftChangeRequestRepository.findById(1)).thenReturn(Optional.of(request));

        ShiftChangeRequestDTO result = shiftChangeRequestService.cancelRequest(1, userId);

        assertNotNull(result);
        assertEquals("CANCELLED", result.getStatus());
        verify(shiftChangeRequestRepository, times(1)).save(request);
    }

    @Test
    void testCancelRequest_NotOwner_ThrowsSecurityException() {
        UUID anotherUser = UUID.randomUUID();
        when(profileRepository.checkAccountStatus(anotherUser)).thenReturn("ACTIVE");
        when(shiftChangeRequestRepository.findById(1)).thenReturn(Optional.of(request));

        assertThrows(SecurityException.class, () -> shiftChangeRequestService.cancelRequest(1, anotherUser));
        verify(shiftChangeRequestRepository, never()).save(any(ShiftChangeRequest.class));
    }

    @Test
    void testCancelRequest_NotPending_ThrowsIllegalStateException() {
        request.setStatus("APPROVED");
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(shiftChangeRequestRepository.findById(1)).thenReturn(Optional.of(request));

        assertThrows(IllegalStateException.class, () -> shiftChangeRequestService.cancelRequest(1, userId));
        verify(shiftChangeRequestRepository, never()).save(any(ShiftChangeRequest.class));
    }
}
