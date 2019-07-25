.PHONY: all
all:
	# app succeeds
	cd foorel && rebar3 do release
	cd foorel && _build/default/rel/foorel/bin/foorel start
	if [ ! -e "./foorel/foo.db" ]; then echo "FAILED: DB MISSING" && exit 1; else echo "SUCCEEDED: DB FOUND"; fi
	# escript fails
	cd fooesc && rebar3 escriptize	
	cd fooesc && _build/default/bin/fooesc
	# stopping foorel down here due to timing issues
	cd foorel && _build/default/rel/foorel/bin/foorel stop
