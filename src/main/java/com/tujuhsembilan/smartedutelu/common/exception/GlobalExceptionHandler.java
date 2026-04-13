package com.tujuhsembilan.smartedutelu.common.exception;

import com.tujuhsembilan.smartedutelu.common.dto.ApiResponse;
import com.tujuhsembilan.smartedutelu.common.enums.ErrorCode;
import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;

import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiResponse<Void>> handleResourceNotFoundException(
            ResourceNotFoundException ex, WebRequest request) {
        log.error("Resource not found: {}", ex.getMessage());

        ApiResponse<Void> response = ApiResponse.error(
                ex.getErrorCode().getCode(),
                ex.getErrorCode().getMessage(),
                ex.getDetail()
        );

        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
    }

    @ExceptionHandler(DuplicateResourceException.class)
    public ResponseEntity<ApiResponse<Void>> handleDuplicateResourceException(
            DuplicateResourceException ex, WebRequest request) {
        log.error("Duplicate resource: {}", ex.getMessage());

        ApiResponse<Void> response = ApiResponse.error(
                ex.getErrorCode().getCode(),
                ex.getErrorCode().getMessage(),
                ex.getDetail()
        );

        return ResponseEntity.status(HttpStatus.CONFLICT).body(response);
    }

    @ExceptionHandler(CircularReferenceException.class)
    public ResponseEntity<ApiResponse<Void>> handleCircularReferenceException(
            CircularReferenceException ex, WebRequest request) {
        log.error("Circular reference detected: {}", ex.getMessage());

        ApiResponse<Void> response = ApiResponse.error(
                ex.getErrorCode().getCode(),
                ex.getErrorCode().getMessage(),
                ex.getDetail()
        );

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResponse<Void>> handleBusinessException(
            BusinessException ex, WebRequest request) {
        log.error("Business exception: {}", ex.getMessage());

        ApiResponse<Void> response = ApiResponse.error(
                ex.getErrorCode().getCode(),
                ex.getErrorCode().getMessage(),
                ex.getDetail()
        );

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Map<String, String>>> handleValidationException(
            MethodArgumentNotValidException ex, WebRequest request) {
        log.error("Validation error: {}", ex.getMessage());

        Map<String, String> errors = ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .collect(Collectors.toMap(
                        FieldError::getField,
                        error -> error.getDefaultMessage() != null ? error.getDefaultMessage() : "Invalid value",
                        (existing, replacement) -> existing
                ));

        ApiResponse<Map<String, String>> response = ApiResponse.<Map<String, String>>builder()
                .success(false)
                .message("Validation failed")
                .data(errors)
                .error(ApiResponse.ErrorDetails.builder()
                        .code(ErrorCode.SE_CMN_006.getCode()) // Sesuaikan dengan kode Enum aplikasi Anda
                        .message(ErrorCode.SE_CMN_006.getMessage())
                        .detail(String.format("Found %d validation error(s)", errors.size()))
                        .build())
                .timestamp(java.time.LocalDateTime.now())
                .build();

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiResponse<Map<String, String>>> handleConstraintViolationException(
            ConstraintViolationException ex, WebRequest request) {
        log.error("Constraint violation: {}", ex.getMessage());

        Map<String, String> errors = new HashMap<>();
        ex.getConstraintViolations().forEach(violation -> {
            String propertyPath = violation.getPropertyPath().toString();
            String message = violation.getMessage();
            errors.put(propertyPath, message);
        });

        ApiResponse<Map<String, String>> response = ApiResponse.<Map<String, String>>builder()
                .success(false)
                .message("Constraint violation")
                .data(errors)
                .error(ApiResponse.ErrorDetails.builder()
                        .code(ErrorCode.SE_CMN_006.getCode())
                        .message(ErrorCode.SE_CMN_006.getMessage())
                        .detail(String.format("Found %d constraint violation(s)", errors.size()))
                        .build())
                .timestamp(java.time.LocalDateTime.now())
                .build();

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Void>> handleAccessDeniedException(
            AccessDeniedException ex, WebRequest request) {
        log.error("Access denied: {}", ex.getMessage());

        ApiResponse<Void> response = ApiResponse.error(
                ErrorCode.SE_CMN_004.getCode(),
                ErrorCode.SE_CMN_004.getMessage(),
                "Anda tidak memiliki wewenang untuk mengakses sumber daya ini"
        );

        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(response);
    }

    @ExceptionHandler(org.springframework.web.multipart.MaxUploadSizeExceededException.class)
    public ResponseEntity<ApiResponse<Void>> handleMaxUploadSizeExceededException(
            org.springframework.web.multipart.MaxUploadSizeExceededException ex, WebRequest request) {
        log.error("Max upload size exceeded: {}", ex.getMessage());

        ApiResponse<Void> response = ApiResponse.error(
                ErrorCode.SE_CMN_001.getCode(),
                "Maximum upload size exceeded",
                ex.getMessage()
        );

        return ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE).body(response);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleGlobalException(
            Exception ex, WebRequest request) {
        log.error("Unexpected error occurred", ex);

        ApiResponse<Void> response = ApiResponse.error(
                ErrorCode.SE_CMN_005.getCode(),
                ErrorCode.SE_CMN_005.getMessage(),
                "Terjadi kesalahan internal pada server"
        );

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }
}