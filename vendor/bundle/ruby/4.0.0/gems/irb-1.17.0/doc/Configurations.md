# Configure IRB

## Configuration Sources

IRB configurations can be set through multiple sources, each with its own precedence:

1. **Command-Line Options**: When some options are specified when starting IRB, they can override default settings.
2. **Configuration File**: If present, IRB reads a configuration file containing Ruby code to set configurations.
3. **Environment Variables**: Certain environment variables influence IRB's behavior.
4. **Hash `IRB.conf`**: This hash holds the current configuration settings, which can be modified during a session.

### Configuration File Path Resolution

IRB searches for a configuration file in the following order:

1. `$IRBRC`
2. `$XDG_CONFIG_HOME/irb/irbrc`
3. `$HOME/.irbrc`
4. `$HOME/.config/irb/irbrc` (only if `XDG_CONFIG_HOME` is _not_ set)
5. `.irbrc` in the current directory
6. `_irbrc` in the current directory
7. `$irbrc` in the current directory

If the `-f` command-line option is used, no configuration file is loaded.

Method `conf.rc?` returns `true` if a configuration file was read, `false` otherwise. Hash entry `IRB.conf[:RC]` also contains that value.

## Environment Variables

- `NO_COLOR`: Disables IRB's colorization.
- `IRB_USE_AUTOCOMPLETE`: Setting to `false` disables autocompletion.
- `IRB_COMPLETOR`: Configures auto-completion behavior (`regexp` or `type`).
- `IRB_COPY_COMMAND`: Overrides the default program used to interface with the system clipboard.
- `VISUAL` / `EDITOR`: Specifies the editor for the `edit` command.
- `IRBRC`: Specifies the rc-file for configuration.
- `XDG_CONFIG_HOME`: Used to locate the user-specific rc-file (i.e. `$XDG_CONFIG_HOME/irb/irbrc` instead of `$HOME/.config/irb/irbrc`).
- `RI_PAGER` / `PAGER`: Specifies the pager for documentation.
- `IRB_LANG`, `LC_MESSAGES`, `LC_ALL`, `LANG`: Determines the locale.

## Hash `IRB.conf`

The initial entries in hash `IRB.conf` are determined by:

- Default values.
- Command-line options, which may override defaults.
- Direct assignments in the configuration file.

You can see the hash by typing `IRB.conf`. Below are the primary entries:

- `:AP_NAME`: IRB {application name}[rdoc-ref:IRB@Application+Name];
  initial value: `'irb'`.
- `:AT_EXIT`: Array of hooks to call
  {at exit}[rdoc-ref:IRB@IRB];
  initial value: `[]`.
- `:AUTO_INDENT`: Whether {automatic indentation}[rdoc-ref:IRB@Automatic+Indentation]
  is enabled; initial value: `true`.
- `:BACK_TRACE_LIMIT`: Sets the {back trace limit}[rdoc-ref:IRB@Tracer];
  initial value: `16`.
- `:COMMAND_ALIASES`: Defines input {command aliases}[rdoc-ref:IRB@Command+Aliases];
  initial value:

        {
          "$": :show_source,
          "@": :whereami,
        }

- `:CONTEXT_MODE`: Sets the {context mode}[rdoc-ref:IRB@Context+Mode],
  the type of binding to be used when evaluating statements;
  initial value: `4`.
- `:ECHO`: Whether to print ({echo}[rdoc-ref:IRB@Return-Value+Printing+-28Echoing-29])
  return values;
  initial value: `nil`, which would set `conf.echo` to `true`.
- `:ECHO_ON_ASSIGNMENT`: Whether to print ({echo}[rdoc-ref:IRB@Return-Value+Printing+-28Echoing-29])
  return values on assignment;
  initial value: `nil`, which would set `conf.echo_on_assignment` to `:truncate`.
- `:EVAL_HISTORY`: How much {evaluation history}[rdoc-ref:IRB@Evaluation+History]
  is to be stored; initial value: `nil`.
- `:EXTRA_DOC_DIRS`: Array of
  {RI documentation directories}[rdoc-ref:IRB@RI+Documentation+Directories]
  to be parsed for the documentation dialog;
  initial value: `[]`.
- `:IGNORE_EOF`: Whether to ignore {end-of-file}[rdoc-ref:IRB@End-of-File];
  initial value: `false`.
- `:IGNORE_SIGINT`: Whether to ignore {SIGINT}[rdoc-ref:IRB@SIGINT];
  initial value: `true`.
- `:INSPECT_MODE`: Whether to use method `inspect` for printing
  ({echoing}[rdoc-ref:IRB@Return-Value+Printing+-28Echoing-29]) return values;
  initial value: `true`.
- `:IRB_LIB_PATH`: The path to the {IRB library directory}[rdoc-ref:IRB@IRB+Library+Directory]; initial value:

      - `"<i>RUBY_DIR</i>/lib/ruby/gems/<i>RUBY_VER_NUM</i>/gems/irb-<i>IRB_VER_NUM</i>/lib/irb"`,

    where:

      - <i>RUBY_DIR</i> is the Ruby installation dirpath.
      - <i>RUBY_VER_NUM</i> is the Ruby version number.
      - <i>IRB_VER_NUM</i> is the IRB version number.

- `:IRB_NAME`: {IRB name}[rdoc-ref:IRB@IRB+Name];
  initial value: `'irb'`.
- `:IRB_RC`: {Configuration monitor}[rdoc-ref:IRB@Configuration+Monitor];
  initial value: `nil`.
- `:LC_MESSAGES`: {Locale}[rdoc-ref:IRB@Locale];
  initial value: IRB::Locale object.
- `:LOAD_MODULES`: deprecated.
- `:MAIN_CONTEXT`: The {context}[rdoc-ref:IRB@Session+Context] for the main IRB session;
  initial value: IRB::Context object.
- `:MEASURE`: Whether to
  {measure performance}[rdoc-ref:IRB@Performance+Measurement];
  initial value: `false`.
- `:MEASURE_CALLBACKS`: Callback methods for
  {performance measurement}[rdoc-ref:IRB@Performance+Measurement];
  initial value: `[]`.
- `:MEASURE_PROC`: Procs for
  {performance measurement}[rdoc-ref:IRB@Performance+Measurement];
  initial value:

        {
          :TIME=>#<Proc:0x0000556e271c6598 /var/lib/gems/3.0.0/gems/irb-1.8.3/lib/irb/init.rb:106>,
          :STACKPROF=>#<Proc:0x0000556e271c6548 /var/lib/gems/3.0.0/gems/irb-1.8.3/lib/irb/init.rb:116>
        }

- `:PROMPT`: Hash of {defined prompts}[rdoc-ref:IRB@Prompt+and+Return+Formats];
  initial value:

        {
          :NULL=>{:PROMPT_I=>nil, :PROMPT_S=>nil, :PROMPT_C=>nil, :RETURN=>"%s\n"},
          :DEFAULT=>{:PROMPT_I=>"%N(%m):%03n> ", :PROMPT_S=>"%N(%m):%03n%l ", :PROMPT_C=>"%N(%m):%03n* ", :RETURN=>"=> %s\n"},
          :CLASSIC=>{:PROMPT_I=>"%N(%m):%03n:%i> ", :PROMPT_S=>"%N(%m):%03n:%i%l ", :PROMPT_C=>"%N(%m):%03n:%i* ", :RETURN=>"%s\n"},
          :SIMPLE=>{:PROMPT_I=>">> ", :PROMPT_S=>"%l> ", :PROMPT_C=>"?> ", :RETURN=>"=> %s\n"},
          :INF_RUBY=>{:PROMPT_I=>"%N(%m):%03n> ", :PROMPT_S=>nil, :PROMPT_C=>nil, :RETURN=>"%s\n", :AUTO_INDENT=>true},
          :XMP=>{:PROMPT_I=>nil, :PROMPT_S=>nil, :PROMPT_C=>nil, :RETURN=>"    ==>%s\n"}
        }

- `:PROMPT_MODE`: Name of {current prompt}[rdoc-ref:IRB@Prompt+and+Return+Formats];
  initial value: `:DEFAULT`.
- `:RC`: Whether a {configuration file}[rdoc-ref:IRB@Configuration+File]
  was found and interpreted;
  initial value: `true` if a configuration file was found, `false` otherwise.
- `:SAVE_HISTORY`: Number of commands to save in
  {input command history}[rdoc-ref:IRB@Input+Command+History];
  initial value: `1000`.
- `:SINGLE_IRB`: Whether command-line option `--single-irb` was given;
  initial value: `true` if the option was given, `false` otherwise.
  See {Single-IRB Mode}[rdoc-ref:IRB@Single-IRB+Mode].
- `:USE_AUTOCOMPLETE`: Whether to use
  {automatic completion}[rdoc-ref:IRB@Automatic+Completion];
  initial value: `true`.
- `:USE_COLORIZE`: Whether to use
  {color highlighting}[rdoc-ref:IRB@Color+Highlighting];
  initial value: `true`.
- `:USE_LOADER`: Whether to use the
  {IRB loader}[rdoc-ref:IRB@IRB+Loader] for `require` and `load`;
  initial value: `false`.
- `:USE_TRACER`: Whether to use the
  {IRB tracer}[rdoc-ref:IRB@Tracer];
  initial value: `false`.
- `:USE_PAGER`: Controls whether pager is enabled.
  initial value: `true`.
- `:VERBOSE`: Whether to print {verbose output}[rdoc-ref:IRB@Verbosity];
  initial value: `nil`.
- `:__MAIN__`: The main IRB object;
  initial value: `main`.

## Notes on Initialization Precedence

- Any conflict between an entry in hash `IRB.conf` and a command-line option is resolved in favor of the hash entry.
- Hash `IRB.conf` affects the context only once, when the configuration file is interpreted; any subsequent changes to it do not affect the context and are therefore essentially meaningless.

## Load Modules

You can specify the names of modules that are to be required at startup.

Array `conf.load_modules` determines the modules (if any) that are to be required during session startup. The array is used only during session startup, so the initial value is the only one that counts.

The default initial value is `[]` (load no modules):

```console
irb(main):001> conf.load_modules
=> []
```

You can set the default initial value via:

- Command-line option `-r`

    ```console
    $ irb -r csv -r json
    irb(main):001> conf.load_modules
    => ["csv", "json"]
    ```

- Hash entry `IRB.conf[:LOAD_MODULES] = *array*`:

    ```ruby
    IRB.conf[:LOAD_MODULES] = %w[csv json]
    ```

Note that the configuration file entry overrides the command-line options.

## RI Documentation Directories

You can specify the paths to RI documentation directories that are to be loaded (in addition to the default directories) at startup; see details about RI by typing `ri --help`.

Array `conf.extra_doc_dirs` determines the directories (if any) that are to be loaded during session startup. The array is used only during session startup, so the initial value is the only one that counts.

The default initial value is `[]` (load no extra documentation):

```console
irb(main):001> conf.extra_doc_dirs
=> []
```

You can set the default initial value via:

- Command-line option `--extra_doc_dir`

    ```console
    $ irb --extra-doc-dir your_doc_dir --extra-doc-dir my_doc_dir
    irb(main):001> conf.extra_doc_dirs
    => ["your_doc_dir", "my_doc_dir"]
    ```

- Hash entry `IRB.conf[:EXTRA_DOC_DIRS] = *array*`:

    ```ruby
    IRB.conf[:EXTRA_DOC_DIRS] = %w[your_doc_dir my_doc_dir]
    ```

Note that the configuration file entry overrides the command-line options.

## IRB Name

You can specify a name for IRB.

The default initial value is `'irb'`:

```console
irb(main):001> conf.irb_name
=> "irb"
```

You can set the default initial value via hash entry `IRB.conf[:IRB_NAME] = *string*`:

```ruby
IRB.conf[:IRB_NAME] = 'foo'
```

## Application Name

You can specify an application name for the IRB session.

The default initial value is `'irb'`:

```console
irb(main):001> conf.ap_name
=> "irb"
```

You can set the default initial value via hash entry `IRB.conf[:AP_NAME] = *string*`:

```ruby
IRB.conf[:AP_NAME] = 'my_ap_name'
```

## Configuration Monitor

You can monitor changes to the configuration by assigning a proc to `IRB.conf[:IRB_RC]` in the configuration file:

```console
IRB.conf[:IRB_RC] = proc {|conf| puts conf.class }
```

Each time the configuration is changed, that proc is called with argument `conf`:
