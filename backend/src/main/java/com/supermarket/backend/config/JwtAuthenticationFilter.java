package com.supermarket.backend.config;

import com.supermarket.backend.repository.StaffRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;
import java.util.regex.Pattern;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider tokenProvider;
    private final StaffRepository staffRepository;

    private static final Pattern UUID_PATTERN = Pattern.compile(
            "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
    );

    @Autowired
    public JwtAuthenticationFilter(JwtTokenProvider tokenProvider, StaffRepository staffRepository) {
        this.tokenProvider = tokenProvider;
        this.staffRepository = staffRepository;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        try {
            String jwt = getJwtFromRequest(request);

            if (StringUtils.hasText(jwt) && tokenProvider.validateToken(jwt)) {
                String subject = tokenProvider.getSubjectFromToken(jwt);
                String role = null;

                // If subject is a UUID, attempt to query the user's role from profiles
                if (subject != null && UUID_PATTERN.matcher(subject).matches()) {
                    role = staffRepository.getUserRole(subject);
                }

                // If not found in DB or not a UUID, fall back to checking the "role" claim in the token
                if (role == null) {
                    try {
                        role = tokenProvider.getRoleFromToken(jwt);
                    } catch (Exception e) {
                        // "role" claim might be missing in token
                    }
                }

                if (role != null) {
                    String authorityName = "ROLE_" + role.toUpperCase().replace(" ", "_");
                    SimpleGrantedAuthority authority = new SimpleGrantedAuthority(authorityName);

                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                            subject != null ? subject : "mock-user", null, Collections.singletonList(authority));
                    authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            }
        } catch (Exception ex) {
            // Log or ignore authentication errors
        }

        filterChain.doFilter(request, response);
    }

    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}
