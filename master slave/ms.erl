%%%-------------------------------------------------------------------
%%% @author Ayman
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. Apr 2022 6:13 AM
%%%-------------------------------------------------------------------
-module(ms).
-author("Ayman").

%% API
-export([start/1, to_slave/2, spawnSlaves/2, slave/0, masterwait/1, masterinit/1]).

start(N) ->
  SlavesList = spawnSlaves(N, []),
  io:format("Spawned Slaves ~p~n", [SlavesList]),
  spawn(ms, masterinit, [SlavesList]).

spawnSlaves(0, SlavesList) ->
  SlavesList;

spawnSlaves(N, SlavesList) ->
  New = spawn(ms, slave, []),
  spawnSlaves(N - 1, [New | SlavesList]).

masterinit(SlavesList) ->
  register(newmaster, self()),
  masterwait(SlavesList).

masterwait(SlavesList) ->
  receive
    {die, SlaveNum} ->
      lists:nth(SlaveNum, SlavesList) ! die,
      DelSlavesList=lists:delete(lists:nth(SlaveNum, SlavesList), SlavesList),
      io:format("Slaves Before Delete ~p~n", [DelSlavesList]),
      io:format("master restarting slave ~p~n", [SlaveNum]),
      New = [spawn(ms, slave, [])],
      NewSlavesList = lists:append(DelSlavesList, New),
      io:format("Slaves After Delete ~p~n", [NewSlavesList]),
      masterwait(NewSlavesList);

    {Msg, SlaveNum} ->
      lists:nth(SlaveNum, SlavesList) ! Msg,
      masterwait(SlavesList)
  end.

slave() ->
  receive
    die ->
      io:format("Slave ~p I will be dead~n", [self()]),
      dead;
    Msg ->
      io:format("Slave ~p got message ~p~n", [self(), Msg]),
      slave()
  end.

to_slave(die, SlaveNum) ->
  newmaster ! {die, SlaveNum},
  {die, SlaveNum};

to_slave(Msg, SlaveNum) ->
  newmaster ! {Msg, SlaveNum},
  {Msg, SlaveNum}.