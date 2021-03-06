%% kilian_ring.erl - Send a bunch of messages through a chain of processes
%% Program written from scratch to implement an idea from someone going by
%% the nickname of "kilian_" on #erlang and presenting
%%   http://paste.lisp.org/display/82236
%% as his solution.
%%
%% Run this program as follows:
%%   $ erl -noshell -s kilian_ring test -s init stop
%%   $ erl -noshell -s kilian_ring test 13 -s init stop
%%   $ erl -noshell -s kilian_ring test 5000 -s init stop > log.txt


-module(kilian_ring).


-export([test/0, test/1]).
-export([loop/2]).


loop(none, Number) -> % receiver process
    receive
        {message, Sender, Content} ->
            io:format("Process ~w/~w: Received message ~w~n",
                      [Number, self(), Content]),
            Sender ! {ack, Content},
            loop(none, Number);
        {stop, Sender} ->
            io:format("Process ~w/~w: stopping.~n",
                      [Number, self()]),
            Sender ! {ack, stop}
    end;
loop(Next, Number) -> % forwarder process
    receive
        {message, _Sender, Content} = Msg ->
            io:format("Process ~w/~w: forwarding message to Pid ~w: ~w~n",
                      [Number, self(), Next, Content]),
            Next ! Msg,
            loop(Next, Number);
        {stop, _Sender} = Msg ->
            io:format("Process ~w/~w: stopping (forwarding to Pid ~w)~n",
                      [Number, self(), Next]),
            Next ! Msg
    end.


receive_acks(_Timeout, []) ->
    ok;
receive_acks(Timeout, [Head|Tail]) ->
    receive
        {ack, Head} -> receive_acks(Timeout, Tail)
        after Timeout  -> timeout
    end.


receive_acks(Messages) ->
    receive_acks(1000, Messages).


spawn_chain(Number, Next) when Number > 0 ->
    Pid = spawn(?MODULE, loop, [Next,Number]),
    spawn_chain(Number-1, Pid);
spawn_chain(0, Next) ->
    Next.


spawn_chain(Number) ->
    spawn_chain(Number, none).



test_chain(Number) ->
    %% Set up chain of processes
    First = spawn_chain(Number),
    io:format("First: ~p~n", [First]),

    %% Send a few messages through the chain
    RawMessages = ['moo', ['foo', 'bar'], "blah", {42,23}, 'that\'s it!'],
    {Messages, _} = lists:mapfoldl(fun(X, Count) -> {{Count, X}, Count+1} end,
                                   1, RawMessages),
    [ First ! {message, self(), M} || M <- Messages ],
    case receive_acks(Messages) of
        ok -> io:format("All messages have crossed the process chain.~n", []);
        timeout -> io:format("Timeout waiting for all messages to cross process chain.~n", [])
    end,

    %% Send a stop message to chain
    First ! {stop, self()},
    case receive_acks(5000, [stop]) of
        ok -> io:format("The process chain has been torn down.~n", []);
        timeout -> io:format("The process chain teardown has timed out.~n", [])
    end.


test() ->
    test([]).


test([]) ->
    test([5]);
test([NumAtom]) when is_atom(NumAtom) ->
    test([atom_to_list(NumAtom)]);
test([NumStr]) when is_list(NumStr) ->
    test([list_to_integer(NumStr)]);
test([Number]) when is_integer(Number) ->
    test_chain(Number).

