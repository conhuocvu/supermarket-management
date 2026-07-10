package com.supermarket.backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "categories")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Category {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "category_number")
    private Integer categoryNumber;

    @Column(name = "parent_category_number")
    private Integer parentCategoryNumber;

    @Column(name = "category_name")
    private String categoryName;

    @Column(name = "status")
    private String status;

    @Column(name = "description")
    private String description;
}
