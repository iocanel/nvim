package {{_lua:(vim.fn.expand("%:p:h"):gsub("[/\\]", ".")):gsub("^.",""):gsub("^.*src.main.java.", ""):gsub("^.*src.test.java.","")_}}; 

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.sql.DataSource;

@Configuration
public class {{_file_name_}} {

  @Value("${username}")
  private String username;
  @Value("${password}")
  private String password;
  @Value("${uri}")
  private String uri;
  @Value("${database_name}")
  private String databaseName;

  @Bean
  DataSource create() {
    return DataSourceBuilder.create()
      .username(username)
      .password(password)
      .url(uri.replaceAll("postgres", "jdbc:postgresql") + "/" + databaseName)
      .driverClassName("org.postgresql.Driver")
      .build();
  }
}
