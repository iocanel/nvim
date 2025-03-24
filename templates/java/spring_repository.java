package {{_lua:(vim.fn.expand("%:p:h"):gsub("[/\\]", ".")):gsub("^.",""):gsub("^.*src.main.java.", ""):gsub("^.*src.test.java.","")_}}; 

import org.springframework.data.jpa.repository.JpaRepository;

interface {{_file_name_}} extends JpaRepository<{{_lua:(vim.fn.expand("%:t:r"):gsub("Repository$", ""))_}}, Long> {

}



