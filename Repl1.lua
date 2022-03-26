-- This file:
--     http://angg.twu.net/LUA/Repl1.lua.html
--     http://angg.twu.net/LUA/Repl1.lua
--             (find-angg "LUA/Repl1.lua")
--   http://angg.twu.net/emlua/Repl1.lua.html
--   http://angg.twu.net/emlua/Repl1.lua
--           (find-angg "emlua/Repl1.lua")
-- https://raw.githubusercontent.com/edrx/emlua/main/Repl1.lua
--           https://github.com/edrx/emlua/blob/main/Repl1.lua
-- Author: Eduardo Ochs <eduardoochs@gmail.com>
-- Version: 2022mar26
-- License: GPL2
--
-- See: https://github.com/edrx/emlua

-- Tools:
-- «.WithFakePrint»		(to "WithFakePrint")
-- «.WithFakePrint-tests»	(to "WithFakePrint-tests")
-- «.ErrHandler»		(to "ErrHandler")
-- «.ErrHandler-tests»		(to "ErrHandler-tests")
--
-- The two repls:
-- «.MultiLineCmd»		(to "MultiLineCmd")
-- «.MultiLineCmd-tests»	(to "MultiLineCmd-tests")
-- «.EdrxRepl»			(to "EdrxRepl")
-- «.EdrxRepl-tests»		(to "EdrxRepl-tests")
-- «.EdrxEmacsRepl»		(to "EdrxEmacsRepl")
-- «.EdrxEmacsRepl-tests»	(to "EdrxEmacsRepl-tests")




-- __        ___ _   _     _____     _        ____       _       _   
-- \ \      / (_) |_| |__ |  ___|_ _| | _____|  _ \ _ __(_)_ __ | |_ 
--  \ \ /\ / /| | __| '_ \| |_ / _` | |/ / _ \ |_) | '__| | '_ \| __|
--   \ V  V / | | |_| | | |  _| (_| |   <  __/  __/| |  | | | | | |_ 
--    \_/\_/  |_|\__|_| |_|_|  \__,_|_|\_\___|_|   |_|  |_|_| |_|\__|
--                                                                   
-- «WithFakePrint»  (to ".WithFakePrint")
-- This class is not used by EdrxRepl, only by EdrxEmacsRepl.
--
-- WithFakePrint.run(f) runs f() with a fake print() function that
-- saves the results to the global variable withprint_. "f" must be a
-- function that does not yield errors; if it aborts the original
-- print will not be restored, and we're fscked.
--
-- WithFakePrint.run(f) also substitutes temporarily write() by a fake
-- write() function. I always use "write" instead of io.write" in my
-- code, so this trick works.
--
withprint_ = {}

WithFakePrint = Class {
  type      = "WithFakePrint",
  fakeprint = function (...)
      local A = pack(...)
      local out = mapconcat(tostring, A, "\t", A.n).."\n"
      table.insert(withprint_, out)
    end,
  fakewrite = function (str)
      table.insert(withprint_, str)
    end,
  out = function () return table.concat(withprint_, "") end,
  --
  run1 = function (f)
      local old_print = print
      local old_write = write
      print = WithFakePrint.fakeprint
      write = WithFakePrint.fakewrite
      local results = pack(f())
      print = old_print
      write = old_write
      return myunpack(results)
    end,
  run = function (f)
      withprint_ = {}
      WithFakePrint.run1(f)
      return WithFakePrint.out()
    end,
  xpcall = function (f, errhandler)
      errhandler = errhandler or WithFakePrint.errhandler
      return WithFakePrint.run(function () xpcall(f, errhandler) end)
    end,
  errhandler = function (err)
      print(err)
      print(debug.traceback())
    end,
  --
  __index = {
  },
}

-- «WithFakePrint-tests»  (to ".WithFakePrint-tests")
--[[
 (eepitch-lua51)
 (eepitch-kill)
 (eepitch-lua51)
dofile "Repl1.lua"
ff = function ()
    print(22, {}, nil)
    PP(22, {}, nil)
    return 33, 44
  end
ff()
= ff()
= "<<" .. WithFakePrint.run(                       ff       ) .. ">>"
= "<<" .. WithFakePrint.run(function ()            ff()  end) .. ">>"
= "<<" .. WithFakePrint.run(function () PP("ret:", ff()) end) .. ">>"
= "<<" .. WithFakePrint.xpcall(function ()
            PP("ret:", ff())
          end) ..
  ">>"
= "<<" .. WithFakePrint.xpcall(function ()
            PP("ret:", ff())
            error("foo")
          end) ..
  ">>"

--]]



--  _____           _   _                 _ _           
-- | ____|_ __ _ __| | | | __ _ _ __   __| | | ___ _ __ 
-- |  _| | '__| '__| |_| |/ _` | '_ \ / _` | |/ _ \ '__|
-- | |___| |  | |  |  _  | (_| | | | | (_| | |  __/ |   
-- |_____|_|  |_|  |_| |_|\__,_|_| |_|\__,_|_|\___|_|   
--                                                      
-- «ErrHandler»  (to ".ErrHandler")
-- Error handlers for xpcall.
-- The "prosody" error handler is explained here:
--
--   (find-angg "LUA/lua50init.lua" "DGetInfo")
--   (find-angg "LUA/lua50init.lua" "DGetInfo" "prosodytraceback =")
--   (find-angg "LUA/lua50init.lua" "DGetInfos")
--   (find-angg "LUA/lua50init.lua" "DGetInfos" "tb =")
--
-- and there are tests for it here:
--
--   (find-angg "LUA/Xpcall1.lua" "tests")
--
ErrHandler = Class {
  type    = "ErrHandler",
  builtin = function (err)
      print(err)
      print(debug.traceback())
    end,
  --
  deltop = 0,
  delbot = 0,
  prosody = function (err)
      dgis = DGetInfos.newv()
      print(dgis:tb(#dgis - ErrHandler.deltop, 1 + ErrHandler.delbot))
      print(err)
    end,
  --
  default = function (err)
      ErrHandler.prosody(err)
    end,
  --
  __index = {
  },
}

-- «ErrHandler-tests»  (to ".ErrHandler-tests")
--[[
 (eepitch-lua51)
 (eepitch-kill)
 (eepitch-lua51)
dofile "Repl1.lua"
F02 = function (a) return 1 + F01(a) end
F01 = function (a) return 1 + F00(a) end
F00 = function (a) return expr(a) end
xpcall(function () F02("error 'foo'") end,
       function (...) PP(...) end) 
xpcall(function () F02("error 'foo'") end,
       ErrHandler.prosody)
xpcall(function () F02("error 'foo'") end,
       ErrHandler.builtin)
xpcall(function () F02("error 'foo'") end,
       ErrHandler.default)

--]]







--  __  __       _ _   _ _     _             ____               _ 
-- |  \/  |_   _| | |_(_) |   (_)_ __   ___ / ___|_ __ ___   __| |
-- | |\/| | | | | | __| | |   | | '_ \ / _ \ |   | '_ ` _ \ / _` |
-- | |  | | |_| | | |_| | |___| | | | |  __/ |___| | | | | | (_| |
-- |_|  |_|\__,_|_|\__|_|_____|_|_| |_|\___|\____|_| |_| |_|\__,_|
--                                                                
-- «MultiLineCmd»  (to ".MultiLineCmd")
-- The class MultiLineCmd implements the hard part of the "read" part
-- of the read-eval-print loop of EdrxRepl. The simple part is:
--
--   mlc:status()   tells if the input is complete, incomplete,
--                  or has a compilation error,
--   mlc:add(line)  adds a line to the input.
--
-- Checking if the input is incomplete is very tricky, especially
-- because we need to support the prefix "=", that in the standard Lua
-- REPL means "treat the rest of the input as an expression and print
-- its result". This is done by the methods :luacode() and
-- :luacodewithprint(), that translate the input in different ways.
-- See the comments in the class EdrxRepl below to understand how
-- these translations are used.
--
-- See: (find-angg "emacs-lua/EdrxRepl.lua" "EdrxRepl")
--      (find-angg "emacs-lua/EdrxRepl.lua" "EdrxRepl" "near '?<eof>'?$")
--
MultiLineCmd = Class {
  type = "MultiLineCmd",
  new  = function (line) return MultiLineCmd({line}) end,
  __tostring = function (mlc) return mlc:concat() end,
  __index = {
    add = function (mlc, line) table.insert(mlc, line) end,
    prefix = function (mlc) return mlc[1]:match("^=?") end,
    concat = function (mlc) return table.concat(mlc, "\n") end,
    --
    luacode = function (mlc)
        return (mlc:concat():gsub("^=", "return "))
      end,
    luacodewithprint = function (mlc)
        return (mlc:concat():gsub("^=(.*)$", "print(%1\n  )"))
      end,
    --
    errincomplete = function (mlc)
        return mlc.err and mlc.err:find(" near '?<eof>'?$")
      end,
    status = function (mlc)
        mlc.f,mlc.err = loadstring(mlc:luacode())
	if mlc:errincomplete() then return "incomplete" end
	if mlc.f then
          mlc.f,mlc.err = loadstring(mlc:luacodewithprint())
          return "complete"
        end
        return "comp error"
      end,
    incomplete = function (mlc)
        return mlc:status() == "incomplete"
      end,
  },
}

-- «MultiLineCmd-tests»  (to ".MultiLineCmd-tests")
--[[
 (eepitch-lua51)
 (eepitch-kill)
 (eepitch-lua51)
dofile "Repl1.lua"
mlc = MultiLineCmd.new("print(22,")
               mlc:add("  33,")
= mlc
= mlc:status()
               mlc:add("  44)")
= mlc
= mlc:status()
= mlc:luacodewithprint()
= mlc.f()
mlc = MultiLineCmd.new("print(22!!!")
= mlc:status()
= mlc.err
mlc = MultiLineCmd.new("= 20,")
               mlc:add("  30,")
               mlc:add("  40 ")
= mlc
= mlc:status()
= mlc:luacodewithprint()
= mlc.f()

--]]



--  _____    _           ____            _ 
-- | ____|__| |_ ____  _|  _ \ ___ _ __ | |
-- |  _| / _` | '__\ \/ / |_) / _ \ '_ \| |
-- | |__| (_| | |   >  <|  _ <  __/ |_) | |
-- |_____\__,_|_|  /_/\_\_| \_\___| .__/|_|
--                                |_|      
--
-- «EdrxRepl»  (to ".EdrxRepl")
-- A simple REPL for Lua. Usage:
--
--   REPL = EdrxRepl:new(); REPL:repl()
--
-- To exit the REPL set REPL.stop to true.
-- The code is run by the method :evalprint().
--
--
-- NOTE ON THE PREFIX '=':
-- =======================
-- The manpages of lua5.1 and lua5.2 explain how the Lua REPL treats
-- the prefix "=" in this way:
-- 
--   If a line starts with '=', then lua displays the values of all
--   the expressions in the remainder of the line. The expressions
--   must be separated by commas.
-- 
-- In Lua5.3 they changed that to this (also copied from the manpage):
-- 
--   If the line contains an expression or list of expressions, then
--   the line is evaluated and the results are printed.
-- 
-- The prefix "=" is still supported in Lua5.3, but is not documented.
-- The class MultiLineCmd implements a behavior similar to the one in
-- lua5.1 and lua5.2. For example, here
--
--   >>> = 22+33,
--   ...   44, 'foo bar'
--   55      44      foo bar
--
-- we have this (before the execution):
--
--   r.mlc:concat()             -->      "= 22,33,\n  44, 'foo bar'"
--   r.mlc:luacode()            --> "return 22,33,\n  44, 'foo bar'"
--   r.mlc:luacodewithprint()   -->  "print(22,33,\n  44, 'foo bar'\n)"
--
-- The method :luacode() in the class MultiLineCmd is used to check if
-- the input is complete, and the method :luacodewithprint() is used
-- to produce the code that is executed by the xpcall in the method
-- :evalprint() of EdrxRepl. It should be easy to add support for
-- other prefixes - we just need to change :luacode() and
-- :luacodewithprint().
--
-- See for example this thread:
-- http://lua-users.org/lists/lua-l/2020-10/msg00209.html




-- See: (find-angg "emacs-lua/EdrxRepl.lua" "EdrxRepl")
--      (find-angg "emacs-lua/EdrxRepl.lua" "EdrxRepl-emacs")
--
EdrxRepl = Class {
  type         = "EdrxRepl",
  new          = function () return EdrxRepl({}) end,
  __index = {
    read00 = function (r, prompt) write(prompt); return io.read() end,
    read0 = function (r, prompt) return r:read00(prompt) end,
    read1 = function (r) return r:read0 ">>> " end,
    read2 = function (r) return r:read0 "... " end,
    read = function (r)
        r.mlc = MultiLineCmd.new(r:read1())
        while r.mlc:incomplete() do r.mlc:add(r:read2()) end
        return r
      end,
    --
    trapcomperror = function (r) return r.mlc:status() == "comp error" end,
    printcomperror = function (r) print(r.mlc.err) end,
    --
    evalprint = function (r)
        xpcall(r.mlc.f, ErrHandler.default)
      end,
    readevalprint = function (r)
        r:read()
        if r:trapcomperror()
        then r:printcomperror()
	else r:evalprint()
        end
      end,
    repl = function (r)
        while not r.STOP do
          r:readevalprint()
        end
      end,
  },
}

-- «EdrxRepl-tests»  (to ".EdrxRepl-tests")
--[[
 (eepitch-lua51)
 (eepitch-kill)
 (eepitch-lua51)
dofile "Repl1.lua"
r = EdrxRepl.new()
r:repl()
print(2
  +3
  !
print(2
  +3
  )
print(2+3+nil)  -- err
= 22 + 33, 44
r.STOP = "please"

--]]




--  _____    _           _____                          ____            _ 
-- | ____|__| |_ ____  _| ____|_ __ ___   __ _  ___ ___|  _ \ ___ _ __ | |
-- |  _| / _` | '__\ \/ /  _| | '_ ` _ \ / _` |/ __/ __| |_) / _ \ '_ \| |
-- | |__| (_| | |   >  <| |___| | | | | | (_| | (__\__ \  _ <  __/ |_) | |
-- |_____\__,_|_|  /_/\_\_____|_| |_| |_|\__,_|\___|___/_| \_\___| .__/|_|
--                                                               |_|      
-- «EdrxEmacsRepl»  (to ".EdrxEmacsRepl")
-- This is a variant of EdrxRepl that is intended to be used inside
-- emacs-lua. To test it in pure Lua, do this:
--
--   r = EdrxEmacsRepl.new()
--   r:testemacsrepl()
--
-- Note that when we run r:esend(line) this adds "line" to the
-- multiline command in r.mlc, and it captures all the outputs of
-- compiling and executing the current multiline command and returns
-- them as a string. The outputs that are error messages are trivial
-- to capture, but the outputs of executing the command are captured
-- with an WithFakePrint.run(...) around an xpcall. The class
-- WithFakePrint is defined near the top of this file.
--
-- The "outputs of r:esend(line)" do not include the next prompt.
--
EdrxEmacsRepl = Class {
  type = "EdrxEmacsRepl",
  new  = function () return EdrxEmacsRepl({}) end,
  __index = {
    --
    eempty  = function (r) return r.mlc == nil end,
    eprompt = function (r) return r:eempty() and ">>> " or "... " end,
    eincomplete = function (r) return r.mlc:status() == "incomplete" end,
    ecomperror  = function (r) return r.mlc:status() == "comp error" end,
    ecomplete   = function (r) return r.mlc:status() == "complete"   end,
    eaddfirstline   = function (r, line) r.mlc = MultiLineCmd.new(line) end,
    eaddanotherline = function (r, line) r.mlc:add(line) end,
    --
    eretcomperror = function (r)
        local err = r.mlc.err
        r.mlc = nil
        return err
      end,
    eevalprint  = function (r)
        return WithFakePrint.run(function ()
            xpcall(r.mlc.f, ErrHandler.default)
          end)
      end,
    eretevalprint = function (r)
        local out = r:eevalprint()
        r.mlc = nil
        return out
      end,
    --
    esend = function (r, line)
        if r:eempty()
	then r:eaddfirstline(line)
	else r:eaddanotherline(line)
	end
        if     r:eincomplete() then return ""
        elseif r:ecomperror()  then return r:eretcomperror().."\n"
        else                        return r:eretevalprint()
        end
      end,
    --
    testemacsrepl = function (r)
        while not r.STOP do
          write(r:eprompt())
	  local line = io.read()
          write(r:esend(line))
        end      
      end,
  },
}

-- «EdrxEmacsRepl-tests»  (to ".EdrxEmacsRepl-tests")
--[[
 (eepitch-lua51)
 (eepitch-kill)
 (eepitch-lua51)
dofile "Repl1.lua"
r = EdrxEmacsRepl.new()
r:testemacsrepl()
  print(2, 3)
  print(2,
    3)
= 2, 3
= 2,
  3
= 2,
  !!
= 2 + nil

ErrHandler.deltop = 0
ErrHandler.delbot = 0
= 2 + nil

ErrHandler.deltop = 10
ErrHandler.delbot = 6
= 2 + nil

F02 = function (a) return 1 + F01(a) end
F01 = function (a) return 1 + F00(a) end
F00 = function (a) return expr(a) end
F02("error 'foo'")

dgis0 = dgis
= dgis0
= dgis0:tb()
= dgis0:tb(#dgis0 - 10, 7)

r.STOP = "yes"

--]]








-- Local Variables:
-- coding:  utf-8-unix
-- End:
