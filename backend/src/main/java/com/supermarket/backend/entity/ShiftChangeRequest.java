package com.supermarket.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.ColumnTransformer;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.UUID;

/**
 * Maps the Supabase table public.shift_change_requests.
 * Structured columns store the current (from) and target (to) shift details
 * separately so they can be queried and displayed without string-parsing.
 * The status column is a Postgres enum (request_status), cast via ColumnTransformer.
 */
@Entity
@Table(name = "shift_change_requests")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ShiftChangeRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "request_number")
    private Integer requestNumber;

    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "reason")
    private String reason;

    @Column(name = "status", columnDefinition = "request_status")
    @ColumnTransformer(write = "?::request_status")
    private String status;

    @Column(name = "created_date")
    private LocalDateTime createdDate;

    @Column(name = "approved_date")
    private LocalDateTime approvedDate;

    // ── Current shift (the one the employee is currently assigned to) ──────────
    @Column(name = "current_shift_date")
    private LocalDate currentShiftDate;

    @Column(name = "current_shift_type")
    private String currentShiftType;

    @Column(name = "current_shift_start")
    private LocalTime currentShiftStart;

    @Column(name = "current_shift_end")
    private LocalTime currentShiftEnd;

    // ── Target shift (the shift the employee wants to swap to) ─────────────────
    @Column(name = "target_shift_date")
    private LocalDate targetShiftDate;

    @Column(name = "target_shift_type")
    private String targetShiftType;

    @Column(name = "target_shift_start")
    private LocalTime targetShiftStart;

    @Column(name = "target_shift_end")
    private LocalTime targetShiftEnd;
}
