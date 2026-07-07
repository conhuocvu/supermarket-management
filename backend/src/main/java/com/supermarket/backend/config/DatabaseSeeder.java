package com.supermarket.backend.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.sql.Connection;

@Component
@RequiredArgsConstructor
@Slf4j
public class DatabaseSeeder implements CommandLineRunner {

    private final JdbcTemplate jdbcTemplate;

    @Override
    public void run(String... args) throws Exception {
        // Check if products table has rows
        Integer productCount = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM products", Integer.class);
        if (productCount != null && productCount > 0) {
            log.info("Database already seeded with products. Skipping database seeding.");
            return;
        }

        log.info("Database is empty. Seeding demo data for supermarket dashboard...");

        try (Connection connection = jdbcTemplate.getDataSource().getConnection()) {
            // Insert products
            jdbcTemplate.execute("INSERT INTO products (product_name, barcode, selling_price, reorder_level, status, description) VALUES " +
                    "('Fresh Whole Milk', '8930000000001', 35000, 20, 'ACTIVE', 'Fresh whole milk, pasteurized')");
            jdbcTemplate.execute("INSERT INTO products (product_name, barcode, selling_price, reorder_level, status, description) VALUES " +
                    "('Sliced Wheat Bread', '8930000000002', 25000, 15, 'ACTIVE', 'Sliced whole wheat sandwich bread')");
            jdbcTemplate.execute("INSERT INTO products (product_name, barcode, selling_price, reorder_level, status, description) VALUES " +
                    "('Honey Crunch Cereal', '8930000000003', 65000, 10, 'ACTIVE', 'Honey roasted oats and flakes cereal')");
            jdbcTemplate.execute("INSERT INTO products (product_name, barcode, selling_price, reorder_level, status, description) VALUES " +
                    "('Organic Apple Juice', '8930000000004', 45000, 30, 'ACTIVE', '100% natural organic apple juice')");
            jdbcTemplate.execute("INSERT INTO products (product_name, barcode, selling_price, reorder_level, status, description) VALUES " +
                    "('Green Tea Pack', '8930000000005', 55000, 25, 'ACTIVE', 'Organic premium green tea bags')");

            // Seed inventories
            jdbcTemplate.execute("INSERT INTO inventories (product_number, total_quantity, available_quantity, last_updated) VALUES (1, 50, 50, NOW())");
            jdbcTemplate.execute("INSERT INTO inventories (product_number, total_quantity, available_quantity, last_updated) VALUES (2, 12, 12, NOW())"); // Low stock (reorder level 15)
            jdbcTemplate.execute("INSERT INTO inventories (product_number, total_quantity, available_quantity, last_updated) VALUES (3, 100, 100, NOW())");
            jdbcTemplate.execute("INSERT INTO inventories (product_number, total_quantity, available_quantity, last_updated) VALUES (4, 8, 8, NOW())"); // Low stock (reorder level 30)
            jdbcTemplate.execute("INSERT INTO inventories (product_number, total_quantity, available_quantity, last_updated) VALUES (5, 60, 60, NOW())");

            // Seed stock_in_details (expires in 10 days, 180 days, and expired 5 days ago)
            jdbcTemplate.execute("INSERT INTO stock_in_details (product_number, batch_number, quantity, remaining_quantity, import_price, expiry_date, manufacturing_date) VALUES " +
                    "(1, 'BATCH-001', 100, 50, 25000, CURRENT_DATE + 10, CURRENT_DATE - 20)");
            jdbcTemplate.execute("INSERT INTO stock_in_details (product_number, batch_number, quantity, remaining_quantity, import_price, expiry_date, manufacturing_date) VALUES " +
                    "(3, 'BATCH-002', 200, 100, 45000, CURRENT_DATE + 180, CURRENT_DATE - 10)");
            jdbcTemplate.execute("INSERT INTO stock_in_details (product_number, batch_number, quantity, remaining_quantity, import_price, expiry_date, manufacturing_date) VALUES " +
                    "(2, 'BATCH-003', 50, 12, 18000, CURRENT_DATE - 5, CURRENT_DATE - 35)");

            // Check if PostgreSQL vs H2
            String dbProductName = connection.getMetaData().getDatabaseProductName();
            log.info("Database product name detected: {}", dbProductName);
            boolean isPostgres = dbProductName != null && dbProductName.toLowerCase().contains("postgres");

            if (isPostgres) {
                // Seed purchase requests using request_status enum cast
                jdbcTemplate.execute("INSERT INTO purchase_requests (status, created_date) VALUES (CAST('PENDING' AS request_status), NOW() - INTERVAL '1 DAY')");
                jdbcTemplate.execute("INSERT INTO purchase_requests (status, created_date) VALUES (CAST('PENDING' AS request_status), NOW() - INTERVAL '2 HOUR')");
                jdbcTemplate.execute("INSERT INTO purchase_requests (status, created_date) VALUES (CAST('PENDING' AS request_status), NOW())");
                jdbcTemplate.execute("INSERT INTO purchase_requests (status, created_date, approved_date) VALUES (CAST('APPROVED' AS request_status), NOW() - INTERVAL '5 DAY', NOW() - INTERVAL '4 DAY')");

                // Seed inventory transactions using transaction_type enum cast
                jdbcTemplate.execute("INSERT INTO inventory_transactions (product_number, type, quantity, created_at) VALUES (1, CAST('IN' AS transaction_type), 50, NOW() - INTERVAL '10 MINUTE')");
                jdbcTemplate.execute("INSERT INTO inventory_transactions (product_number, type, quantity, created_at) VALUES (2, CAST('OUT' AS transaction_type), 10, NOW() - INTERVAL '2 HOUR')");
                jdbcTemplate.execute("INSERT INTO inventory_transactions (product_number, type, quantity, created_at) VALUES (3, CAST('IN' AS transaction_type), 100, NOW() - INTERVAL '1 DAY')");
                jdbcTemplate.execute("INSERT INTO inventory_transactions (product_number, type, quantity, created_at) VALUES (4, CAST('OUT' AS transaction_type), 24, NOW() - INTERVAL '1 DAY')");
            } else {
                // H2 database seed logic
                jdbcTemplate.execute("INSERT INTO purchase_requests (status, created_date) VALUES ('PENDING', NOW())");
                jdbcTemplate.execute("INSERT INTO purchase_requests (status, created_date) VALUES ('PENDING', NOW())");
                jdbcTemplate.execute("INSERT INTO purchase_requests (status, created_date) VALUES ('PENDING', NOW())");

                jdbcTemplate.execute("INSERT INTO inventory_transactions (product_number, type, quantity, created_at) VALUES (1, 'IN', 50, NOW())");
                jdbcTemplate.execute("INSERT INTO inventory_transactions (product_number, type, quantity, created_at) VALUES (2, 'OUT', 10, NOW())");
                jdbcTemplate.execute("INSERT INTO inventory_transactions (product_number, type, quantity, created_at) VALUES (3, 'IN', 100, NOW())");
                jdbcTemplate.execute("INSERT INTO inventory_transactions (product_number, type, quantity, created_at) VALUES (4, 'OUT', 24, NOW())");
            }

            log.info("Database seeding completed successfully!");
        } catch (Exception e) {
            log.error("Failed to seed database: ", e);
        }
    }
}
