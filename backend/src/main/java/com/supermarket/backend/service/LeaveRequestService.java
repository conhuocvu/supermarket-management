package com.supermarket.backend.service;

import com.supermarket.backend.dto.LeaveRequestDTO;
import com.supermarket.backend.entity.LeaveRequest;
import com.supermarket.backend.repository.LeaveRequestRepository;
import com.supermarket.backend.repository.ProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class LeaveRequestService {

    /** Matches the Postgres request_status enum (uppercase). */
    public static final String STATUS_PENDING = "PENDING";
    public static final String STATUS_CANCELLED = "CANCELLED";

    private final LeaveRequestRepository leaveRequestRepository;
    private final ProfileRepository profileRepository;
    private final Clock clock;

    /** A user's leave requests, newest first. */
    public List<LeaveRequestDTO> getUserLeaveRequests(UUID userId) {
        verifyActiveAccount(userId);
        return leaveRequestRepository.findByUserIdOrderByCreatedDateDesc(userId)
                .stream()
                .map(this::mapToDTO)
                .toList();
    }

    @Transactional
    public LeaveRequestDTO createLeaveRequest(LeaveRequestDTO dto) {
        UUID userId = UUID.fromString(dto.getUserId());
        verifyActiveAccount(userId);

        if (dto.getEndDate().isBefore(dto.getStartDate())) {
            throw new IllegalArgumentException("End date cannot be before start date.");
        }
        if (dto.getStartDate().isBefore(LocalDate.now(clock))) {
            throw new IllegalArgumentException("Leave requests cannot start in the past.");
        }
        if (leaveRequestRepository.existsOverlappingRequest(
                userId, dto.getStartDate(), dto.getEndDate())) {
            throw new IllegalStateException(
                    "You already have a pending or approved leave request overlapping these dates.");
        }

        LeaveRequest record = LeaveRequest.builder()
                .userId(userId)
                .reason(dto.getReason())
                .startDate(dto.getStartDate())
                .endDate(dto.getEndDate())
                .status(STATUS_PENDING)
                .createdDate(LocalDateTime.now(clock))
                .build();

        leaveRequestRepository.save(record);
        return mapToDTO(record);
    }

    /**
     * Cancels a pending leave request by setting status to CANCELLED. Only the
     * owner may cancel, and only while it is still PENDING (approved/rejected
     * requests are locked).
     */
    @Transactional
    public LeaveRequestDTO cancelLeaveRequest(Integer leaveNumber, UUID userId) {
        verifyActiveAccount(userId);

        LeaveRequest record = leaveRequestRepository.findById(leaveNumber)
                .orElseThrow(() -> new IllegalArgumentException("Leave request not found."));

        if (!userId.equals(record.getUserId())) {
            throw new SecurityException("You are not authorised to cancel this leave request.");
        }
        if (!STATUS_PENDING.equalsIgnoreCase(record.getStatus())) {
            throw new IllegalStateException(
                    "Only pending leave requests can be cancelled. This request is " + record.getStatus() + ".");
        }

        record.setStatus(STATUS_CANCELLED);
        leaveRequestRepository.save(record);
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

    private LeaveRequestDTO mapToDTO(LeaveRequest r) {
        return LeaveRequestDTO.builder()
                .leaveNumber(r.getLeaveNumber())
                .userId(r.getUserId().toString())
                .reason(r.getReason())
                .startDate(r.getStartDate())
                .endDate(r.getEndDate())
                .status(r.getStatus())
                .createdDate(r.getCreatedDate())
                .approvedDate(r.getApprovedDate())
                .build();
    }
}
