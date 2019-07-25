# rebar3-error-escript-nifs

Repo to help understand how rebar3, escripts and nifs play with each other.

## REPRO

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

