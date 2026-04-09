package com.tujuhsembilan.smartedutelu.domain.identity.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${application.mail.from}")
    private String fromAddress;

    @Value("${application.mail.password-reset-url}")
    private String passwordResetUrl;

    @Async
    public void sendPasswordResetEmail(String toEmail, String token) {
        try {
            String resetLink = passwordResetUrl + "?token=" + token;

            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromAddress);
            message.setTo(toEmail);
            message.setSubject("SmartEdu - Reset Password");
            message.setText(
                    "Halo,\n\n" +
                    "Kami menerima permintaan untuk reset password akun SmartEdu Anda.\n\n" +
                    "Klik link berikut untuk reset password:\n" +
                    resetLink + "\n\n" +
                    "Link ini berlaku selama 1 jam.\n\n" +
                    "Jika Anda tidak meminta reset password, abaikan email ini.\n\n" +
                    "Terima kasih,\nTim SmartEdu"
            );

            mailSender.send(message);
            log.info("Password reset email sent to {}", toEmail);
        } catch (Exception e) {
            log.error("Gagal mengirim email reset password ke {}: {}", toEmail, e.getMessage());
        }
    }
}
