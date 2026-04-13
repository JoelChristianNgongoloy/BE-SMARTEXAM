package com.tujuhsembilan.smartedutelu.common.dto;

import lombok.Data;
import java.time.LocalDateTime;

/**
 * Base DTO yang menyediakan field audit standar untuk response ke frontend.
 * Extend class ini di DTO baru yang butuh info created/modified.
 */
@Data
public abstract class BaseDTO {

    // Kolom-kolom ini bersifat opsional untuk dikirim ke frontend,
    // namun berguna sebagai standar jika data log/audit perlu ditampilkan di UI.

    private String createdBy;
    private LocalDateTime createdDate;
    private String lastModifiedBy;
    private LocalDateTime lastModifiedDate;

}