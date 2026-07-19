package com.supermarket.backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Maps the existing Supabase table public.work_schedules — a shift assignment
 * for an employee on a specific date. The shift itself (name, hours) lives in
 * public.shifts and is referenced by shift_number.
 * Status is a Postgres enum (schedule_status: ASSIGNED / COMPLETED /
 * CANCELLED / MISSED), read via a ::text cast in the repository query.
 */
@Entity
@Table(name = "work_schedules")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkSchedule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "schedule_number")
    private Integer scheduleNumber;

    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "shift_number")
    private Integer shiftNumber;

    @Column(name = "work_date")
    private LocalDate workDate;

    @Column(name = "status", insertable = false, updatable = false)
    private String status;

    @Column(name = "assigned_date")
    private LocalDateTime assignedDate;
}
