# \ERB Executable

The `erb` executable gives command-line access to ERB template processing.

The executable is installed with \ERB, which is part of the Ruby installation.

For a quick summary, type:

```bash
$ erb --help
```

The format of the command is
`erb [_options_] [_filepaths_]`,
where:

- _options_ are zero or more [options][options].
- _filepaths_ are zero or more paths to files, each containing an plain text
  that can include \ERB tags.

## Filepaths

With one or more _filepaths_ given, `erb` reads all the given files as a single template;
that is, `erb` processes multiple files into a single result:

```bash
$ cat t.erb
<%= RUBY_VERSION %>
<%= Time.now %>
$ cat u.erb
% Encoding.list.take(4).each do |encoding|
* <%= encoding %>
% end
$ erb t.erb u.erb
3.4.5
2025-09-24 00:23:00 +0100
* ASCII-8BIT
* UTF-8
* US-ASCII
* UTF-16BE
```

There is a special "filepath", `'-'`, that specifies the standard input:

```bash
$ echo "<%= RUBY_VERSION %>" | erb u.erb -
* ASCII-8BIT
* UTF-8
* US-ASCII
* UTF-16BE
3.4.5
```

Any filepath, including `'-'`, may be repeated.

With no _filepaths_ given, `erb` reads and processes the standard input:

```bash
$ echo "<%= RUBY_VERSION %>" | erb # Prints the ERB version string.
```

## Options

### `-d`, `--debug`: Set $DEBUG

Use option `-d` or `--debug` to turn on debugging output:

```bash
$ echo "<%= $DEBUG %>" | erb
"false"
$echo "<%= $DEBUG %>" | erb --debug
"true"
```

### `-E`, `--encoding`: Set Encodings

Use option `-E` or `--encoding` to set the default external encoding to `_ex_`
and, if `_in_` is given, to set the default internal encoding to `_in_`.

Each encoding, `ex` and `in`, must be the name of an Encoding:

```
erb  -E ASCII-8BIT:ASCII-8BIT t.erb
```

### `-h`, `--help`: Print Help

Use option `-h` or `--help` to print `erb` help text:

```bash
$ erb --help
```

### `-n`: Print Source with Line Numbers

Use option `-n` with option `-x` to print the output of ERB#src,
with numbered lines:

```bash
$ cat t.erb
<%= RUBY_VERSION %>
<%= Time.now %>
$ erb -n -x t.erb
  1 #coding:UTF-8
  2 _erbout = +''; _erbout.<<(( RUBY_VERSION ).to_s); _erbout.<< "\n".freeze
  3 ; _erbout.<<(( Time.now ).to_s); _erbout.<< "\n".freeze
  4 ; _erbout
```

Using option `-n` without option `-x` has no effect:

```bash
$ erb -n t.erb
3.4.5
2025-09-23 02:44:57 +0100
```

### `-P`: Disable Execution Tag Shorthand

By default, `erb` enables [execution tag shorthand][execution tag shorthand]:

```
$ cat u.erb
% Encoding.list.take(4).each do |encoding|
* <%= encoding %>
% end
$ erb u.erb
* ASCII-8BIT
* UTF-8
* US-ASCII
* UTF-16BE
```

You can use option `-P` to disable the shorthand:

```
$ erb -P u.erb # Raises NameError: "undefined local variable or method 'encoding'"
```

### `-r`: Load Library

You can use option `-r` to load a library;
the option may be given multiple times, to load multiple libraries:

```
$ erb -r csv -r bigdecimal t.erb
```

### `-T`: Set Trim Mode

You can use option `-T` to set the trim mode.

The values for the option are:

- `'0'`, meaning `'%'`; enable execution tag shorthand;
  see [execution tag shorthand][execution tag shorthand].
- `'1'`, meaning `'%>'`: enable execution tag shorthand and omit newline for each line ending with `'%>'`;
  see [suppressing unwanted newlines][suppressing unwanted newlines].
- `'2'`, meaning `'<>'`:  to suppress the trailing newline for each line
  that both begins with `'<%'` and ends with `'%>'`;
  see [suppressing unwanted newlines][suppressing unwanted newlines].
- `'-'`, meaning `'%-'`: enable execution tag shorthand and omit each blank line ending with `'-%>'`.
  see [execution tag shorthand][execution tag shorthand]
  and [suppressing unwanted blank lines][suppressing unwanted blank lines].

Example:

```bash
$ erb -T 0 t.erb
```

### `-U`: Set Default Encodings to UTF-8

You can use option `-U` to set both external and internal encodings to UTF-8:

```bash
$ erb -U t.erb
```

### `-v`: Set $VERBOSE

Use option `-v` to turn on verbose output:

```bash
$ $ "<%= $VERBOSE %>" | erb
"false"
$ echo "<%= $VERBOSE %>" | erb -v
"true"
```

### `-v`: Print \ERB Version

Use option `--version` to print the \ERB version string:

```bash
$ erb --version
```

### `-x`: Print Source

Use option `-x` to print the output of ERB#src,
which is the Ruby code that is to be run when ERB#result is called:

```bash
$ cat t.erb
<%= RUBY_VERSION %>
<%= Time.now %>
$ erb -x t.erb
#coding:UTF-8
_erbout = +''; _erbout.<<(( RUBY_VERSION ).to_s); _erbout.<< "\n".freeze
; _erbout.<<(( Time.now ).to_s); _erbout.<< "\n".freeze
; _erbout
```

### `--`: End of Options

You can use option `'--'` to declare the end of options in the `erb` command;
`erb` treats each word following as a filepath (even if it looks like an option):

```
erb -- --help # Raises Errno::ENOENT: "No such file or directory @ rb_sysopen - --help"
```

### `name=value`: Set the Value of a Variable

You can use option `name=value` to set the value of the variable named `name`
to the given `value`.

The option may be given multiple times to set multiple variables:

```bash
$ echo "<%= foo %> <%= bar %>" | erb foo=1 bar=2
"1 2"
```

[erb.new]: https://docs.ruby-lang.org/en/master/ERB.html#method-c-new.
[execution tag shorthand]: rdoc-ref:ERB@Shorthand+Format+for+Execution+Tags
[options]: rdoc-ref:erb_executable.md@Options
[suppressing unwanted blank lines]: rdoc-ref:ERB@Suppressing+Unwanted+Blank+Lines
[suppressing unwanted newlines]: rdoc-ref:ERB@Suppressing+Unwanted+Newlines