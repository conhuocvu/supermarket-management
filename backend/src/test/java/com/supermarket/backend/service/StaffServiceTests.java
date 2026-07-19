package com.supermarket.backend.service;

import com.supermarket.backend.dto.RoleNumber;
import com.supermarket.backend.repository.StaffRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class StaffServiceTests {

    @Mock
    private StaffRepository staffRepository;

    @InjectMocks
    private StaffService staffService;

    @Test
    void testSetStaffRole_InvalidRole_ThrowsIllegalArgumentException() {
        // Assert that passing 999 (invalid) throws IllegalArgumentException without hits to the repository
        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> 
            staffService.setStaffRole("e3b3ec4a-da0b-40f5-9747-29361993892b", 999)
        );

        assertEquals("Invalid role number.", exception.getMessage());
        verify(staffRepository, never()).existsRole(anyInt());
    }

    @Test
    void testSetStaffRole_ValidRole_Success() {
        String userId = "e3b3ec4a-da0b-40f5-9747-29361993892b";
        int validRole = RoleNumber.MANAGER.getValue(); // 2

        when(staffRepository.existsRole(validRole)).thenReturn(true);
        when(staffRepository.updateStaffRole(userId, validRole)).thenReturn(1);

        assertDoesNotThrow(() -> staffService.setStaffRole(userId, validRole));

        verify(staffRepository, times(1)).existsRole(validRole);
        verify(staffRepository, times(1)).updateStaffRole(userId, validRole);
    }
}
