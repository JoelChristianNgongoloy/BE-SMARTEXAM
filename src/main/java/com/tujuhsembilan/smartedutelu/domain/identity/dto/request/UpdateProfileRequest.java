package com.tujuhsembilan.smartedutelu.domain.identity.dto.request;

import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateProfileRequest {

    @Size(max = 255, message = "Nama maksimal 255 karakter")
    private String name;

    @Size(max = 50, message = "Nomor telepon maksimal 50 karakter")
    private String phone;

    private String picture;

    @Size(max = 10, message = "Locale maksimal 10 karakter")
    private String locale;

    @Size(max = 100, message = "Timezone maksimal 100 karakter")
    private String timezone;
}
