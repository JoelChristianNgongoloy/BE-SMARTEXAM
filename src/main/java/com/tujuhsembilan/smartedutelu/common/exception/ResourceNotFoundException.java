package com.tujuhsembilan.smartedutelu.common.exception;

import com.tujuhsembilan.smartedutelu.common.enums.ErrorCode;

/**
 * Exception thrown when a requested resource is not found.
 */
public class ResourceNotFoundException extends BusinessException {

    public ResourceNotFoundException(ErrorCode errorCode) {
        super(errorCode);
    }

    public ResourceNotFoundException(ErrorCode errorCode, String detail) {
        super(errorCode, detail);
    }

    public ResourceNotFoundException(String resourceName, Object identifier) {
        super(ErrorCode.SE_CMN_002,
                String.format("%s with identifier '%s' not found", resourceName, identifier));
    }
}