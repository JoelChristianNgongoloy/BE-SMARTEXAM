package com.tujuhsembilan.smartedutelu.common.security;

import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    // TODO: Injeksi UserRepository di sini saat entitas User sudah dibuat

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        // Logika untuk mengambil data dari database aplikasi
        // Contoh implementasi kasar:
        // User user = userRepository.findByUsername(username)
        //     .orElseThrow(() -> new UsernameNotFoundException("Pengguna tidak ditemukan"));
        // return new org.springframework.security.core.userdetails.User(
        //     user.getUsername(), user.getPassword(), user.getAuthorities());

        throw new UnsupportedOperationException("Harap integrasikan dengan UserRepository smartedu-be");
    }
}