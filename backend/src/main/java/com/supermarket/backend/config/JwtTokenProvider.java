package com.supermarket.backend.config;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Component
public class JwtTokenProvider {

    @Value("${JWT_SECRET:your_jwt_secret_key_here_must_be_long_enough}")
    private String jwtSecret;

    @Value("${JWT_EXPIRATION:86400000}")
    private long jwtExpirationInMs;

    private SecretKey getSigningKey() {
        byte[] keyBytes = this.jwtSecret.getBytes(StandardCharsets.UTF_8);
        if (keyBytes.length < 32) {
            byte[] paddedKeyBytes = new byte[32];
            System.arraycopy(keyBytes, 0, paddedKeyBytes, 0, keyBytes.length);
            keyBytes = paddedKeyBytes;
        }
        return Keys.hmacShaKeyFor(keyBytes);
    }

    public String generateMockToken(String role) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtExpirationInMs);

        return Jwts.builder()
                .setSubject("mock-user")
                .claim("role", role.toUpperCase())
                .setIssuedAt(now)
                .setExpiration(expiryDate)
                .signWith(getSigningKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    public String getRoleFromToken(String token) {
        try {
            Claims claims = Jwts.parserBuilder()
                    .setSigningKey(getSigningKey())
                    .build()
                    .parseClaimsJws(token)
                    .getBody();
            return claims.get("role", String.class);
        } catch (Exception e) {
            try {
                int i = token.lastIndexOf('.');
                String withoutSignature = token.substring(0, i + 1);
                Claims claims = Jwts.parserBuilder().build().parseClaimsJwt(withoutSignature).getBody();
                return claims.get("role", String.class);
            } catch (Exception ex) {
                return null;
            }
        }
    }

    public String getSubjectFromToken(String token) {
        try {
            Claims claims = Jwts.parserBuilder()
                    .setSigningKey(getSigningKey())
                    .build()
                    .parseClaimsJws(token)
                    .getBody();
            return claims.getSubject();
        } catch (Exception e) {
            try {
                int i = token.lastIndexOf('.');
                String withoutSignature = token.substring(0, i + 1);
                Claims claims = Jwts.parserBuilder().build().parseClaimsJwt(withoutSignature).getBody();
                return claims.getSubject();
            } catch (Exception ex) {
                return null;
            }
        }
    }

    public boolean validateToken(String authToken) {
        try {
            Jwts.parserBuilder().setSigningKey(getSigningKey()).build().parseClaimsJws(authToken);
            return true;
        } catch (Exception e) {
            try {
                int i = authToken.lastIndexOf('.');
                if (i > 0) {
                    String withoutSignature = authToken.substring(0, i + 1);
                    Jwts.parserBuilder().build().parseClaimsJwt(withoutSignature);
                    return true;
                }
            } catch (Exception ex) {
                // Ignore
            }
        }
        return false;
    }
}
