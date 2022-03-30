// This file:
//   http://angg.twu.net/emlua/emlua.cpp.html
//   http://angg.twu.net/emlua/emlua.cpp
//           (find-angg "emlua/emlua.cpp")
// https://raw.githubusercontent.com/edrx/emlua/main/emlua.cpp
//           https://github.com/edrx/emlua/blob/main/emlua.cpp
// Authors: <nerditation@outlook.com> (part in C++),
//          <eduardoochs@gmail.com> (all the rest).
// See: http://lua-users.org/lists/lua-l/2021-03/msg00084.html
//      https://lists.gnu.org/archive/html/emacs-devel/2021-04/msg00907.html
// Version: 2022mar30
// License: GPL2
//
// See: <https://github.com/edrx/emlua>.
//
// TODO: at this moment this module needs to be loaded with (load ...) -
// running (require 'emlua) won't work. This is because this file
// lacks something like the call to "provide" here,
//
//   https://github.com/akermu/emacs-libvterm/blob/master/vterm-module.c#L1514
//
// that would work like a (provide 'emlua), but written in C.
//
//
// «.tests-in-tmp»	(to "tests-in-tmp")
// «.tests-edrx»	(to "tests-edrx")



#include <vector>
#include <emacs-module.h>
#include <lua.hpp>

int plugin_is_GPL_compatible;

// TODO: convert lua values to elisp values in a meaningful way.
// PLACEHOLDER: call `luaL_tolstring` on everything
static emacs_value lua_to_elisp(lua_State *L, emacs_env *env, int i) {
	size_t size;
	auto s = luaL_tolstring(L, i, &size);
	return env->make_string(env, s, size);
}

#define EMACS_ENV_KEY "*emacs_env"

// ef_xxx is elisp function so uses emacs-module-func protocol
// basically a wrapper around the Lua `dostring` function
// returns a vector containing the multiple (possibly zero) return values (called `tostring` on them) of the Lua code
// returns an error message on failure
static emacs_value ef_lua_dostring(emacs_env *env, ptrdiff_t nargs, emacs_value *args, void *data) noexcept {
	// closure data is lua_State
	lua_State *L = (lua_State *)data;
	// the env is valid on for this callstack
	lua_pushlightuserdata(L, env);
	lua_setfield(L, LUA_REGISTRYINDEX, EMACS_ENV_KEY);
	// string length: emacs uses signed type (ptrdiff_t), Lua uses unsigned type (size_t)
	ptrdiff_t len = 0;
	// emacs didn't provide API to `borrow` the string
	// we are forced to make a copy and then Lua will copy it again
	env->copy_string_contents(env, args[0], nullptr, &len);
	auto buffer = std::vector<char>(len);
	env->copy_string_contents(env, args[0], buffer.data(), &len);
	//assert(buffer.back() == '\0');
	auto status = luaL_dostring(L, buffer.data());
	if (status != LUA_OK) {
		auto ret = lua_to_elisp(L, env, -1);
		lua_settop(L, 0);
		return ret;
	}
	auto multret = std::vector<emacs_value>{};
	int retcount = lua_gettop(L);
	multret.reserve(retcount);
	for (int i = 1; i <= retcount; ++i) {
		multret.push_back(lua_to_elisp(L, env, i));
	}
	lua_settop(L, 0);
	return env->funcall(env, env->intern(env, "vector"), multret.size(), multret.data());
}

// lf_xxx is lua function so use lua_CFunction protocol
static int lf_message(lua_State *L)
{
	lua_getfield(L, LUA_REGISTRYINDEX, EMACS_ENV_KEY);
	auto *env = (emacs_env *)lua_touserdata(L, -1);
	size_t size;
	auto s = luaL_tolstring(L, 1, &size);
	emacs_value args[1] = {env->make_string(env, s, size)};
	env->funcall(env, env->intern(env, "message"), 1, args);
	return 0;
};

extern "C" {
int emacs_module_init(struct emacs_runtime *ert) noexcept
{
	emacs_env *env = ert->get_environment(ert);
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	// register Lua callable function(s)
	lua_pushcfunction(L, lf_message);
	lua_setglobal(L, "message");
	// register elisp callable function(s)
	emacs_value func = env->make_function(
			env,
			1, // min_arity,
			1, // max_arity,
			&ef_lua_dostring,
			"Run ARG1 - a string - as Lua code.",
			L
			);
	emacs_value symbol = env->intern(env, "emlua-dostring");
	emacs_value args[] = {symbol, func};
	env->funcall(env, env->intern(env, "defalias"), 2, args);

	// The next three lines were suggested by bpalmer
	env->intern(env, "emlua");
	emacs_value provide_args[] = {symbol};
	env->funcall(env, env->intern(env, "provide"), 1, provide_args);

	return 0;
}
} // extern "C"




// «tests-in-tmp»  (to ".tests-in-tmp")
// Download a copy of emlua into /tmp/emlua/
// and run some tests there.
/*
 (eepitch-shell)
 (eepitch-kill)
 (eepitch-shell)
rm -Rfv /tmp/emlua/
mkdir   /tmp/emlua/
cd      /tmp/emlua/
git clone https://github.com/edrx/emlua .
make clean
make
make EMACS_DIR=$HOME/usrc/emacs29

# (load "/tmp/emlua/emlua.so")
# (emlua-dostring "a = a and a+1 or 0; return 22+33, '44', {}, a, nil")
# (emlua-dostring "err")

*/


// «tests-edrx»  (to ".tests-edrx")
// Tests that only work in the author's machine.
/*
# (find-fline "/tmp/emlua/")
# (find-fline "~/emlua/")

 (eepitch-shell)
 (eepitch-kill)
 (eepitch-shell)
cd ~/emlua/
make clean
make EMACS_DIR=$HOME/usrc/emacs29

# (add-to-list 'load-path "~/emlua/")
# (require 'emlua)

# Or:
# (load (ee-expand "~/emlua/emlua.so"))

# (emlua-dostring "a = a and a+1 or 0; return 22+33, '44', {}, a, nil")
# (emlua-dostring "err")

*/




// Local Variables:
// coding:  utf-8-unix
// End:

