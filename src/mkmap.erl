-module(mkmap).

-export([new/0,put/3,add_key/3,del_key/2,get/2,get/3,get_keys/2,get_all_keys/1]).
-export([fold/3]).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

-record(mkmap,
        {
         valmap=#{},
         keymap=#{}
        }).

new() ->
    #mkmap{}.

put(Key, Value, Map) -> 
    MM=case maps:is_key(Key,Map#mkmap.keymap) of
           false ->
               erlang:unique_integer([positive]);
           true ->
               maps:get(Key,Map#mkmap.keymap)
       end,
    Map#mkmap{
      keymap=maps:put(Key,MM,Map#mkmap.keymap),
      valmap=maps:put(MM,Value,Map#mkmap.valmap)
     }.

get(Key, Map) ->
    MM=maps:get(Key, Map#mkmap.keymap),
    maps:get(MM, Map#mkmap.valmap).

get(Key, Map, Default) ->
    case maps:is_key(Key, Map#mkmap.keymap) of
        true ->
            MM=maps:get(Key, Map#mkmap.keymap),
            maps:get(MM, Map#mkmap.valmap);
        false ->
            Default
    end.

add_key(Key1, Key2, Map) ->
    MM=maps:get(Key1,Map#mkmap.keymap),
    Map#mkmap{
      keymap=maps:put(Key2,MM,Map#mkmap.keymap)
     }.

get_all_keys(Map) ->
    KM=Map#mkmap.keymap,
    maps:values(
      maps:fold(
        fun(K,V,A) ->
                maps:put(V,[K|maps:get(V,A,[])],A)
        end, #{}, KM)
     ).

get_keys(Key1, Map) ->
    KM=Map#mkmap.keymap,
    case maps:is_key(Key1, KM) of 
        false ->
            [];
        true ->
            MM=maps:get(Key1,KM),
            maps:fold(
              fun(K,V,A) when V==MM ->
                      [K|A];
                 (_,_,A) -> 
                      A
              end, [], KM)
    end.


del_key(Key1, Map) ->
    MM=maps:get(Key1,Map#mkmap.keymap),
    MR=maps:remove(Key1,Map#mkmap.keymap),
    Rest=maps:values(MR),
    case lists:member(MM,Rest) of
        true ->
            Map#mkmap{
              keymap=MR
             };
        false ->
            Map#mkmap{
              keymap=MR,
              valmap=maps:remove(MM,Map#mkmap.valmap)
             }
    end.

fold(Fun,State0,Map) ->
    KM=Map#mkmap.keymap,
    KV=Map#mkmap.valmap,
    maps:fold(
      fun(Id,Keys,Acc) ->
              Value=maps:get(Id,KV),
              Fun(Keys,Value,Acc)
      end, State0, 
      maps:fold(
        fun(K,V,A) ->
                maps:put(V,[K|maps:get(V,A,[])],A)
        end, #{}, KM)
     ).

-ifdef(TEST).
mkmap_test() ->
    M1=new(),
    M2=put(k1,val1,M1),
    M3=add_key(k1,k2,M2),
    ?assertEqual(val1, get(k1,M3)),
    ?assertEqual(val1, get(k2,M3)),
    ?assertEqual(undef, get(k3,M3,undef)),
    ?assertError({badkey,k3}, get(k3,M3)),
    ?assertEqual(lists:sort([k1,k2]), lists:sort(get_keys(k1,M3))),
    M4=del_key(k1,M3),
    ?assertEqual(lists:sort([k2]), lists:sort(get_keys(k2,M4))),
    ?assertEqual(lists:sort([]), lists:sort(get_keys(k3,M4))),
    M5=del_key(k2,M4),
    ?assertEqual(#mkmap{}, M5),
    ?assertEqual([[k2,k1]], get_all_keys(M3)),
    ok.
-endif.

