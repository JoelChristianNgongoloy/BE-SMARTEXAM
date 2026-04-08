package com.tujuhsembilan.smartedutelu.common.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public abstract class BaseDTO {

    // Kolom-kolom ini bersifat opsional untuk dikirim ke frontend,
    // namun berguna sebagai standar jika data log/audit perlu ditampilkan di UI.

    private String createdBy;
    private LocalDateTime createdDate;
    private String lastModifiedBy;
    private LocalDateTime lastModifiedDate;

}