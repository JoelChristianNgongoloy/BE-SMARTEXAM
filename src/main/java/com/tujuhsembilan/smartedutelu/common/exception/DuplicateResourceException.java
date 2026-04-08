package com.tujuhsembilan.smartedutelu.common.exception;

import com.tujuhsembilan.smartedutelu.common.enums.ErrorCode;

/**
 * Exception thrown when attempting to create a resource that already exists.
 */
public class DuplicateResourceException extends BusinessException {

    public DuplicateResourceException(ErrorCode errorCode) {
        super(errorCode);
    }

    public DuplicateResourceException(ErrorCode errorCode, String detail) {
        super(errorCode, detail);
    }

    public DuplicateResourceException(String resourceName, String field, Object value) {
        super(ErrorCode.SE_CMN_003,
                String.format("%s with %s '%s' already exists", resourceName, field, value));
    }
}