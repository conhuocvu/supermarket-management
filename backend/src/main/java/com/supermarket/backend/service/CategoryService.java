package com.supermarket.backend.service;

import com.supermarket.backend.dto.CategoryDTO;
import com.supermarket.backend.entity.Category;
import com.supermarket.backend.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryRepository categoryRepository;

    public Page<CategoryDTO> getCategories(String keyword, Pageable pageable) {
        Page<Category> categories;
        if (keyword != null && !keyword.trim().isEmpty()) {
            categories = categoryRepository.findByCategoryNameContainingIgnoreCase(keyword.trim(), pageable);
        } else {
            categories = categoryRepository.findAll(pageable);
        }
        
        return categories.map(this::mapToDTO);
    }

    public CategoryDTO getCategoryById(Integer categoryNumber) {
        Category category = categoryRepository.findById(categoryNumber)
                .orElseThrow(() -> new RuntimeException("Category not found"));
        return mapToDTO(category);
    }

    @Transactional
    public CategoryDTO createCategory(CategoryDTO categoryDTO) {
        Category category = Category.builder()
                .categoryName(categoryDTO.getCategoryName())
                .parentCategoryNumber(categoryDTO.getParentCategoryNumber())
                .status(categoryDTO.getStatus() != null ? categoryDTO.getStatus() : "ACTIVE")
                .description(categoryDTO.getDescription())
                .internalNotes(categoryDTO.getInternalNotes())
                .build();
        
        category = categoryRepository.save(category);
        return mapToDTO(category);
    }

    @Transactional
    public CategoryDTO updateCategory(Integer categoryNumber, CategoryDTO categoryDTO) {
        Category category = categoryRepository.findById(categoryNumber)
                .orElseThrow(() -> new RuntimeException("Category not found"));
        
        category.setCategoryName(categoryDTO.getCategoryName());
        category.setParentCategoryNumber(categoryDTO.getParentCategoryNumber());
        category.setDescription(categoryDTO.getDescription());
        category.setInternalNotes(categoryDTO.getInternalNotes());
        
        if (categoryDTO.getStatus() != null && !categoryDTO.getStatus().equals(category.getStatus())) {
            updateStatusRecursive(category, categoryDTO.getStatus());
        }
        
        category = categoryRepository.save(category);
        return mapToDTO(category);
    }

    @Transactional
    public CategoryDTO updateCategoryStatus(Integer categoryNumber, String newStatus) {
        Category category = categoryRepository.findById(categoryNumber)
                .orElseThrow(() -> new RuntimeException("Category not found"));
        
        updateStatusRecursive(category, newStatus);
        
        return mapToDTO(category);
    }
    
    private void updateStatusRecursive(Category category, String newStatus) {
        category.setStatus(newStatus);
        categoryRepository.save(category);
        
        List<Category> children = categoryRepository.findByParentCategoryNumber(category.getCategoryNumber());
        for (Category child : children) {
            updateStatusRecursive(child, newStatus);
        }
    }

    private CategoryDTO mapToDTO(Category category) {
        String parentName = null;
        if (category.getParentCategoryNumber() != null) {
            parentName = categoryRepository.findById(category.getParentCategoryNumber())
                    .map(Category::getCategoryName)
                    .orElse(null);
        }
        
        return CategoryDTO.builder()
                .categoryNumber(category.getCategoryNumber())
                .parentCategoryNumber(category.getParentCategoryNumber())
                .parentCategoryName(parentName)
                .categoryName(category.getCategoryName())
                .status(category.getStatus())
                .description(category.getDescription())
                .internalNotes(category.getInternalNotes())
                .build();
    }
}
