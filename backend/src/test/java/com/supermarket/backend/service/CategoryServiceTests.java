package com.supermarket.backend.service;

import com.supermarket.backend.dto.CategoryDTO;
import com.supermarket.backend.entity.Category;
import com.supermarket.backend.repository.CategoryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class CategoryServiceTests {

    @Mock
    private CategoryRepository categoryRepository;

    @InjectMocks
    private CategoryService categoryService;

    private Category category;
    private Category parentCategory;
    private CategoryDTO categoryDTO;

    @BeforeEach
    void setUp() {
        parentCategory = Category.builder()
                .categoryNumber(1)
                .categoryName("Beverages")
                .status("ACTIVE")
                .description("All kinds of drinks")
                .build();

        category = Category.builder()
                .categoryNumber(2)
                .categoryName("Soft Drinks")
                .parentCategoryNumber(1)
                .status("ACTIVE")
                .description("Carbonated drinks")
                .internalNotes("High sales volume")
                .build();

        categoryDTO = CategoryDTO.builder()
                .categoryNumber(2)
                .categoryName("Soft Drinks")
                .parentCategoryNumber(1)
                .status("ACTIVE")
                .description("Carbonated drinks")
                .internalNotes("High sales volume")
                .build();
    }

    @Test
    void testGetCategories_WithKeyword_Success() {
        Pageable pageable = PageRequest.of(0, 10);
        Page<Category> categoryPage = new PageImpl<>(Collections.singletonList(category));
        
        when(categoryRepository.findByCategoryNameContainingIgnoreCase(eq("Drinks"), eq(pageable)))
                .thenReturn(categoryPage);
        when(categoryRepository.findById(1)).thenReturn(Optional.of(parentCategory));

        Page<CategoryDTO> result = categoryService.getCategories("Drinks", pageable);

        assertNotNull(result);
        assertEquals(1, result.getContent().size());
        assertEquals("Soft Drinks", result.getContent().get(0).getCategoryName());
        assertEquals("Beverages", result.getContent().get(0).getParentCategoryName());
    }

    @Test
    void testGetCategories_WithoutKeyword_Success() {
        Pageable pageable = PageRequest.of(0, 10);
        Page<Category> categoryPage = new PageImpl<>(Collections.singletonList(category));
        
        when(categoryRepository.findAll(eq(pageable))).thenReturn(categoryPage);
        when(categoryRepository.findById(1)).thenReturn(Optional.of(parentCategory));

        Page<CategoryDTO> result = categoryService.getCategories(null, pageable);

        assertNotNull(result);
        assertEquals(1, result.getContent().size());
        assertEquals("Soft Drinks", result.getContent().get(0).getCategoryName());
    }

    @Test
    void testGetCategoryById_Success() {
        when(categoryRepository.findById(2)).thenReturn(Optional.of(category));
        when(categoryRepository.findById(1)).thenReturn(Optional.of(parentCategory));

        CategoryDTO result = categoryService.getCategoryById(2);

        assertNotNull(result);
        assertEquals("Soft Drinks", result.getCategoryName());
        assertEquals("Beverages", result.getParentCategoryName());
    }

    @Test
    void testGetCategoryById_NotFound_ThrowsException() {
        when(categoryRepository.findById(99)).thenReturn(Optional.empty());

        assertThrows(RuntimeException.class, () -> categoryService.getCategoryById(99));
    }

    @Test
    void testCreateCategory_Success() {
        when(categoryRepository.save(any(Category.class))).thenReturn(category);
        when(categoryRepository.findById(1)).thenReturn(Optional.of(parentCategory));

        CategoryDTO result = categoryService.createCategory(categoryDTO);

        assertNotNull(result);
        assertEquals("Soft Drinks", result.getCategoryName());
        assertEquals("Beverages", result.getParentCategoryName());
        verify(categoryRepository, times(1)).save(any(Category.class));
    }

    @Test
    void testUpdateCategory_Success() {
        when(categoryRepository.findById(2)).thenReturn(Optional.of(category));
        when(categoryRepository.save(any(Category.class))).thenReturn(category);
        when(categoryRepository.findById(1)).thenReturn(Optional.of(parentCategory));

        CategoryDTO updatedDTO = CategoryDTO.builder()
                .categoryName("Updated Soft Drinks")
                .parentCategoryNumber(1)
                .description("New description")
                .status("ACTIVE")
                .build();

        CategoryDTO result = categoryService.updateCategory(2, updatedDTO);

        assertNotNull(result);
        verify(categoryRepository, times(1)).save(any(Category.class));
    }

    @Test
    void testUpdateCategory_OwnParent_ThrowsException() {
        when(categoryRepository.findById(2)).thenReturn(Optional.of(category));

        CategoryDTO updatedDTO = CategoryDTO.builder()
                .categoryName("Soft Drinks")
                .parentCategoryNumber(2) // Parent is itself
                .build();

        assertThrows(IllegalArgumentException.class, () -> categoryService.updateCategory(2, updatedDTO));
        verify(categoryRepository, never()).save(any(Category.class));
    }

    @Test
    void testUpdateCategory_CyclicParent_ThrowsException() {
        when(categoryRepository.findById(2)).thenReturn(Optional.of(category));
        
        // Mock chain: 2 -> parent 1 -> parent 2 (cyclic)
        when(categoryRepository.findById(1)).thenReturn(Optional.of(Category.builder()
                .categoryNumber(1)
                .parentCategoryNumber(2)
                .build()));

        CategoryDTO updatedDTO = CategoryDTO.builder()
                .categoryName("Soft Drinks")
                .parentCategoryNumber(1)
                .build();

        assertThrows(IllegalArgumentException.class, () -> categoryService.updateCategory(2, updatedDTO));
        verify(categoryRepository, never()).save(any(Category.class));
    }

    @Test
    void testUpdateCategoryStatus_InvalidStatus_ThrowsException() {
        assertThrows(IllegalArgumentException.class, () -> categoryService.updateCategoryStatus(2, "SUSPENDED"));
        assertThrows(IllegalArgumentException.class, () -> categoryService.updateCategoryStatus(2, " "));
    }

    @Test
    void testUpdateCategoryStatus_Success() {
        when(categoryRepository.findById(2)).thenReturn(Optional.of(category));
        when(categoryRepository.findAll()).thenReturn(Arrays.asList(parentCategory, category));
        
        CategoryDTO result = categoryService.updateCategoryStatus(2, "INACTIVE");

        assertNotNull(result);
        verify(categoryRepository, times(1)).updateStatusForIds(anyList(), eq("INACTIVE"));
    }
}
