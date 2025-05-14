# mutable struct DefaultRobotPlayer <: RobotPlayer
#     player::Player
# end
# 
#  Robot Player API.  Your RobotPlayer type can implement these methods.  If any are not implemented, it falls back to the existing implementation
# 
# choose_accept_trade(board::Board, player::RobotPlayer, 
#     from_player::PlayerPublicView, from_goods::Vector{Symbol}, 
#     to_goods::Vector{Symbol})::Bool
#
# choose_building_location(board::Board, players::Vector{PlayerPublicView}, 
#     player::RobotPlayer, candidates::Vector{Tuple{Int, Int}}, 
#     building_type::Symbol)::Union{Nothing,Tuple{Int,Int}}
#
# choose_one_resource_to_discard(player::RobotPlayer)::Symbol
#
# choose_monopoly_resource(board::Board, players::Vector{PlayerPublicView}, 
#     player::RobotPlayer)::Symbol
#
# choose_next_action(board::Board, players::Vector{PlayerPublicView}, 
#     player::RobotPlayer, actions::Set{Symbol})
#
# choose_place_robber(board::Board, players::Vector{PlayerPublicView}, 
#     player::RobotPlayer)::Symbol
#
# choose_road_location(board::Board, players::Vector{PlayerPublicView}, 
#     player::RobotPlayer, candidates::Vector{Vector{Tuple{Int, Int}}}
#     )::Union{Nothing,Vector{Tuple{Int, Int}}}
#
# choose_robber_victim(board::Board, player::RobotPlayer, potential_victims...
#     )::PlayerType
#
# choose_who_to_trade_with(board::Board, player::RobotPlayer, 
#     players::Vector{PlayerPublicView})::Symbol
#
# choose_year_of_plenty_resources(board, players::Vector{PlayerPublicView}, 
#     player::RobotPlayer)::Tuple{Symbol, Symbol}
#
# get_legal_action_functions(board::Board, players::Vector{PlayerPublicView}, 
#     player::RobotPlayer, actions::Set{Symbol})
#

get_admissible_devcards(player::RobotPlayer) = PlayerApi.get_admissible_devcards(player.player)

"""
    choose_accept_trade(board::Board, player::RobotPlayer, from_player::PlayerPublicView, 
    from_goods::Vector{Symbol}, to_goods::Vector{Symbol})::Bool

Decides whether `player` will accept the trade from `from_player`.  The trade is not performed within this function.
"""
function choose_accept_trade(board::Board, player::RobotPlayer, from_player::PlayerPublicView, from_goods::Vector{Symbol}, to_goods::Vector{Symbol})::Bool
    return rand() > .5
end

function roll_dice(player::RobotPlayer)::Int
    value = rand(1:6) + rand(1:6)
    @info "$(player.player.team) rolled a $value"
    return value
end

"""
    choose_road_location(board::Board, players::Vector{PlayerPublicView}, 
    player::RobotPlayer, candidates::Vector{Vector{Tuple{Int, Int}}})
    ::Vector{Tuple{Int, Int}}

`candidates` is guaranteed to be non-empty.  Given all legal road placements, 
return a `Vector` containing two coordinates signifying the road placement choice.
"""
function choose_road_location(board::Board, players::Vector{PlayerPublicView}, player::RobotPlayer, candidates::Vector{Vector{Tuple{Int, Int}}})::Vector{Tuple{Int, Int}}
    return sample(candidates)
end

"""
    choose_building_location(board::Board, players::Vector{PlayerPublicView}, 
    player::RobotPlayer, candidates::Vector{Tuple{Int, Int}}, building_type::Symbol
    )::Tuple{Int,Int}

`candidates` is guaranteed to be non-empty.  This method is only called if there is a legal placement available.
"""
function choose_building_location(board::Board, players::Vector{PlayerPublicView}, player::RobotPlayer, candidates::Vector{Tuple{Int, Int}}, building_type::Symbol)::Tuple{Int,Int}
    @debug "$(player.player.team) chooses $building_type location randomly"
    return sample(candidates, 1)[1]
end

"""
    choose_one_resource_to_discard(board::Board, player::RobotPlayer)::Symbol

Returned symbol must be present in both `Catan.RESOURCES` and `keys(player.resources)`. 
"""
function choose_one_resource_to_discard(board::Board, player::RobotPlayer)::Symbol
    isempty(player.player.resources) && throw(ArgumentError("Player has no resources"))
    return random_sample_resources(player.player.resources, 1)[1]
end

"""
    choose_place_robber(board::Board, players::Vector{PlayerPublicView}, player::RobotPlayer, 
    candidates::Vector{Symbol})::Union{Nothing, Symbol}
"""
function choose_place_robber(board::Board, players::Vector{PlayerPublicView}, player::RobotPlayer, candidates::Vector{Symbol})::Union{Nothing, Symbol}
    if length(candidates) > 0
        return sample(candidates, 1)[1]
    end
    return nothing
end

function steal_random_resource(from_player::RobotPlayer, to_player::RobotPlayer)
    stolen_good = choose_card_to_steal(from_player)
end

function choose_card_to_steal(player::RobotPlayer)::Symbol
    random_sample_resources(player.player.resources, 1)[1]
end

"""
    choose_monopoly_resource(board::Board, players::Vector{PlayerPublicView}, 
    player::RobotPlayer)::Symbol

Called during the Monopoly development card action.  Choose the resource to steal from each player based on public information.
"""
function choose_monopoly_resource(board::Board, players::Vector{PlayerPublicView}, player::RobotPlayer)::Symbol
    return get_random_resource()
end

"""
    choose_resource_to_draw(board, players::Vector{PlayerPublicView}, 
    player::RobotPlayer)::Symbol

Called two times during the Year of Plenty development card action.  TODO inconsistent naming.
"""
function choose_resource_to_draw(board, players::Vector{PlayerPublicView}, player::RobotPlayer)::Symbol
    return get_random_resource()
end

"""
    choose_robber_victim(board::Board, player::RobotPlayer, 
    potential_victims::PlayerPublicView...)::PlayerPublicView

The robber has already been placed, so here `player` decided which adjacent player to steal from.
"""
function choose_robber_victim(board::Board, player::RobotPlayer, potential_victims::PlayerPublicView...)::PlayerPublicView
    max_ind = sample(collect(potential_victims), 1)[1]
    @info "$(player.player.team) decided it is wisest to steal from the $(max_ind.team) player"
    return max_ind
end

function _choose_play_devcard(board::Board, players::Vector{PlayerPublicView}, player::RobotPlayer, devcards::Dict)::Union{Symbol,Nothing}
    if sum(values(devcards)) > 0 && (rand() > .5)
        return random_sample_resources(devcards, 1)[1]
    end
    return nothing
end

"""
    choose_next_action(board::Board, players::Vector{PlayerPublicView}, player::RobotPlayer, 
    actions::Set{PreAction})::Function

Given a `Set` of `PreAction` legal move categories, decide what will be taken as the next action.
The return `Function` needs to accept a `Game, Board, PlayerType` triple.

TODO integrate with `CatanLearning` `Action` type.  This should not be returning a function.
"""
function choose_next_action(board::Board, players::Vector{PlayerPublicView}, player::RobotPlayer, actions::Set{PreAction})::Function
    rand_action = sample(collect(actions), 1)[1]
    name = rand_action.name
    candidates = rand_action.admissible_args
    if name == :ConstructCity
        coord = choose_building_location(board, players::Vector{PlayerPublicView}, player, candidates, :City)
        return (g, b, p) -> construct_city(b, p.player, coord)
    end
    if name == :ConstructSettlement
        coord = choose_building_location(board, players::Vector{PlayerPublicView}, player, candidates, :Settlement)
        return (g, b, p) -> construct_settlement(b, p.player, coord)
    end
    if name == :ConstructRoad
        coord = choose_road_location(board, players::Vector{PlayerPublicView}, player, candidates)
        coord1 = coord[1]
        coord2 = coord[2]
        return (g, b, p) -> construct_road(b, p.player, coord1, coord2)
    end
    if name == :BuyDevCard
        return (g, b, p) -> draw_devcard(g, b, p.player)
    end
    if name == :PlayDevCard
        devcards = PlayerApi.get_admissible_devcards_with_counts(player.player)
        card = _choose_play_devcard(board, players, player, devcards)
        if card !== nothing
            return (g, b, p) -> do_play_devcard(b, g.players, p, card)
        end
    end
    if name == :ProposeTrade
        # We add an additional random filter here to avoid extremely long, uninteresting trade negotiations between DefaultRobotPlayers.
        if rand() > .8
            sampled = random_sample_resources(player.player.resources, 1)
            rand_resource_from = [sampled...]
            
            rand_resource_to = [get_random_resource()]
            while rand_resource_to[1] == rand_resource_from[1]
                rand_resource_to = [get_random_resource()]
            end
            return (g, b, p) -> propose_trade_goods(b, g.players, p, rand_resource_from, rand_resource_to)
        end
    end
    return Returns(nothing)
end

"""
    choose_who_to_trade_with(board::Board, player::RobotPlayer, 
    players::Vector{PlayerPublicView})::Symbol

Called when multiple other players have accepted a trade offer via `choose_accept_trade`, and now the trade initiator, `player`, selects which player will be selected.
"""
function choose_who_to_trade_with(board::Board, player::RobotPlayer, players::Vector{PlayerPublicView})::Symbol
    max_ind = player.player
    while max_ind.team == player.player.team
        max_ind = sample(collect(players), 1)[1]
    end
    @info "$(player.player.team) decided it is wisest to do business with $(max_ind.team) player"
    return max_ind.team
end
