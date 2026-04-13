package com.tujuhsembilan.smartedutelu.common.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * Base entity yang menyediakan field audit standar (created/updated).
 * Gunakan {@code extends BaseEntity} di entity baru agar otomatis punya audit trail.
 *
 * <p>Catatan: Entity yang sudah ada (User, dll) belum menggunakan BaseEntity ini
 * karena skema DB dibuat terpisah. Entity baru disarankan meng-extend class ini.</p>
 */
@Data
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class BaseEntity implements Serializable {

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @org.springframework.data.annotation.CreatedBy
    @Column(name = "created_by", length = 50, updatable = false)
    private String createdBy;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @org.springframework.data.annotation.LastModifiedBy
    @Column(name = "updated_by", length = 50)
    private String updatedBy;
}