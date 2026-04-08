package com.tujuhsembilan.smartedutelu.common.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * Centralized error codes for the application.
 * Format: {DOMAIN}_{ERROR_TYPE}_{SEQUENCE}
 */
@Getter
@RequiredArgsConstructor
public enum ErrorCode {

    // Common Errors (SE-CMN-xxx)
    SE_CMN_001("SE-CMN-001", "Invalid request parameter"),
    SE_CMN_002("SE-CMN-002", "Resource not found"),
    SE_CMN_003("SE-CMN-003", "Duplicate resource"),
    SE_CMN_004("SE-CMN-004", "Unauthorized access"),
    SE_CMN_005("SE-CMN-005", "Internal server error"),
    SE_CMN_006("SE-CMN-006", "Validation error"),
    SE_CMN_007("SE-CMN-007", "Circular reference detected"),

    // Auth & Security Errors (SE-AUT-xxx)
    SE_AUT_001("SE-AUT-001", "Invalid credentials"),
    SE_AUT_002("SE-AUT-002", "Token expired or invalid"),

    // Organization / Tenant Errors (SE-ORG-xxx)
    SE_ORG_001("SE-ORG-001", "Organization not found"),

    // Exam Management Errors (SE-EXM-xxx) - Contoh untuk SmartEdu
    SE_EXM_001("SE-EXM-001", "Exam not found"),
    SE_EXM_002("SE-EXM-002", "Exam is currently active and cannot be modified");

    private final String code;
    private final String message;
}