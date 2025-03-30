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
# choose_cards_to_discard(player::RobotPlayer, amount::Int)::Vector{Symbol}
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


function choose_accept_trade(board::Board, player::RobotPlayer, from_player::PlayerPublicView, from_goods::Vector{Symbol}, to_goods::Vector{Symbol})::Bool
    return rand() > .5
end

function roll_dice(player::RobotPlayer)::Int
    value = rand(1:6) + rand(1:6)
    @info "$(player.player.team) rolled a $value"
    return value
end


function choose_road_location(board::Board, players::Vector{PlayerPublicView}, player::RobotPlayer, candidates::Vector{Vector{Tuple{Int, Int}}})::Union{Nothing,Vector{Tuple{Int, Int}}}
    if length(candidates) > 0
        return sample(candidates)
    end
    @info "I didn't find any place to put my road"
    return nothing
end
function choose_building_location(board::Board, players::Vector{PlayerPublicView}, player::RobotPlayer, candidates::Vector{Tuple{Int, Int}}, building_type::Symbol)::Union{Nothing,Tuple{Int,Int}}
    if length(candidates) > 0
        return sample(candidates, 1)[1]
    end
    return nothing
end

function choose_cards_to_discard(player::RobotPlayer, amount::Int)::Vector{Symbol}
    return random_sample_resources(player.player.resources, amount)
end

function choose_place_robber(board::Board, players::Vector{PlayerPublicView}, player::RobotPlayer)::Symbol
    validated = false
    sampled_value = nothing
    while ~validated
        sampled_value = get_random_tile(board)

        # Rules say you have to move the robber, can't leave it in place
        if sampled_value == board.robber_tile
            continue
        end
        validated = true
        neighbors = TILE_TO_COORDS[sampled_value]
        for c in neighbors
            if haskey(board.coord_to_building, c) && board.coord_to_building[c].team == player.player.team
                validated = false
            end
        end
    end
    return sampled_value
end

function steal_random_resource(from_player::RobotPlayer, to_player::RobotPlayer)
    stolen_good = choose_card_to_steal(from_player)
end

function choose_card_to_steal(player::RobotPlayer)::Symbol
    random_sample_resources(player.player.resources, 1)[1]
end

function choose_monopoly_resource(board::Board, players::Vector{PlayerPublicView}, player::RobotPlayer)::Symbol
    return get_random_resource()
end

function choose_year_of_plenty_resources(board, players::Vector{PlayerPublicView}, player::RobotPlayer)::Tuple{Symbol, Symbol}
    return get_random_resource(),get_random_resource()
end
function choose_robber_victim(board::Board, player::RobotPlayer, potential_victims...)::PlayerPublicView
    max_ind = sample(collect(potential_victims), 1)[1]
    @info "$(player.player.team) decided it is wisest to steal from the $(max_ind.team) player"
    return max_ind
end

function _choose_play_devcard(board::Board, players::Vector{PlayerPublicView}, player::RobotPlayer, devcards::Dict)::Union{Symbol,Nothing}
    if sum(values(devcards)) > 0 && (rand() > .5)
        card = random_sample_resources(devcards, 1)[1]
        if card != :VictoryPoint
            return card
        end
    end
    return nothing
end

function choose_next_action(board::Board, players::Vector{PlayerPublicView}, player::RobotPlayer, actions::Set{Symbol})::Tuple
    rand_action = sample(collect(actions), 1)
    if :ConstructCity in rand_action
        candidates = BoardApi.get_admissible_city_locations(board, player.player.team)
        coord = choose_building_location(board, players::Vector{PlayerPublicView}, player, candidates, :City)
        return (coord, (g, b, p) -> construct_city(b, p.player, coord))
    end
    if :ConstructSettlement in rand_action
        candidates = BoardApi.get_admissible_settlement_locations(board, player.player.team, false)
        coord = choose_building_location(board, players::Vector{PlayerPublicView}, player, candidates, :Settlement)
        return (coord, (g, b, p) -> construct_settlement(b, p.player, coord))
    end
    if :ConstructRoad in rand_action
        candidates = BoardApi.get_admissible_road_locations(board, player.player.team, false)
        coord = choose_road_location(board, players::Vector{PlayerPublicView}, player, candidates)
        coord1 = coord[1]
        coord2 = coord[2]
        return ((coord1, coord2), (g, b, p) -> construct_road(b, p.player, coord1, coord2))
    end
    if :BuyDevCard in rand_action
        return (nothing, (g, b, p) -> draw_devcard(g, p.player))
    end
    if :PlayDevCard in rand_action
        devcards = PlayerApi.get_admissible_devcards(player.player)
        card = _choose_play_devcard(board, players, player, devcards)
        if card != nothing
            return (card, (g, b, p) -> do_play_devcard(b, g.players, p, card))
        end
    end
    if :ProposeTrade in rand_action
        if rand() > .8
            sampled = random_sample_resources(player.player.resources, 1)
            rand_resource_from = [sampled...]
            
            rand_resource_to = [get_random_resource()]
            while rand_resource_to[1] == rand_resource_from[1]
                rand_resource_to = [get_random_resource()]
            end
            return ((rand_resource_from, rand_resource_to), (g, b, p) -> propose_trade_goods(b, g.players, p, rand_resource_from, rand_resource_to))
        end
    end
    return (nothing, nothing)
end

function choose_who_to_trade_with(board::Board, player::RobotPlayer, players::Vector{PlayerPublicView})::Symbol
    max_ind = player.player
    while max_ind.team == player.player.team
        max_ind = sample(collect(players), 1)[1]
    end
    @info "$(player.player.team) decided it is wisest to do business with $(max_ind.team) player"
    return max_ind.team
end
