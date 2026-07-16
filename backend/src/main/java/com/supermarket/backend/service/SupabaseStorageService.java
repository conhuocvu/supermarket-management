package com.supermarket.backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
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

    @Value("${supabase.storage.avatar-bucket:avatars}")
    private String avatarBucketName;

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

    /**
     * Uploads (upserts) a user's avatar to the avatars bucket at "<userId>/avatar.<ext>".
     * Uses HTTP PUT with x-upsert=true so the file is created on first upload
     * and overwritten on subsequent uploads without a 409 conflict error.
     * Returns the public URL of the uploaded avatar.
     */
    public String uploadAvatar(UUID userId, MultipartFile file) throws IOException {
        String extension = resolveExtension(file);
        String objectPath = userId + "/avatar." + extension;

        String uploadUrl = supabaseUrl.trim() + "/storage/v1/object/" + avatarBucketName.trim() + "/" + objectPath;

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + serviceRoleKey.trim());
        headers.set("apikey", serviceRoleKey.trim());
        // x-upsert=true: create if not exists, overwrite if exists
        headers.set("x-upsert", "true");
        headers.setContentType(MediaType.parseMediaType(
                file.getContentType() != null ? file.getContentType() : "application/octet-stream"));

        HttpEntity<byte[]> requestEntity = new HttpEntity<>(file.getBytes(), headers);

        ResponseEntity<String> response;
        try {
            // PUT method is preferred for upsert — avoids 409 conflicts on repeated uploads
            response = restTemplate.exchange(uploadUrl, HttpMethod.PUT, requestEntity, String.class);
        } catch (HttpClientErrorException e) {
            if (e.getStatusCode() == HttpStatus.NOT_FOUND) {
                // Bucket does not exist yet — create it, then retry
                createAvatarBucket();
                response = restTemplate.exchange(uploadUrl, HttpMethod.PUT, requestEntity, String.class);
            } else {
                throw new RuntimeException(
                        "Supabase Storage error [" + e.getStatusCode() + "]: " + e.getResponseBodyAsString(), e);
            }
        }

        if (response.getStatusCode().is2xxSuccessful()) {
            return supabaseUrl.trim() + "/storage/v1/object/public/" + avatarBucketName.trim() + "/" + objectPath;
        } else {
            throw new RuntimeException("Failed to upload avatar to Supabase. HTTP status: " + response.getStatusCode());
        }
    }

    /**
     * Creates the public avatars bucket via the Storage API (service role bypasses RLS),
     * so no manual SQL setup is required. Limits mirror the frontend validation.
     */
    private void createAvatarBucket() {
        String bucketUrl = supabaseUrl.trim() + "/storage/v1/bucket";

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + serviceRoleKey.trim());
        headers.set("apikey", serviceRoleKey.trim());
        headers.setContentType(MediaType.APPLICATION_JSON);

        String body = "{"
                + "\"id\":\"" + avatarBucketName.trim() + "\","
                + "\"name\":\"" + avatarBucketName.trim() + "\","
                + "\"public\":true,"
                + "\"file_size_limit\":2097152,"
                + "\"allowed_mime_types\":[\"image/jpeg\",\"image/png\",\"image/webp\"]"
                + "}";

        try {
            restTemplate.postForEntity(bucketUrl, new HttpEntity<>(body, headers), String.class);
        } catch (HttpClientErrorException e) {
            // 409 means another request created it concurrently — safe to continue
            if (e.getStatusCode() != HttpStatus.CONFLICT) {
                throw new RuntimeException("Failed to create avatars bucket: " + e.getMessage(), e);
            }
        }
    }

    private String resolveExtension(MultipartFile file) {
        String originalFilename = file.getOriginalFilename();
        if (originalFilename != null && originalFilename.contains(".")) {
            return originalFilename.substring(originalFilename.lastIndexOf('.') + 1).toLowerCase();
        }
        return "png";
    }
}
