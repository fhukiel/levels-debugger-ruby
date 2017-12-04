# A debugger for use with the levels package for Ruby

![Levels Debugger Ruby](https://user-images.githubusercontent.com/26176396/33531533-9c6f21b4-d88e-11e7-9b64-45f0cc4fd74d.png)

This package contains a debugger for use with the [`levels-language-ruby`](https://github.com/lakrme/atom-levels-language-ruby) package, which in turn uses the [`levels`](https://github.com/lakrme/atom-levels) package. Both packages are required dependencies and will be installed automatically if they are not already installed.

Using this debugger you will be able to step through your Ruby programs line by line, toggle breakpoints and inspect variables. Furthermore, you will be able to see the call stack and replay your program from a call on forward.

To get started, you may want to take a look at the [user manual](https://github.com/fhukiel/levels-debugger-ruby/wiki#user-manual).

**Note:** This package is not meant as a general purpose Ruby debugger for Atom. It will only work with the `levels-language-ruby` dialect as it is meant to support the beginners computer science course taught at [Kiel University](https://www.uni-kiel.de), which uses the `levels-language-ruby` dialect.

## Requirements

To use the debugger you need at least a Java 8 runtime environment and of course a current Ruby installation.