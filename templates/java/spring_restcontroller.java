package {{_lua:(vim.fn.expand("%:p:h"):gsub("[/\\]", ".")):gsub("^.",""):gsub("^.*src.main.java.", ""):gsub("^.*src.test.java.","")_}}; 

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class {{_file_name_}} {

    @GetMapping("/")
    public String hello() {
       {{_cursor_}}
       return  "Hello World!";
    }
}
