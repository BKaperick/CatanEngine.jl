
# function action(game::Game, board::Board, player::PlayerType, coords::Union{Vector, Nothing}, trade_amount_flag::Int, resources::Union{Vector, Nothing})

act_construct_settlement(game::Game, board::Board, player::PlayerType, coords::Union{Vector, Nothing}, trade_amount_flag::Int = 0, resources::Union{Vector, Nothing} = nothing) = construct_settlement(board, player.player, coords[1])
function act_construct_city(game::Game, board::Board, player::PlayerType, coords::Union{Vector, Nothing}, trade_amount_flag::Int = 0, resources::Union{Vector, Nothing} = nothing)
    try
        construct_city(board, player.player, coords[1])
    catch e
        println("Sorry, unable to complete this action: $e")
    end
end
act_construct_road(game::Game, board::Board, player::PlayerType, coords::Union{Vector, Nothing}, trade_amount_flag::Int, resources::Union{Vector, Nothing}) = construct_road(board, player.player, coords...)
act_propose_trade_goods(game::Game, board::Board, player::PlayerType, coords::Union{Vector, Nothing}, trade_amount_flag::Int, resources::Union{Vector, Nothing}) = propose_trade_goods(board, game.players, player, trade_amount_flag, resources...)
act_buy_devcard(game::Game, board::Board, player::PlayerType, coords::Union{Vector, Nothing}, trade_amount_flag::Int, resources::Union{Vector, Nothing}) = buy_devcard(game, player.player)
act_play_devcard(game::Game, board::Board, player::PlayerType, coords::Union{Vector, Nothing}, trade_amount_flag::Int, resources::Union{Vector, Nothing}) = do_play_devcard(game, player.player)
PLAYER_ACTIONS = Dict(
    :ConstructSettlement    => act_construct_settlement,
    :ConstructCity          => act_construct_city,
    :ConstructRoad          => act_construct_road,
    :ProposeTrade           => act_propose_trade_goods,
    :BuyDevCard             => act_buy_devcard,
    :PlayDevCard            => act_play_devcard
   )
