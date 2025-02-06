package com.example;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;


@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}

@Component
class Props implements CommandLineRunner {
    @Value("${spring.datasource.username}")
    private String username;

    @Value("${spring.datasource.password}")
    private String password;

    @Override
    public void run(String... args) throws Exception {
        System.out.println("Username: " + username);
        System.out.println("Password: " + password);
    }
}

@RestController
class DataSourceTest {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @RequestMapping("/")
    public String index(String... args) {
        try {
            Integer result = jdbcTemplate.queryForObject("SELECT 1", Integer.class);
            return "DataSource is working! Query result: " + result;
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR,
                "DataSource is NOT working: " + e.getMessage());
        }
    }
}
