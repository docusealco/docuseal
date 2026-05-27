# ERB (Embedded Ruby)

ERB is an easy-to-use, but also very powerful, [template processor][template processor].

ERB is commonly used to produce:

- Customized or personalized email messages.
- Customized or personalized web pages.
- Software code (in code-generating applications).

Like method [sprintf][sprintf], ERB can format run-time data into a string.
ERB, however, is *much more powerful*

## How ERB Works

Using ERB, you can create a *template*: a plain-text string that has specially-formatted *tags*,
then store it into an ERB object;
when ERB produces _result_ string, it:

- Inserts run-time-evaluated expressions into the result.
- Executes snippets of Ruby code.
- Omits comments from the results.

In the result:

- All non-tag text is passed through, _unchanged_.
- Each tag is either _replaced_ (expression tag),
  or _omitted_ entirely (execution tag or comment tag).

There are three types of tags:

| Tag            |                 Form                 |                Action                 |    Text in Result    |
|----------------|:------------------------------------:|:-------------------------------------:|:--------------------:|
| Expression tag | <tt>'<%= _ruby_expression_ %>'</tt>  | Evaluates <tt>_ruby_expression_</tt>. | Value of expression. |       
| Execution tag  |     <tt>'<% _ruby_code_ %>'</tt>     |     Execute <tt>_ruby_code_</tt>.     |        None.         |                 
| Comment tag    |   <tt>'<%# _comment_text_ %>'</tt>   |                 None.                 |        None.         |

These examples use `erb`, the ERB command-line interface;
each "echoes" a string template and pipes it to `erb` as input:


- Expression tag:

        $ echo "<%= $VERBOSE %>" | erb
        "false"
        $ echo "<%= 2 + 2 %>" | erb
        "4"

- Execution tag:

        echo "<% if $VERBOSE %> Long message. <% else %> Short message. <% end %>" | erb
        " Short message. "

- Comment tag:

        echo "<%# TODO: Fix this nonsense. %> Nonsense." | erb
        " Nonsense."

## How to Use ERB

You can use ERB either:

- In a program: see class ERB.
- From the command line: see [ERB Executable][erb executable].

## Installation

ERB is installed with Ruby, and so there's no further installation needed.

## Other Template Engines

There are a variety of template engines available in various Ruby projects.
For example, [RDoc][rdoc], distributed with Ruby, uses its own template engine, which
can be reused elsewhere.

Other popular template engines may be found in the [Ruby Toolbox][ruby toolbox].

## Code

The ERB source code is in GitHub project [ruby/erb][ruby/erb].

## Bugs

Bugfixes may be filed at [ERB Pull Requests][erb pull requests].

## License

This software is available as open source under the terms
of the [2-Clause BSD License][2-clause bsd license].

[2-clause bsd license]: https://opensource.org/licenses/BSD-2-Clause
[erb executable]:       rdoc-ref:erb_executable.md
[erb pull requests]:    https://github.com/ruby/erb/pull
[rdoc]:                 https://ruby.github.io/rdoc/
[ruby/erb]:             https://github.com/ruby/erb
[ruby toolbox]:         https://www.ruby-toolbox.com/categories/template_engines
[sprintf]:              https://docs.ruby-lang.org/en/master/Kernel.html#method-i-sprintf
[template processor]:   https://en.wikipedia.org/wiki/Template_processor_
