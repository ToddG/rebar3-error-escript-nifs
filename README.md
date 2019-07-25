# rebar3-error-escript-nifs

Repo to help understand how rebar3, escripts and nifs play with each other.

## REPRO 1

### Command

```bash
$ make
```

### Output

```bash
# app succeeds
cd foorel && rebar3 do release
===> Verifying dependencies...
===> Compiling foorel
===> Starting relx build process ...
===> Resolving OTP Applications from directories:
          /home/toddg/temp/rebar3-error-escript-nifs/foorel/_build/default/lib
          /home/toddg/temp/rebar3-error-escript-nifs/foorel/apps
          /home/toddg/.asdf/installs/erlang/22.0.7/lib
          /home/toddg/temp/rebar3-error-escript-nifs/foorel/_build/default/rel
===> Resolved foorel-0.1.0
===> Dev mode enabled, release will be symlinked
===> release successfully created!
cd foorel && _build/default/rel/foorel/bin/foorel start
if [ ! -e "./foorel/foo.db" ]; then echo "FAILED: DB MISSING" && exit 1; else echo "SUCCEEDED: DB FOUND"; fi
SUCCEEDED: DB FOUND
# escript fails
cd fooesc && rebar3 escriptize
===> Verifying dependencies...
===> Compiling fooesc
===> Building escript...
cd fooesc && _build/default/bin/fooesc
Args: []
=WARNING REPORT==== 25-Jul-2019::07:02:46.839588 ===
The on_load function for module esqlite3_nif returned:
{{badmatch,{error,{load_failed,"Failed to load NIF library: '/home/toddg/temp/rebar3-error-escript-nifs/fooesc/_build/default/bin/fooesc/esqlite/priv/esqlite3_nif.so: cannot open shared object file: Not a directory'"}}},
 [{esqlite3_nif,init,0,[{file,...},{...}]},
  {code_server,'-handle_on_load/5-fun-0-',1,[{...}|...]}]}

=ERROR REPORT==== 25-Jul-2019::07:02:46.838795 ===
Error in process <0.76.0> with exit value:
{{badmatch,{error,{load_failed,"Failed to load NIF library: '/home/toddg/temp/rebar3-error-escript-nifs/fooesc/_build/default/bin/fooesc/esqlite/priv/esqlite3_nif.so: cannot open shared object file: Not a directory'"}}},
 [{esqlite3_nif,init,0,
                [{file,"/home/toddg/temp/fooesc/_build/default/lib/esqlite/src/esqlite3_nif.erl"},
                 {line,49}]},
  {code_server,'-handle_on_load/5-fun-0-',1,
               [{file,"code_server.erl"},{line,1340}]}]}

escript: exception error: undefined function esqlite3_nif:start/0
  in function  esqlite3:open/2 (/home/toddg/temp/fooesc/_build/default/lib/esqlite/src/esqlite3.erl, line 65)
  in call from fooesc:main/1 (/home/toddg/temp/rebar3-error-escript-nifs/fooesc/src/fooesc.erl, line 13)
  in call from escript:run/2 (escript.erl, line 758)
  in call from escript:start/1 (escript.erl, line 277)
  in call from init:start_em/1
  in call from init:do_boot/3
Makefile:3: recipe for target 'all' failed
make: *** [all] Error 127
```

### Where are the .so files?

```bash
~/temp/rebar3-error-escript-nifs $ find . | grep \.so$
./foorel/_build/default/lib/esqlite/priv/esqlite3_nif.so
./fooesc/_build/default/lib/esqlite/priv/esqlite3_nif.so
```

### So what's the problem?

The escript is looking for the nif here:

```_build/default/bin/fooesc/esqlite/priv/esqlite3_nif.so```

...but it's actually here:

```
_build/default/lib/esqlite/priv/esqlite3_nif.so
```

```erlang
{{badmatch,{error,{load_failed,"Failed to load NIF library: '/home/toddg/temp/rebar3-error-escript-nifs/fooesc/_build/default/bin/fooesc/esqlite/priv/esqlite3_nif.so: cannot open shared object file: Not a directory'"}}},
```

### This seems to have been discovered back in 2016


https://stackoverflow.com/questions/15617798/erlang-rebar-escriptize-nifs#15685971

```text
erlang rebar escriptize & nifs
Ask Question
Asked 6 years, 4 months ago
Active 1 year, 7 months ago
Viewed 2k times
```

## REPRO 2

I thought I'd try `rvirding`'s solution in this branch to see if I could recommend a generalized work-around... didn't work.

But here is the run output showing that the module on_load function happens before the escript code is invoked.

### Code

_fooesc.erl_
```erlang
%% nif has been built here: _build/default/lib/esqlite/priv/esqlite3_nif.so
%% escript bulit here: _build/default/bin/fooesc
%% copied nif to _build/default/bin/esqlite3_nif.so
%% did not set NIF_DIR so defaults to "."
load_nifs() ->
    Path = case os:getenv("NIF_DIR") of
        false -> file:get_cwd();
        Dir -> Dir
    end,
    Nif = Path ++ "/esqlite3_nif",
    io:format("loading nif: ~p~n", [Nif]),
    ok = erlang:load_nif(Nif, 0),
    io:format("loaded nif: ~p~n", [Nif]).
```

### Output

```bash
$ make
make foorel
make[1]: Entering directory '/home/toddg/temp/rebar3-error-escript-nifs'
# -----------------------------------------------------------------
# foorel : app succeeds
# -----------------------------------------------------------------
cd foorel && rebar3 do clean release
===> Verifying dependencies...
===> Cleaning out foorel...
cd foorel && _build/default/rel/foorel/bin/foorel start
if [ ! -e "./foorel/foo.db" ]; then echo "FAILED: DB MISSING" && exit 1; else echo "SUCCEEDED: DB FOUND"; fi
SUCCEEDED: DB FOUND
cd foorel && _build/default/rel/foorel/bin/foorel stop
Makefile:9: recipe for target 'foorel' failed
make[1]: [foorel] Error 1 (ignored)
make[1]: Leaving directory '/home/toddg/temp/rebar3-error-escript-nifs'
make fooesc1
make[1]: Entering directory '/home/toddg/temp/rebar3-error-escript-nifs'
# -----------------------------------------------------------------
# fooesc1 : escript fails, cannot find nif
# -----------------------------------------------------------------
cd fooesc && rebar3 clean escriptize
===> Verifying dependencies...
===> Cleaning out fooesc...
cd fooesc && _build/default/bin/fooesc
Args: []
=WARNING REPORT==== 25-Jul-2019::09:17:45.954869 ===
The on_load function for module esqlite3_nif returned:
{{badmatch,{error,{load_failed,"Failed to load NIF library: '/home/toddg/temp/rebar3-error-escript-nifs/fooesc/_build/default/bin/fooesc/esqlite/priv/esqlite3_nif.so: cannot open shared object file: Not a directory'"}}},
 [{esqlite3_nif,init,0,[{file,...},{...}]},
  {code_server,'-handle_on_load/5-fun-0-',1,[{...}|...]}]}

=ERROR REPORT==== 25-Jul-2019::09:17:45.953962 ===
Error in process <0.76.0> with exit value:
{{badmatch,{error,{load_failed,"Failed to load NIF library: '/home/toddg/temp/rebar3-error-escript-nifs/fooesc/_build/default/bin/fooesc/esqlite/priv/esqlite3_nif.so: cannot open shared object file: Not a directory'"}}},
 [{esqlite3_nif,init,0,
                [{file,"/home/toddg/temp/fooesc/_build/default/lib/esqlite/src/esqlite3_nif.erl"},
                 {line,49}]},
  {code_server,'-handle_on_load/5-fun-0-',1,
               [{file,"code_server.erl"},{line,1340}]}]}

escript: exception error: undefined function esqlite3_nif:start/0
  in function  esqlite3:open/2 (/home/toddg/temp/fooesc/_build/default/lib/esqlite/src/esqlite3.erl, line 65)
  in call from fooesc:main/1 (/home/toddg/temp/rebar3-error-escript-nifs/fooesc/src/fooesc.erl, line 13)
  in call from escript:run/2 (escript.erl, line 758)
  in call from escript:start/1 (escript.erl, line 277)
  in call from init:start_em/1
  in call from init:do_boot/3
Makefile:20: recipe for target 'fooesc1' failed
make[1]: *** [fooesc1] Error 127
make[1]: Leaving directory '/home/toddg/temp/rebar3-error-escript-nifs'
Makefile:3: recipe for target 'all' failed
make: [all] Error 2 (ignored)
make fooesc2
make[1]: Entering directory '/home/toddg/temp/rebar3-error-escript-nifs'
# -----------------------------------------------------------------
# fooesc2 : copy nif escript next to escript bin
# -----------------------------------------------------------------
cd fooesc && rebar3 clean escriptize
===> Verifying dependencies...
===> Cleaning out fooesc...
cp fooesc/_build/default/lib/esqlite/priv/esqlite3_nif.so fooesc/_build/default/bin/esqlite3_nif.so
cd fooesc && _build/default/bin/fooesc
Args: []
=ERROR REPORT==== 25-Jul-2019::09:17:47.940867 ===
Error in process <0.76.0> with exit value:
{{badmatch,{error,{load_failed,"Failed to load NIF library: '/home/toddg/temp/rebar3-error-escript-nifs/fooesc/_build/default/bin/fooesc/esqlite/priv/esqlite3_nif.so: cannot open shared object file: Not a directory'"}}},
 [{esqlite3_nif,init,0,
                [{file,"/home/toddg/temp/fooesc/_build/default/lib/esqlite/src/esqlite3_nif.erl"},
                 {line,49}]},
  {code_server,'-handle_on_load/5-fun-0-',1,
               [{file,"code_server.erl"},{line,1340}]}]}

=WARNING REPORT==== 25-Jul-2019::09:17:47.941605 ===
The on_load function for module esqlite3_nif returned:
{{badmatch,{error,{load_failed,"Failed to load NIF library: '/home/toddg/temp/rebar3-error-escript-nifs/fooesc/_build/default/bin/fooesc/esqlite/priv/esqlite3_nif.so: cannot open shared object file: Not a directory'"}}},
 [{esqlite3_nif,init,0,[{file,...},{...}]},
  {code_server,'-handle_on_load/5-fun-0-',1,[{...}|...]}]}

escript: exception error: undefined function esqlite3_nif:start/0
  in function  esqlite3:open/2 (/home/toddg/temp/fooesc/_build/default/lib/esqlite/src/esqlite3.erl, line 65)
  in call from fooesc:main/1 (/home/toddg/temp/rebar3-error-escript-nifs/fooesc/src/fooesc.erl, line 13)
  in call from escript:run/2 (escript.erl, line 758)
  in call from escript:start/1 (escript.erl, line 277)
  in call from init:start_em/1
  in call from init:do_boot/3
Makefile:29: recipe for target 'fooesc2' failed
make[1]: *** [fooesc2] Error 127
make[1]: Leaving directory '/home/toddg/temp/rebar3-error-escript-nifs'
Makefile:3: recipe for target 'all' failed
make: *** [all] Error 2

```
