.PHONY: all
all:
	$(MAKE) foorel
	- $(MAKE) fooesc1
	$(MAKE) fooesc2

.PHONY: foorel
foorel:
	# -----------------------------------------------------------------
	# foorel : app succeeds
	# -----------------------------------------------------------------
	cd foorel && rebar3 do clean release
	cd foorel && _build/default/rel/foorel/bin/foorel start
	if [ ! -e "./foorel/foo.db" ]; then echo "FAILED: DB MISSING" && exit 1; else echo "SUCCEEDED: DB FOUND"; fi
	-cd foorel && _build/default/rel/foorel/bin/foorel stop


.PHONY: fooesc1
fooesc1:
	# -----------------------------------------------------------------
	# fooesc1 : escript fails, cannot find nif
	# -----------------------------------------------------------------
	cd fooesc && rebar3 clean escriptize	
	cd fooesc && _build/default/bin/fooesc


.PHONY: fooesc2
fooesc2:
	# -----------------------------------------------------------------
	# fooesc2 : copy nif escript next to escript bin
	# -----------------------------------------------------------------
	cd fooesc && rebar3 clean escriptize	
	cp fooesc/_build/default/lib/esqlite/priv/esqlite3_nif.so fooesc/_build/default/bin/esqlite3_nif.so
	cd fooesc && _build/default/bin/fooesc
