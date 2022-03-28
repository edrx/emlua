# This file:
#   http://angg.twu.net/emlua/Makefile.html
#   http://angg.twu.net/emlua/Makefile
#           (find-angg "emlua/Makefile")
# https://raw.githubusercontent.com/edrx/emlua/main/Makefile
#           https://github.com/edrx/emlua/blob/main/Makefile
# Author: Phil Hagelberg (aka technomancy).
# Version: 2022mar26
# License: GPL2
#
# See: https://github.com/edrx/emlua

EMACS_DIR       ?= "$(HOME)/src/emacs"
LUA_INCLUDE_DIR ?= /usr/include/lua5.3
LUA_LIB         ?= lua5.3

emlua.so:
	g++ -std=c++11 -I$(EMACS_DIR)/src -I$(LUA_INCLUDE_DIR) -shared emlua.cpp -o $@ -l$(LUA_LIB)

clean:
	rm -fv emlua.so

.PHONY: clean
