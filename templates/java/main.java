package {{_lua:(vim.fn.expand("%:p:h"):gsub("[/\\]", ".")):gsub("^.",""):gsub("^.*src.main.java.", ""):gsub("^.*src.test.java.","")_}}; 


public class {{_file_name_}} {

  public static void main(String args[]) {
    {{_cursor_}}
  }
}
