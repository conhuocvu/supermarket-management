package com.supermarket.backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

@Service
public class SupabaseStorageService {

    @Value("${supabase.url}")
    private String supabaseUrl;

    @Value("${supabase.service-role-key}")
    private String serviceRoleKey;

    @Value("${supabase.storage.bucket:product-images}")
    private String bucketName;

    private final RestTemplate restTemplate = new RestTemplate();

    public String uploadFile(MultipartFile file) throws IOException {
        String originalFilename = file.getOriginalFilename();
        String extension = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            extension = originalFilename.substring(originalFilename.lastIndexOf("."));
        }
        String uniqueFilename = UUID.randomUUID().toString() + extension;

        // URL format: https://<project_id>.supabase.co/storage/v1/object/<bucket_name>/<unique_filename>
        String uploadUrl = supabaseUrl.trim() + "/storage/v1/object/" + bucketName.trim() + "/" + uniqueFilename;

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + serviceRoleKey.trim());
        headers.set("apikey", serviceRoleKey.trim());
        headers.setContentType(MediaType.parseMediaType(file.getContentType() != null ? file.getContentType() : "application/octet-stream"));

        byte[] fileBytes = file.getBytes();
        HttpEntity<byte[]> requestEntity = new HttpEntity<>(fileBytes, headers);

        // Supabase REST endpoint returns a JSON response on success like {"Key": "bucket/filename"}
        ResponseEntity<String> response = restTemplate.postForEntity(uploadUrl, requestEntity, String.class);

        if (response.getStatusCode().is2xxSuccessful()) {
            // Public URL: https://<project_id>.supabase.co/storage/v1/object/public/<bucket_name>/<unique_filename>
            return supabaseUrl.trim() + "/storage/v1/object/public/" + bucketName.trim() + "/" + uniqueFilename;
        } else {
            throw new RuntimeException("Failed to upload file to Supabase. HTTP status: " + response.getStatusCode());
        }
    }
}
