package {{_lua:(vim.fn.expand("%:p:h"):gsub("[/\\]", ".")):gsub("^.",""):gsub("^.*src.main.java.", ""):gsub("^.*src.test.java.","")_}}; 

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.Callable;

import picocli.CommandLine.Command;
import picocli.CommandLine.Parameters;
import picocli.CommandLine.Unmatched;
import picocli.CommandLine.ExitCode;
import picocli.CommandLine.Option;

@Command(name = {{_lua:(vim.fn.expand("%:t:r")):gsub('Command$', ''):gsub('([A-Z]+)([A-Z][a-z])', '%1-%2'):gsub('([a-z])([A-Z])', '%1-%2'):gsub('^(.*)$', '"%1"'):lower() _}}, mixinStandardHelpOptions = true)
public class {{_file_name_}} implements Callable<Integer> {

    @Parameters(paramLabel = "<name>", defaultValue = "picocli", description = "The name.")
    String name;

    @Option(names = { "--namespace" }, description = "The namespace.")
    protected Optional<String> namespace = Optional.empty();

    @Unmatched
    private List<String> unmatched = new ArrayList<>();

    @Override
    public Integer call() {
        System.out.printf("Hello %s, go go commando!\n", name);
        return ExitCode.OK;
    }

}
