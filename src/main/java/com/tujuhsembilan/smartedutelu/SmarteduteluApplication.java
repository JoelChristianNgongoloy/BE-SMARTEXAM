package com.tujuhsembilan.smartedutelu;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class SmarteduteluApplication {

	public static void main(String[] args) {
		SpringApplication.run(SmarteduteluApplication.class, args);
	}

}
