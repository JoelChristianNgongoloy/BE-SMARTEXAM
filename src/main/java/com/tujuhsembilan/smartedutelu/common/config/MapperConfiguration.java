package com.tujuhsembilan.smartedutelu.common.config;

import org.modelmapper.ModelMapper;
import org.modelmapper.convention.MatchingStrategies;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class MapperConfiguration {

    @Bean
    public ModelMapper modelMapper() {
        ModelMapper modelMapper = new ModelMapper();

        // Konfigurasi ketat agar tidak ada salah pemetaan nama field
        modelMapper.getConfiguration()
                .setMatchingStrategy(MatchingStrategies.STRICT)
                .setSkipNullEnabled(true); // Abaikan nilai null agar tidak menimpa data yang sudah ada saat update

        return modelMapper;
    }
}