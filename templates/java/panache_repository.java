package {{_lua:(vim.fn.expand("%:p:h"):gsub("[/\\]", ".")):gsub("^.",""):gsub("^.*src.main.java.", ""):gsub("^.*src.test.java.","")_}}; 

import io.quarkus.hibernate.orm.panache.PanacheRepository;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class {{_file_name_}} implements PanacheRepository<{{_lua:(vim.fn.expand("%:t:r"):gsub("Repository$", ""))_}}> {

}
