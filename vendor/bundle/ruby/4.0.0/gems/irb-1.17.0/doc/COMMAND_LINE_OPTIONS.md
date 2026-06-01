# Index of Command-Line Options

These are the IRB command-line options, with links to explanatory text:

- `-d`: Set `$DEBUG` and {$VERBOSE}[rdoc-ref:IRB@Verbosity]
  to `true`.
- `-E _ex_[:_in_]`: Set initial external (ex) and internal (in)
  {encodings}[rdoc-ref:IRB@Encodings] (same as `ruby -E`).
- `-f`: Don't initialize from {configuration file}[rdoc-ref:IRB@Configuration+File].
- `-I _dirpath_`: Specify {$LOAD_PATH directory}[rdoc-ref:IRB@Load+Modules]
  (same as `ruby -I`).
- `-r _load-module_`: Require {load-module}[rdoc-ref:IRB@Load+Modules]
  (same as `ruby -r`).
- `-U`: Set external and internal {encodings}[rdoc-ref:IRB@Encodings] to UTF-8.
- `-w`: Suppress {warnings}[rdoc-ref:IRB@Warnings] (same as `ruby -w`).
- `-W[_level_]`: Set {warning level}[rdoc-ref:IRB@Warnings];
  0=silence, 1=medium, 2=verbose (same as `ruby -W`).
- `--autocomplete`: Use {auto-completion}[rdoc-ref:IRB@Automatic+Completion].
- `--back-trace-limit _n_`: Set a {backtrace limit}[rdoc-ref:IRB@Tracer];
  display at most the top `n` and bottom `n` entries.
- `--colorize`: Use {color-highlighting}[rdoc-ref:IRB@Color+Highlighting]
  for input and output.
- `--context-mode _n_`: Select method to create Binding object
  for new {workspace}[rdoc-ref:IRB@Commands]; `n` in range `0..5`.
- `--echo`: Print ({echo}[rdoc-ref:IRB@Return-Value+Printing+-28Echoing-29])
  return values.
- `--extra-doc-dir _dirpath_`:
  Add a {documentation directory}[rdoc-ref:IRB@RI+Documentation+Directories]
  for the documentation dialog.
- `--inf-ruby-mode`: Set prompt mode to {:INF_RUBY}[rdoc-ref:IRB@Pre-Defined+Prompts]
  (appropriate for `inf-ruby-mode` on Emacs);
  suppresses --multiline and --singleline.
- `--inspect`: Use method `inspect` for printing ({echoing}[rdoc-ref:IRB@Return-Value+Printing+-28Echoing-29])
  return values.
- `--multiline`: Use the multiline editor as the {input method}[rdoc-ref:IRB@Input+Method].
- `--noautocomplete`: Don't use {auto-completion}[rdoc-ref:IRB@Automatic+Completion].
- `--nocolorize`: Don't use {color-highlighting}[rdoc-ref:IRB@Color+Highlighting]
  for input and output.
- `--noecho`: Don't print ({echo}[rdoc-ref:IRB@Return-Value+Printing+-28Echoing-29])
  return values.
- `--noecho-on-assignment`: Don't print ({echo}[rdoc-ref:IRB@Return-Value+Printing+-28Echoing-29])
  result on assignment.
- `--noinspect`: Don't se method `inspect` for printing ({echoing}[rdoc-ref:IRB@Return-Value+Printing+-28Echoing-29])
  return values.
- `--nomultiline`: Don't use the multiline editor as the {input method}[rdoc-ref:IRB@Input+Method].
- `--noprompt`: Don't print {prompts}[rdoc-ref:IRB@Prompt+and+Return+Formats].
- `--noscript`:  Treat the first command-line argument as a normal
  {command-line argument}[rdoc-ref:IRB@Initialization+Script],
  and include it in `ARGV`.
- `--nosingleline`: Don't use the singleline editor as the {input method}[rdoc-ref:IRB@Input+Method].
- `--noverbose`: Don't print {verbose}[rdoc-ref:IRB@Verbosity] details.
- `--prompt _mode_`, `--prompt-mode _mode_`:
  Set {prompt and return formats}[rdoc-ref:IRB@Prompt+and+Return+Formats];
  `mode` may be a {pre-defined prompt}[rdoc-ref:IRB@Pre-Defined+Prompts]
  or the name of a {custom prompt}[rdoc-ref:IRB@Custom+Prompts].
- `--script`: Treat the first command-line argument as the path to an
  {initialization script}[rdoc-ref:IRB@Initialization+Script],
  and omit it from `ARGV`.
- `--simple-prompt`, `--sample-book-mode`:
  Set prompt mode to {:SIMPLE}[rdoc-ref:IRB@Pre-Defined+Prompts].
- `--singleline`: Use the singleline editor as the {input method}[rdoc-ref:IRB@Input+Method].
- `--tracer`: Use {Tracer}[rdoc-ref:IRB@Tracer] to print a stack trace for each input command.
- `--truncate-echo-on-assignment`: Print ({echo}[rdoc-ref:IRB@Return-Value+Printing+-28Echoing-29])
  truncated result on assignment.
- `--verbose`Print {verbose}[rdoc-ref:IRB@Verbosity] details.
- `-v`, `--version`: Print the {IRB version}[rdoc-ref:IRB@Version].
- `-h`, `--help`: Print the {IRB help text}[rdoc-ref:IRB@Help].
- `--`: Separate options from {arguments}[rdoc-ref:IRB@Command-Line+Arguments]
  on the command-line.
