-module(fooesc).

%% API exports
-export([main/1]).

%%====================================================================
%% API functions
%%====================================================================

%% escript Entry point
main(Args) ->
    io:format("Args: ~p~n", [Args]),
    load_nifs(),
    %{ok, _} = esqlite3:open("foo.db"),
    erlang:halt(0).

%%====================================================================
%% Internal functions
%%====================================================================
%%
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
