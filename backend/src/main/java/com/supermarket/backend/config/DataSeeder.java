package com.supermarket.backend.config;

import com.supermarket.backend.model.Certification;
import com.supermarket.backend.model.Employee;
import com.supermarket.backend.model.Shift;
import com.supermarket.backend.model.Promotion;
import com.supermarket.backend.repository.CertificationRepository;
import com.supermarket.backend.repository.EmployeeRepository;
import com.supermarket.backend.repository.ShiftRepository;
import com.supermarket.backend.repository.PromotionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Arrays;

@Component
public class DataSeeder implements CommandLineRunner {

    private final EmployeeRepository employeeRepository;
    private final ShiftRepository shiftRepository;
    private final CertificationRepository certificationRepository;
    private final PromotionRepository promotionRepository;

    @Autowired
    public DataSeeder(EmployeeRepository employeeRepository,
                      ShiftRepository shiftRepository,
                      CertificationRepository certificationRepository,
                      PromotionRepository promotionRepository) {
        this.employeeRepository = employeeRepository;
        this.shiftRepository = shiftRepository;
        this.certificationRepository = certificationRepository;
        this.promotionRepository = promotionRepository;
    }

    @Override
    public void run(String... args) throws Exception {
        seedEmployees();
        seedPromotions();
    }

    private void seedEmployees() {
        if (employeeRepository.count() > 0) {
            return; // Already seeded
        }

        // 1. Sarah Jenkins
        Employee sarah = Employee.builder()
                .name("Sarah Jenkins")
                .email("sarah.jenkins@supermarket.com")
                .phone("+1 (555) 234-8901")
                .location("Downtown Branch - Zone A")
                .joinedDate(LocalDate.of(2021, 3, 12))
                .role("CASHIER")
                .status("ON_DUTY")
                .attendanceRate(98.0)
                .completedShifts(124)
                .performanceScore(4.8)
                .managersNote("Sarah has consistently shown leadership in training new recruits. Exceptional handling of high-traffic holiday surges.")
                .imageUrl("https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150")
                .build();
        sarah = employeeRepository.save(sarah);

        certificationRepository.save(Certification.builder()
                .employee(sarah)
                .name("Food Safety Level 2")
                .obtainedDate(LocalDate.of(2022, 12, 1))
                .expiryDate(LocalDate.of(2024, 12, 1))
                .build());

        certificationRepository.save(Certification.builder()
                .employee(sarah)
                .name("Advanced POS Training")
                .obtainedDate(LocalDate.of(2023, 1, 15))
                .build());

        // Shifts for Sarah
        shiftRepository.save(Shift.builder()
                .employee(sarah)
                .date(LocalDate.of(2023, 10, 24))
                .startTime(LocalTime.of(8, 0))
                .endTime(LocalTime.of(16, 0))
                .shiftType("MORNING")
                .register("Register 04")
                .completed(true)
                .build());

        shiftRepository.save(Shift.builder()
                .employee(sarah)
                .date(LocalDate.of(2023, 10, 22))
                .startTime(LocalTime.of(12, 0))
                .endTime(LocalTime.of(20, 0))
                .shiftType("AFTERNOON")
                .register("Register 02")
                .completed(true)
                .build());

        shiftRepository.save(Shift.builder()
                .employee(sarah)
                .date(LocalDate.of(2023, 10, 21))
                .startTime(LocalTime.of(8, 0))
                .endTime(LocalTime.of(16, 0))
                .shiftType("MORNING")
                .register("Register 04")
                .completed(true)
                .build());

        // 2. Marcus Chen
        Employee marcusChen = Employee.builder()
                .name("Marcus Chen")
                .email("marcus.chen@supermarket.com")
                .phone("+1 (555) 345-6789")
                .location("Downtown Branch - Zone B")
                .joinedDate(LocalDate.of(2022, 6, 15))
                .role("SALES_ASSOCIATE")
                .status("OFF_DUTY")
                .attendanceRate(92.0)
                .completedShifts(85)
                .performanceScore(4.2)
                .imageUrl("https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150")
                .build();
        marcusChen = employeeRepository.save(marcusChen);

        // Future shift for Marcus Chen (tomorrow 09:00)
        shiftRepository.save(Shift.builder()
                .employee(marcusChen)
                .date(LocalDate.now().plusDays(1))
                .startTime(LocalTime.of(9, 0))
                .endTime(LocalTime.of(17, 0))
                .shiftType("MORNING")
                .completed(false)
                .build());

        // 3. Elena Rodriguez
        Employee elena = Employee.builder()
                .name("Elena Rodriguez")
                .email("elena.rodriguez@supermarket.com")
                .phone("+1 (555) 456-7890")
                .location("Downtown Branch - Zone A")
                .joinedDate(LocalDate.of(2021, 9, 1))
                .role("INVENTORY_STAFF")
                .status("ON_DUTY")
                .attendanceRate(96.0)
                .completedShifts(110)
                .performanceScore(4.6)
                .imageUrl("https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150")
                .build();
        elena = employeeRepository.save(elena);

        shiftRepository.save(Shift.builder()
                .employee(elena)
                .date(LocalDate.now())
                .startTime(LocalTime.of(10, 0))
                .endTime(LocalTime.of(18, 0))
                .shiftType("AFTERNOON")
                .completed(false)
                .build());

        // 4. David Okafor
        Employee david = Employee.builder()
                .name("David Okafor")
                .email("david.okafor@supermarket.com")
                .phone("+1 (555) 567-8901")
                .location("Downtown Branch - Zone A")
                .joinedDate(LocalDate.of(2020, 1, 15))
                .role("MANAGER")
                .status("ON_LEAVE")
                .attendanceRate(94.0)
                .completedShifts(240)
                .performanceScore(4.7)
                .returnsDate(LocalDate.of(2026, 10, 12))
                .imageUrl("https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150")
                .build();
        employeeRepository.save(david);

        // 5. Marcus Thompson (Needs to be scheduled)
        Employee marcusThompson = Employee.builder()
                .name("Marcus Thompson")
                .email("marcus.thompson@supermarket.com")
                .phone("+1 (555) 678-9012")
                .location("Downtown Branch - Zone B")
                .joinedDate(LocalDate.of(2023, 2, 10))
                .role("INVENTORY_STAFF") // Senior Clerk in mockup
                .status("OFF_DUTY")
                .attendanceRate(90.0)
                .completedShifts(50)
                .performanceScore(4.0)
                .imageUrl("https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150")
                .build();
        employeeRepository.save(marcusThompson);

        // 6. Marcus Sterling (Role change demo)
        Employee marcusSterling = Employee.builder()
                .name("Marcus Sterling")
                .email("marcus.sterling@supermarket.com")
                .phone("+1 (555) 789-0123")
                .location("Downtown Branch - Zone C")
                .joinedDate(LocalDate.of(2023, 5, 18))
                .role("SALES_ASSOCIATE")
                .status("OFF_DUTY")
                .attendanceRate(88.0)
                .completedShifts(42)
                .performanceScore(3.9)
                .imageUrl("https://images.unsplash.com/photo-1500048993953-d23a436266cf?w=150")
                .build();
        employeeRepository.save(marcusSterling);
    }

    private void seedPromotions() {
        if (promotionRepository.count() > 0) {
            return; // Already seeded
        }

        // 1. Fresh Harvest Weekend
        promotionRepository.save(Promotion.builder()
                .name("Fresh Harvest Weekend")
                .code("HARVEST15")
                .description("15% off all organic produce sections. Applicable for loyalty members and bulk purchases. This seasonal promotion aims to increase weekend foot traffic in the fresh produce aisle while rewarding our most frequent shoppers.")
                .priority("MEDIUM")
                .discountType("PERCENTAGE")
                .discountValue(15.0)
                .targetCategories(Arrays.asList("Seasonal", "Produce"))
                .targetProducts(Arrays.asList("Organic Kale", "Baby Carrots", "Vine Tomatoes", "Avocados"))
                .startDate(LocalDate.now().minusDays(5))
                .endDate(LocalDate.now().plusDays(10))
                .imageUrl("https://images.unsplash.com/photo-1542838132-92c53300491e?w=600")
                .visibility("Storewide & Online")
                .build());

        // 2. Autumn Bakery BOGO
        promotionRepository.save(Promotion.builder()
                .name("Autumn Bakery BOGO")
                .code("BAKERYBOGO")
                .description("Buy one get one free on all artisanal breads and pastries every Tuesday.")
                .priority("HIGH")
                .discountType("PERCENTAGE")
                .discountValue(50.0)
                .targetCategories(Arrays.asList("BOGO", "Bakery"))
                .targetProducts(Arrays.asList("Artisanal Sourdough", "French Croissants", "Chocolate Muffins"))
                .startDate(LocalDate.now().plusDays(2))
                .endDate(LocalDate.now().plusDays(20))
                .imageUrl("https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600")
                .visibility("Storewide")
                .build());

        // 3. Flash Dairy Sale
        promotionRepository.save(Promotion.builder()
                .name("Flash Dairy Sale")
                .code("DAIRY20")
                .description("20% off all dairy products. Limited time offer only for the next 24 hours.")
                .priority("HIGH")
                .discountType("PERCENTAGE")
                .discountValue(20.0)
                .targetCategories(Arrays.asList("Flash Sale", "Dairy"))
                .targetProducts(Arrays.asList("Whole Milk 1L", "Greek Yogurt", "Cheddar Cheese 200g"))
                .startDate(LocalDate.now())
                .endDate(LocalDate.now().plusDays(1))
                .imageUrl("https://images.unsplash.com/photo-1550583724-b2692b85b150?w=600")
                .visibility("Storewide")
                .build());

        // 4. Holiday Spirits Pack
        promotionRepository.save(Promotion.builder()
                .name("Holiday Spirits Pack")
                .code("SPIRITS10")
                .description("Scheduled promotion for holiday wine packs and spirit assortments.")
                .priority("MEDIUM")
                .discountType("PERCENTAGE")
                .discountValue(10.0)
                .targetCategories(Arrays.asList("Seasonal", "Beverages"))
                .targetProducts(Arrays.asList("Holiday Wine Pack", "Premium Spirits"))
                .startDate(LocalDate.now().plusDays(30))
                .endDate(LocalDate.now().plusDays(50))
                .imageUrl("https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=600")
                .visibility("Online")
                .build());

        // 5. Home Care Week
        promotionRepository.save(Promotion.builder()
                .name("Home Care Week")
                .code("HOMECARE")
                .description("Special discounts on cleaning detergents and household supplies.")
                .priority("LOW")
                .discountType("FIXED_AMOUNT")
                .discountValue(5.0)
                .targetCategories(Arrays.asList("Household"))
                .targetProducts(Arrays.asList("Disinfectant Spray", "Laundry Detergent"))
                .startDate(LocalDate.now().plusDays(15))
                .endDate(LocalDate.now().plusDays(22))
                .imageUrl("https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600")
                .visibility("Storewide & Online")
                .build());
    }
}