package {{_lua:(vim.fn.expand("%:p:h"):gsub("[/\\]", ".")):gsub("^.",""):gsub("^.*src.main.java.", ""):gsub("^.*src.test.java.","")_}}; 
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import io.smallrye.common.annotation.RunOnVirtualThread;

@ApplicationScoped
public class {{_file_name_}} {

    @Incoming("name")
    @RunOnVirtualThread
    void consume({{_lua:(vim.fn.expand("%:t:r"):gsub("Consumer$", ""))_}} item) {
      {{_cursor_}}
    }
}
