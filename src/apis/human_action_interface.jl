macro safeact(ex)
    quote
        try
            $(esc(ex))
        catch e
            if e isa InterruptException
                throw(e)
            else
                throw(e)
                # @warn "Action failed: $e"
            end
        end
    end
end

act_construct_settlement(game::Game, board::Board, player::PlayerType, coords::Union{Vector, Nothing}, trade_amount_flag::Int = 0, resources::Union{Vector, Nothing} = nothing, card = nothing) = construct_settlement(board, player.player, coords[1])
act_construct_city(game::Game, board::Board, player::PlayerType, coords::Union{Vector, Nothing}, trade_amount_flag::Int = 0, resources::Union{Vector, Nothing} = nothing, card = nothing) = @safeact construct_city(board, player.player, coords[1])
act_construct_road(game::Game, board::Board, player::PlayerType, coords::Union{Vector, Nothing}, trade_amount_flag::Int = 0, resources::Union{Vector, Nothing} = nothing, card = nothing) = @safeact construct_road(board, player.player, coords...)
act_propose_trade_goods(game::Game, board::Board, player::PlayerType, coords::Union{Vector, Nothing}, trade_amount_flag::Int, resources::Union{Vector, Nothing}, card = nothing) = @safeact propose_trade_goods(board, game.players, player, trade_amount_flag, resources...)
act_draw_devcard(game::Game, board::Board, player::PlayerType, coords::Union{Vector, Nothing}, trade_amount_flag::Int = 0, resources::Union{Vector, Nothing} = nothing, card = nothing) = @safeact draw_devcard(game, board, player.player)
act_play_devcard(game::Game, board::Board, player::PlayerType, coords::Union{Vector, Nothing}, trade_amount_flag::Int = 0, resources::Union{Vector, Nothing} = nothing, card = nothing) = @safeact do_play_devcard(game, board, game.players, player, card)

PLAYER_ACTIONS = Dict([
    :ConstructSettlement    => act_construct_settlement,
    :ConstructCity          => act_construct_city,
    :ConstructRoad          => act_construct_road,
    :ProposeTrade           => act_propose_trade_goods,
    :BuyDevCard             => act_draw_devcard,
    :PlayDevCard            => act_play_devcard
   ])
