package com.supermarket.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.ColumnTransformer;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Maps the existing Supabase table public.leave_requests.
 * The status column is a Postgres enum (request_status), so writes are cast
 * explicitly via ColumnTransformer.
 */
@Entity
@Table(name = "leave_requests")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LeaveRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "leave_number")
    private Integer leaveNumber;

    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "reason")
    private String reason;

    @Column(name = "start_date")
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    @Column(name = "status", columnDefinition = "request_status")
    @ColumnTransformer(write = "?::request_status")
    private String status;

    @Column(name = "created_date")
    private LocalDateTime createdDate;

    @Column(name = "approved_date")
    private LocalDateTime approvedDate;
}
