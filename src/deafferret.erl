-module(deafferret).

-export([start/0]).
-export([mutate/1, mutate/2]).
-export([m/1, m/2]).


%% Mute version
m([], _Dict, _Prefix, Acc) ->
    lists:reverse(Acc);
m([Base|Suffix]=OrigSequence, Dict, Prefix, Acc) ->
    m(Suffix, Dict, [Base|Prefix],
      lists:foldl(fun(El,Ac) -> [El|Ac] end, Acc,
		  [Prefix++[X|Suffix] || X<-Dict, X=/=Base])).

m(OrigSequence, Dict) ->
    m(OrigSequence, Dict, "", []).

m(OrigSequence) ->
    m(OrigSequence, "ACGT").


%% Verbose version
mutate([], _Dict, _Prefix, Acc) ->
    lists:reverse(Acc);
mutate([Base|Suffix]=G, Dict, Prefix, Acc) ->
    io:format("mutate(~p,~p,~p,~p)~n", [G,Dict,Prefix,Acc]),
    NewMutations = [Prefix++[X|Suffix] || X<-Dict, X=/=Base],
    io:format("  new: ~p~n", [NewMutations]),
    mutate(Suffix, Dict, [Base|Prefix],
	   lists:foldl(fun(El,Ac) -> [El|Ac] end, Acc, NewMutations)).

mutate(OrigSequence, Dict) ->
    mutate(OrigSequence, Dict, "", []).

mutate(OrigSequence) ->
    mutate(OrigSequence, "ACGT").


%% Run example.
example(OrigSequence) ->
    Dict = "ACGT",
    Mutations = mutate(OrigSequence, Dict),
    io:format("Mutations of ~p for base ~p:~n  ~p~n", [OrigSequence, Dict, Mutations]).

start() ->
    [ example(X) || X <- ["CATTAG", "AAAA"] ].
