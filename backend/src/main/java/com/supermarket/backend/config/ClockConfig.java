package com.supermarket.backend.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Clock;
import java.time.ZoneId;

/**
 * Provides a single application-wide {@link Clock} so services resolve
 * "today"/"now" in the business timezone rather than the server's default
 * timezone. Override with the app.timezone property when deploying.
 */
@Configuration
public class ClockConfig {

    @Value("${app.timezone:Asia/Ho_Chi_Minh}")
    private String timezone;

    @Bean
    public Clock clock() {
        return Clock.system(ZoneId.of(timezone));
    }
}
