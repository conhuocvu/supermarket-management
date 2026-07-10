package com.supermarket.backend.service;

import com.supermarket.backend.dto.ProductDto;
import com.supermarket.backend.model.Product;
import com.supermarket.backend.repository.SupplierFeatureProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class ProductService {

    private final SupplierFeatureProductRepository productRepository;

    @Autowired
    public ProductService(SupplierFeatureProductRepository productRepository) {
        this.productRepository = productRepository;
    }

    @Transactional(readOnly = true)
    public List<ProductDto> getAllProducts(String search, String category) {
        List<Product> products = productRepository.searchProducts(search, category);
        return products.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public ProductDto convertToDto(Product product) {
        return ProductDto.builder()
                .id(product.getId())
                .sku(product.getSku())
                .name(product.getName())
                .category(product.getCategory())
                .basePrice(product.getBasePrice())
                .unit(product.getUnit())
                .imageUrl(product.getImageUrl())
                .build();
    }
}
