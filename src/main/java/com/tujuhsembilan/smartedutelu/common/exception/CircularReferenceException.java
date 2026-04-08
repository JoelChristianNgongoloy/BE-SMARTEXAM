package com.tujuhsembilan.smartedutelu.common.exception;

import com.tujuhsembilan.smartedutelu.common.enums.ErrorCode;

/**
 * Exception thrown when a circular reference is detected in hierarchical data.
 */
public class CircularReferenceException extends BusinessException {

    public CircularReferenceException(ErrorCode errorCode) {
        super(errorCode);
    }

    public CircularReferenceException(ErrorCode errorCode, String detail) {
        super(errorCode, detail);
    }

    public CircularReferenceException(String resourceType, Object id) {
        super(ErrorCode.SE_CMN_007,
                String.format("Circular reference detected in %s with ID '%s'", resourceType, id));
    }
}