"""
PLAYER_ACTIONS = Dict([
    :ConstructSettlement    => act_construct_settlement,
    :ConstructCity          => act_construct_city,
    :ConstructRoad          => act_construct_road,
    :ProposeTrade           => act_propose_trade_goods,
    :BuyDevCard             => act_buy_devcard,
    :PlayDevCard            => act_play_devcard
   ])


ACTIONS_DICTIONARY = Dict(
    :ConstructCity => construct_city,
    :ConstructRoad => construct_road,
    :ConstructSettlement => construct_settlement
   )
"""
function construct_road(board, player::Player, coord1, coord2)
    PlayerApi.pay_construction(player, :Road)
    BoardApi.build_road!(board, player.team, coord1, coord2)
end

function construct_city(board, player::Player, coord)
    PlayerApi.pay_construction(player, :City)
    BoardApi.build_city!(board, player.team, coord)
end
function construct_settlement(board, player::Player, coord)
    PlayerApi.pay_construction(player, :Settlement)
    check_add_port(board, player, coord)
    BoardApi.build_settlement!(board, player.team, coord)
end
function check_add_port(board::Board, player::Player, coord)
    if haskey(board.coord_to_port, coord)
        PlayerApi.add_port!(player, board.coord_to_port[coord])
    end
end
