package com.supermarket.backend;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class BackendApplicationTests {
	static {
		BackendApplication.loadDotEnv();
	}

	@org.springframework.beans.factory.annotation.Autowired
	private com.supermarket.backend.service.InventoryProductService inventoryProductService;

	@Test
	void contextLoads() {
	}

	@Test
	void testWarning() {
		System.out.println("=== STARTING WARNING API DIAGNOSTIC TEST ===");
		try {
			var results = inventoryProductService.getProductsByWarning("ALL");
			System.out.println("Successfully computed warnings: " + results.size());
		} catch (Exception e) {
			System.err.println("CRITICAL ERROR IN WARNING METHOD:");
			e.printStackTrace();
		}
		System.out.println("=== END OF WARNING API DIAGNOSTIC TEST ===");
	}
}
