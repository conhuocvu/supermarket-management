package com.supermarket.backend.service;

import com.supermarket.backend.dto.ShiftChangeRequestDTO;
import com.supermarket.backend.entity.ShiftChangeRequest;
import com.supermarket.backend.repository.ProfileRepository;
import com.supermarket.backend.repository.ShiftChangeRequestRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ShiftChangeRequestService {

    /** Matches the Postgres request_status enum. */
    public static final String STATUS_PENDING   = "PENDING";
    public static final String STATUS_CANCELLED = "CANCELLED";

    private final ShiftChangeRequestRepository shiftChangeRequestRepository;
    private final ProfileRepository profileRepository;
    private final NotificationService notificationService;
    private final Clock clock;

    /** A user's shift change requests, newest first. */
    public List<ShiftChangeRequestDTO> getUserRequests(UUID userId) {
        verifyActiveAccount(userId);
        return shiftChangeRequestRepository.findByUserIdOrderByCreatedDateDesc(userId)
                .stream()
                .map(this::mapToDTO)
                .toList();
    }

    @Transactional
    public ShiftChangeRequestDTO createRequest(ShiftChangeRequestDTO dto) {
        UUID userId = UUID.fromString(dto.getUserId());
        verifyActiveAccount(userId);

        ShiftChangeRequest record = ShiftChangeRequest.builder()
                .userId(userId)
                .reason(dto.getReason())
                .status(STATUS_PENDING)
                .createdDate(LocalDateTime.now(clock))
                // Current shift fields
                .currentShiftDate(dto.getCurrentShiftDate())
                .currentShiftType(dto.getCurrentShiftType())
                .currentShiftStart(dto.getCurrentShiftStart())
                .currentShiftEnd(dto.getCurrentShiftEnd())
                // Target shift fields
                .targetShiftDate(dto.getTargetShiftDate())
                .targetShiftType(dto.getTargetShiftType())
                .targetShiftStart(dto.getTargetShiftStart())
                .targetShiftEnd(dto.getTargetShiftEnd())
                .build();

        shiftChangeRequestRepository.save(record);

        notificationService.createNotification(
                userId,
                "Shift change request submitted",
                "Your request to change shift on " + dto.getCurrentShiftDate()
                        + " is pending approval.");

        return mapToDTO(record);
    }

    /**
     * Cancels a pending shift change request by setting status to CANCELLED.
     * Only the owner may cancel, and only while it is still PENDING.
     */
    @Transactional
    public ShiftChangeRequestDTO cancelRequest(Integer requestNumber, UUID userId) {
        verifyActiveAccount(userId);

        ShiftChangeRequest record = shiftChangeRequestRepository.findById(requestNumber)
                .orElseThrow(() -> new IllegalArgumentException("Shift change request not found."));

        if (!userId.equals(record.getUserId())) {
            throw new SecurityException("You are not authorised to cancel this request.");
        }
        if (!STATUS_PENDING.equalsIgnoreCase(record.getStatus())) {
            throw new IllegalStateException(
                    "Only pending requests can be cancelled. This request is " + record.getStatus() + ".");
        }

        record.setStatus(STATUS_CANCELLED);
        shiftChangeRequestRepository.save(record);
        return mapToDTO(record);
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

    private ShiftChangeRequestDTO mapToDTO(ShiftChangeRequest r) {
        return ShiftChangeRequestDTO.builder()
                .requestNumber(r.getRequestNumber())
                .userId(r.getUserId().toString())
                .reason(r.getReason())
                .status(r.getStatus())
                .createdDate(r.getCreatedDate())
                .approvedDate(r.getApprovedDate())
                // Current shift fields
                .currentShiftDate(r.getCurrentShiftDate())
                .currentShiftType(r.getCurrentShiftType())
                .currentShiftStart(r.getCurrentShiftStart())
                .currentShiftEnd(r.getCurrentShiftEnd())
                // Target shift fields
                .targetShiftDate(r.getTargetShiftDate())
                .targetShiftType(r.getTargetShiftType())
                .targetShiftStart(r.getTargetShiftStart())
                .targetShiftEnd(r.getTargetShiftEnd())
                .build();
    }
}
