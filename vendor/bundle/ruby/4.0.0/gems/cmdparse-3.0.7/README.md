**cmdparse** - an advanced command line parser using optparse which has support for commands

Copyright (C) 2004-2020 Thomas Leitner

## Description

Some programs use a "command style" command line. Examples for such programs are the "gem" program
from Rubygems and the "svn" program from Subversion. The standard Ruby distribution has no library
to create programs that use such a command line interface.

This library, cmdparse, can be used to create such a command line interface. Internally it uses
optparse to parse options and it provides a nice API for specifying commands.

See <https://cmdparse.gettalong.org> for detailed information, an extensive tutorial and the API
reference!


## Documentation

You can build the documentation by invoking

    $ rake doc

This builds the whole documentation and needs webgen >=1.4.0 (https://webgen.gettalong.org) for
building.


## Example Usage

There is an example of how to use cmdparse in the `example/net.rb` file. A detailed walkthrough of
what each part does can be found on <https://cmdparse.gettalong.org/tutorial.html>.


## License

MIT - see COPYING.


## Dependencies

none


## Installation

The preferred way of installing cmdparse is via RubyGems:

    $ gem install cmdparse

If you don't want to use RubyGems, use these commands:

    $ ruby setup.rb config
    $ ruby setup.rb setup
    $ ruby setup.rb install


## Contact

Author: Thomas Leitner

* Web: <https://cmdparse.gettalong.org>
* e-Mail: <mailto:t_leitner@gmx.at>
