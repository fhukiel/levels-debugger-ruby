## 0.5.8 (2019-05-25)

* Added separators to the package menu
* Updated `atom-package-deps` to version 5.1.0

## 0.5.7 (2017-11-29)

* Removed the soon to be deprecated and undocumented Atom function `::showSaveDialogSync`

## 0.5.6 (2017-11-01)

* Fixed the misalignment of variable table columns
* Converted all CSON files to JSON
* Converted all CoffeeScript files to JavaScript

## 0.5.5 (2017-10-02)

* Disabled the debugger for level languages other than Ruby

## 0.5.4 (2017-09-30)

* Changed the border color of the tables to the pane item border color

## 0.5.3 (2017-09-18)

* Bug fixes and performance improvements

## 0.5.2 (2017-09-05)

* Bug fixes and performance improvements

## 0.5.1 (2017-08-31)

* Added menu entry and keyboard shortcut to stop a replay
* Converted title tooltips into Atom's beautiful native tooltips
* Fixed a bug where a replay could be started during running status

## 0.5.0 (2017-08-30)

* Improved the debugger state when switching between different files, language grammars and levels
* Added support for multiple cursors when adding or removing breakpoints
* Disabled the stepping commands when a blocking status reached
* Fixed a bug where the ruby program was not terminated correctly

## 0.4.3 (2017-08-25)

* Made the status div scrollable when the status text is too long
* Moved the user manual to a wiki page

## 0.4.2 (2017-08-19)

* Changed the scrolling behavior of the stack and variable table so that the table headers are always visible

## 0.4.1 (2017-08-19)

* Fixed a bug where some keyboard shortcuts failed within a not debuggable file

## 0.4.0 (2017-08-18)

* Added keybord shortcuts and menu entries to control the debugger
* Converted the debugger view into a dock item
* Removed the `atom-space-pen-view` dependency

## 0.3.0 (2017-05-14)

* Removed the `atom-text-editor` shadow DOM boundary
* Fixed a bug that caused some Atom window elements to be rendered with the wrong style

## 0.2.7 (2016-11-24)

* Added a user manual

## 0.2.6 (2016-08-08)

* Updated the debugger executable to the latest version

## 0.2.5 (2016-07-31)

* Updated the stylesheet so that variables and the call stack are no longer limited in size

## 0.2.4 (2016-07-23)

* Updated the debugger executable to the latest version

## 0.2.3 (2016-06-29)

* Updated the debugger executable to the latest version

## 0.2.2 (2016-06-24)

* Added `atom-package-deps` as a dependency to install the required `levels` and `levels-language-ruby` packages

## 0.2.1 (2016-06-24)

* Updated the debugger executable to the latest version
* Fixed a bug that caused the executor to try and kill a non-existing process

## 0.2.0 (2016-06-11)

* Fixed a timing error that caused the view to connect to the debugger executable before it had opened the communication channel

## 0.1.0 (2016-06-09)

* First release