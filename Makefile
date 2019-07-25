.PHONY: all
all:
	# app succeeds
	cd foorel && rebar3 do release
	cd foorel && _build/default/rel/foorel/bin/foorel start
	cd foorel && _build/default/rel/foorel/bin/foorel stop
	if [[ ! -e "./foorel/foo.db" ]]; then exit 1; fi
	# escript fails
	cd fooesc && rebar3 escriptize	
	cd fooesc && _build/default/bin/fooesc
