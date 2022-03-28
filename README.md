Emlua implements a *very minimalistic* way to run a Lua interpreter
inside Emacs *as a module*. Running a Lua REPL in Emacs [in a shell
buffer](http://www.gnu.org/software/emacs/manual/html_node/emacs/Interactive-Shell.html) is trivial - see [these slides](http://angg.twu.net/LATEX/2021emacsconf.pdf#page=3), the [page](http://angg.twu.net/emacsconf2021.html) of my presentation at
the EmacsConf2021, or [this tutorial of eepitch](http://angg.twu.net/eev-intros/find-eev-quick-intro.html#6) - but Emlua does
something different.

To test Emlua you will need: 1) an Emacs compiled with support for
[dynamic modules](http://www.gnu.org/software/emacs/manual/html_node/elisp/Dynamic-Modules.html), 2) [liblua5.3-dev](https://packages.debian.org/bullseye/liblua5.3-dev) or something equivalent to it,
and 3) [eev](http://angg.twu.net/#eev).

At this moment all the tests are either in [test blocks](http://angg.twu.net/emacsconf2021.html) or in [sexps in
comments](http://angg.twu.net/eev-intros/find-eev-quick-intro.html#3), so you will need [eev](http://angg.twu.net/#eev) to run them - but eev is a [very
non-invasive package](http://angg.twu.net/eev-intros/find-eev-intro.html#1) and it is easy to turn eev-mode on and off, so,
ahem, "everybody should have eev installed". 🙃

Here is a screenshot - click on it to enlarge:

<a href="2022eepitch-emlua-0.png"><IMG SRC="2022eepitch-emlua-0-small.png"></a>


# The low-level way

The low-level way to test Emlua is to run the test blocks in
[`emlua.cpp`](http://angg.twu.net/emlua/emlua.cpp.html#tests-in-tmp). Here is a copy of the body of the first test block:

    rm -Rfv /tmp/emlua/
    mkdir   /tmp/emlua/
    cd      /tmp/emlua/
    git clone https://github.com/edrx/emlua .
    make

It downloads a copy of emlua from the git repository and compiles
`emlua.cpp`. You may need to set some directories - for example, on my
machine I need this instead of a plain "`make`":

    make EMACS_DIR=$HOME/bigsrc/emacs29

Then load the module with this sexp,

    (load "emlua.so")

The test blocks in [`emlua.cpp`](http://angg.twu.net/emlua/emlua.cpp.html#tests-in-tmp) also contain sexps that let you run
some very low-level tests, like this one:

    (emlua-dostring "
      a = a or 0
      a = a + 1
      return 22+33, '44', {}, a, nil
    ")

The result of the sexp above is this:

    ["55" "44" "table: 0x55a0f1979040" "0" "nil"]

The function `emlua-dostring` is very primitive - it returns a vector
of strings in case of success, and a string in the case of errors.


# Exchanging data

The file [`emlua-data.el`](http://angg.twu.net/emlua/emlua-data.el.html) implements a very basic way to send strings
and numbers to Lua code. After loading it we can set the Lua variables
`a` and `b` to `2.34` and `"foo bar"` by running this:

    (emlua-dostring (emlua-format "a,b = %s,%s" 2.34 "foo bar"))
    (emlua-dostring "return a, type(a), b")
    ;;   -->          ["2.34" "number" "foo bar"]


# Two Lua REPLs written in Lua

The file [Repl1.lua](http://angg.twu.net/emlua/Repl1.lua.html) contains two Lua REPLs written in Lua. They can
both be tested by first running this [`setenv`](http://www.gnu.org/software/emacs/manual/html_node/emacs/Environment.html) to make Lua use [my init
file](http://angg.twu.net/emlua/edrxlib.lua.html),

    (setenv "LUA_INIT" "@/tmp/emlua/edrxlib.lua")

and then running the test blocks in `Repl1.lua`. The REPL implemented
by the class [`EdrxRepl`](http://angg.twu.net/emlua/Repl1.lua.html#EdrxRepl) is very simple, and the other one, implemented
by the class [`EdrxEmacsRepl`](http://angg.twu.net/emlua/Repl1.lua.html#EdrxEmacsRepl), is a variant of `EdrxRepl` that
[redirects](http://angg.twu.net/emlua/Repl1.lua.html#WithFakePrint) the outputs of `print` and `io.write` to a string before
writing it to stdout. The REPL that runs inside Emacs uses the class
`EdrxEmacsRepl`, but calls methods in it that return the output as a
string.


# The file emlua-init.el

The file [emlua-init.el](http://angg.twu.net/emlua/emlua-init.el.html) contains functions that load the lua module,
load edrxlib.lua and Repl1.lua, and create a global variable REPL in
the Lua interpreter containing an instance of the class EdrxEmacsRepl.
Try:

    (add-to-list 'load-path "/tmp/emlua/")
    (emlua-init-so)
    (emlua-init-dofiles)
    (emlua-init-newrepl)


# Accessing the files with code-c-d

If you understand how to create "[short hyperlinks](http://angg.twu.net/eev-intros/find-eev-quick-intro.html#9)" with [`code-c-d`](http://angg.twu.net/eev-intros/find-eev-quick-intro.html#9.1) in
eev you can use something like this to point to the files in the emlua
directory:

    (code-c-d "emlua" "/tmp/emlua/" :anchor)
    (find-emluafile "")
    (find-emluafile "emlua-data.lua")
    (find-emluafile "emlua-init.lua")
    (find-emluafile "README.org")
    (find-emluafile "Repl1.lua")
    (find-emlua "Repl1.lua")
    (find-emlua "Repl1.lua" "EdrxEmacsRepl")


# Running the Lua REPL in Emacs

The file [`emlua-repl.el`](http://angg.twu.net/emlua/emlua-repl.el.html) defines a function called [`eepitch-emlua`](http://angg.twu.net/emlua/emlua-repl.el.html#eepitch-emlua),
that is similar to [`eepitch-shell`](http://angg.twu.net/eev-intros/find-eev-quick-intro.html#6), but whose [target](http://angg.twu.net/eev-intros/find-eev-quick-intro.html#6.2) is the Lua
interpreter in the dynamic module. Take a look at the comments at the
top of the file [`emlua-repl.el`](http://angg.twu.net/emlua/emlua-repl.el.html).

Here is a [screenshot](http://angg.twu.net/IMAGES/2022eepitch-emlua-0.png),


# Testing everything

You should probably be able to test everything in just three steps: 1)
copy the block below to an Emacs buffer, 2) adjust the `EMACS_DIR`, 3)
run the block by typing <kbd>&lt;f8&gt;</kbd> on each line.
The bullets will behave as [red stars](http://angg.twu.net/eev-intros/find-eev-quick-intro.html#6.1), as explained [here](http://angg.twu.net/2020-list-packages-eev-nav.html#f8).

    • (eepitch-shell)
    • (eepitch-kill)
    • (eepitch-shell)
    rm -Rfv /tmp/emlua/
    mkdir   /tmp/emlua/
    cd      /tmp/emlua/
    git clone https://github.com/edrx/emlua .
    make EMACS_DIR=$HOME/bigsrc/emacs29
    
    • (add-to-list 'load-path "/tmp/emlua/")
    • (require 'emlua-repl)
    • (emlua-init)
    • (eepitch-emlua)
    • (eepitch-kill)
    • (eepitch-emlua)
    print(2 + 3)
    print(2 +
          3 +
          4)
    = 2,
      3,
      4
    = 2 + nil
    = EdrxEmacsRepl
    PPP(EdrxEmacsRepl)
    PPPV(EdrxEmacsRepl.__index)


# This is a prototype

At this moment `emlua` isn't very useful *per se*, but it is very easy
to hack and extend.


# Ideas

In Agda the same symbol can have different meanings depending on the
context, and the key <kbd>M-,</kbd> can be used to go the
source code of the symbol at point. This is implemented by storing the
location of the source of each symbol in a buffer in its [text
properties](http://www.gnu.org/software/emacs/manual/html_node/elisp/Text-Properties.html). See the screenshot below (click to enlarge it):

<a href="2022agda-mode-prop.png"><IMG SRC="2022agda-mode-prop-small.png"></a>

The function [`emlua-dostring+`](http://angg.twu.net/emlua/emlua-repl.el.html#emlua-dostring+) in `emlua-repl.el` executes Lua code
and interprets the result as elisp code to be executed by Emacs. We
can use it to generate text with properties, and we can use
`eepitch-emlua` to develop interactively the Lua functions that we
will call using `emlua-dostring+`.

Emacs can display SVG images - see the packages [svg](https://elpa.gnu.org/packages/svg.html) and [sketch-mode](https://github.com/dalanicolai/sketch-mode) -
and we can use `emlua-dostring+` to create and modify SVG images.

