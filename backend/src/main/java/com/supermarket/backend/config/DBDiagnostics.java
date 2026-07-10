package com.supermarket.backend.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Component
public class DBDiagnostics implements CommandLineRunner {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public void run(String... args) throws Exception {
        System.out.println("=== DB SYNCHRONIZATION AND DIAGNOSTICS START ===");
        
        // 1. Sync profiles to employees
        try {
            Integer employeeCount = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM employees", Integer.class);
            if (employeeCount == 0) {
                System.out.println("No employees found. Syncing from profiles...");
                List<Map<String, Object>> profiles = jdbcTemplate.queryForList("SELECT * FROM profiles");
                for (Map<String, Object> profile : profiles) {
                    String userId = profile.get("user_id").toString();
                    String fullName = (String) profile.get("full_name");
                    String phone = (String) profile.get("phone");
                    Integer roleNum = ((Number) profile.get("role_number")).intValue();
                    
                    String role = "SALES_ASSOCIATE";
                    if (roleNum == 1) role = "ADMIN";
                    else if (roleNum == 2) role = "MANAGER";
                    else if (roleNum == 3) role = "STOCK_CONTROLLER";
                    else if (roleNum == 4) role = "SALES_ASSOCIATE";
                    else if (roleNum == 5) role = "CASHIER";

                    // Try to get email from auth.users, fall back to generated email if fails
                    String email = null;
                    try {
                        email = jdbcTemplate.queryForObject(
                            "SELECT email FROM auth.users WHERE id = ?::uuid", 
                            String.class, 
                            userId
                        );
                    } catch (Exception e) {
                        System.out.println("Could not read auth.users: " + e.getMessage());
                    }

                    if (email == null || email.trim().isEmpty()) {
                        String cleanName = fullName != null ? fullName.toLowerCase().replaceAll("\\s+", ".") : "user";
                        email = cleanName + "@supermarket.com";
                    }

                    jdbcTemplate.update(
                        "INSERT INTO employees (name, email, phone, location, joined_date, role, status, attendance_rate, completed_shifts, performance_score) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                        fullName != null ? fullName : "Unknown Staff",
                        email,
                        phone != null ? phone : "000-000-0000",
                        "Main Store",
                        LocalDate.now().minusMonths(6),
                        role,
                        "ON_DUTY",
                        98.5,
                        150,
                        4.7
                    );
                    System.out.println("Synced employee: " + fullName + " (" + role + ")");
                }
            } else {
                System.out.println("Employees table already has " + employeeCount + " rows.");
            }
        } catch (Exception e) {
            System.err.println("Error syncing profiles to employees: " + e.getMessage());
        }

        // 2. Sync suppliers to suppliers_v2
        try {
            Integer suppliersV2Count = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM suppliers_v2", Integer.class);
            if (suppliersV2Count == 0) {
                System.out.println("No suppliers_v2 found. Syncing from suppliers...");
                List<Map<String, Object>> suppliers = jdbcTemplate.queryForList("SELECT * FROM suppliers");
                for (Map<String, Object> s : suppliers) {
                    Integer supplierNum = ((Number) s.get("supplier_number")).intValue();
                    String supplierName = (String) s.get("supplier_name");
                    String phone = (String) s.get("phone");
                    String email = (String) s.get("email");
                    String status = (String) s.get("status");

                    String mappedStatus = "Reliable";
                    if ("INACTIVE".equalsIgnoreCase(status)) {
                        mappedStatus = "Suspended";
                    }

                    String code = String.format("SUP-%03d", supplierNum);

                    jdbcTemplate.update(
                        "INSERT INTO suppliers_v2 (id, code, name, category, next_delivery, status, contact_type, contact_value, on_time_delivery_rate, average_rating, notes, certification) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                        (long) supplierNum,
                        code,
                        supplierName != null ? supplierName : "Supplier " + supplierNum,
                        "Dry Goods",
                        LocalDate.now().plusDays(3),
                        mappedStatus,
                        "Email",
                        email != null ? email : "info@supplier.com",
                        96.0,
                        4.6,
                        "Migrated from suppliers table",
                        "ISO 9001"
                    );
                    System.out.println("Synced supplier: " + supplierName + " -> suppliers_v2");
                }
            } else {
                System.out.println("suppliers_v2 already has " + suppliersV2Count + " rows.");
            }
        } catch (Exception e) {
            System.err.println("Error syncing suppliers to suppliers_v2: " + e.getMessage());
        }

        // 3. Sync products to products_v2
        try {
            Integer productsV2Count = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM products_v2", Integer.class);
            if (productsV2Count == 0) {
                System.out.println("No products_v2 found. Syncing from products...");
                List<Map<String, Object>> products = jdbcTemplate.queryForList(
                    "SELECT p.*, c.category_name, u.unit_name " +
                    "FROM products p " +
                    "LEFT JOIN categories c ON p.category_number = c.category_number " +
                    "LEFT JOIN units u ON p.inventory_unit_number = u.unit_number"
                );
                for (Map<String, Object> p : products) {
                    Integer productNum = ((Number) p.get("product_number")).intValue();
                    String productName = (String) p.get("product_name");
                    String barcode = (String) p.get("barcode");
                    Double sellingPrice = ((Number) p.get("selling_price")).doubleValue();
                    String categoryName = (String) p.get("category_name");
                    String unitName = (String) p.get("unit_name");
                    String imageUrl = (String) p.get("image_url");

                    String sku = barcode != null && !barcode.trim().isEmpty() ? barcode : String.format("SKU-%05d", productNum);
                    String category = categoryName != null ? categoryName : "Produce";
                    String unit = unitName != null ? unitName : "unit";
                    Double basePrice = sellingPrice * 0.75; // assume import cost is 75% of sale price

                    jdbcTemplate.update(
                        "INSERT INTO products_v2 (id, sku, name, category, base_price, unit, image_url) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?)",
                        (long) productNum,
                        sku,
                        productName != null ? productName : "Product " + productNum,
                        category,
                        basePrice,
                        unit,
                        imageUrl
                    );
                    System.out.println("Synced product: " + productName + " -> products_v2");
                }
            } else {
                System.out.println("products_v2 already has " + productsV2Count + " rows.");
            }
        } catch (Exception e) {
            System.err.println("Error syncing products to products_v2: " + e.getMessage());
        }

        // 4. Sync product_suppliers to supplier_products
        try {
            Integer supplierProductsCount = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM supplier_products", Integer.class);
            if (supplierProductsCount == 0) {
                System.out.println("No supplier_products found. Syncing from product_suppliers...");
                List<Map<String, Object>> mappings = jdbcTemplate.queryForList("SELECT * FROM product_suppliers");
                for (Map<String, Object> m : mappings) {
                    Integer id = ((Number) m.get("product_supplier_number")).intValue();
                    Integer prodNum = ((Number) m.get("product_number")).intValue();
                    Integer suppNum = ((Number) m.get("supplier_number")).intValue();
                    Double importPrice = ((Number) m.get("import_price")).doubleValue();

                    jdbcTemplate.update(
                        "INSERT INTO supplier_products (id, product_id, supplier_id, import_price) " +
                        "VALUES (?, ?, ?, ?)",
                        (long) id,
                        (long) prodNum,
                        (long) suppNum,
                        importPrice
                    );
                }
                System.out.println("Synced " + mappings.size() + " product-supplier mappings.");
            } else {
                System.out.println("supplier_products already has " + supplierProductsCount + " rows.");
            }
        } catch (Exception e) {
            System.err.println("Error syncing product_suppliers to supplier_products: " + e.getMessage());
        }

        System.out.println("=== DB SYNCHRONIZATION AND DIAGNOSTICS END ===");
    }
}
