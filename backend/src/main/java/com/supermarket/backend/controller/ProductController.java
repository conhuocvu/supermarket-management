package com.supermarket.backend.controller;

import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.dto.ProductDto;
import com.supermarket.backend.service.ProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/products")
public class ProductController {

    private final ProductService productService;

    @Autowired
    public ProductController(ProductService productService) {
        this.productService = productService;
    }

    @GetMapping
    public ApiResponse<List<ProductDto>> getProducts(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String category) {
        List<ProductDto> list = productService.getAllProducts(search, category);
        return ApiResponse.success("Fetched products successfully.", list);
    }
}
