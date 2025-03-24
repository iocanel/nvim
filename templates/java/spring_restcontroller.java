package {{_lua:(vim.fn.expand("%:p:h"):gsub("[/\\]", ".")):gsub("^.",""):gsub("^.*src.main.java.", ""):gsub("^.*src.test.java.","")_}}; 

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestControl

public class {{_file_name_}} {

    @RequestMapping("/")
    public String hello() {
       {{_cursor_}}
       return  "Hello World!";
    }
}
