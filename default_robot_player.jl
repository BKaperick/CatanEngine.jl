#mutable struct DefaultRobotPlayer <: RobotPlayer
#    player::Player
#end
#
# Robot Player API.  Your RobotPlayer type must implement these methods
# choose_who_to_trade_with(board::Board, player::DefaultRobotPlayer, players::Vector{PlayerType})::Symbol
# choose_rest_of_turn(game::Game, board::Board, players::Vector{PlayerType}, player::DefaultRobotPlayer, actions::Set{Symbol})
# choose_accept_trade(board::Board, player::DefaultRobotPlayer, from_player::Player, from_goods::Vector{Symbol}, to_goods::Vector{Symbol})::Bool
#
function choose_accept_trade(board::Board, player::DefaultRobotPlayer, from_player::Player, from_goods::Vector{Symbol}, to_goods::Vector{Symbol})::Bool
    return rand() > .5 + (get_public_vp_count(board, from_player) / 20)
end

function choose_road_location(board::Board, players::Vector{PlayerType}, player::DefaultRobotPlayer, is_first_turn::Bool = false)::Union{Nothing,Vector{Tuple}}
    candidates = get_admissible_road_locations(board, player.player, is_first_turn)
    if length(candidates) > 0
        return sample(candidates)
    end
    @info "I didn't find any place to put my road"
    return nothing
end
function choose_building_location(board, players, player::DefaultRobotPlayer, building_type, is_first_turn = false)
    if building_type == :Settlement
        candidates = get_admissible_settlement_locations(board, player.player, is_first_turn)
        if length(candidates) > 0
            return sample(candidates, 1)[1]
        end
    elseif building_type == :City
        settlement_locs = get_admissible_city_locations(board, player.player)
        if length(settlement_locs) > 0
            return rand(settlement_locs)
        end
    end
    return nothing
end

function choose_cards_to_discard(player::DefaultRobotPlayer, amount)
    return random_sample_resources(player.player.resources, amount)
end

function choose_place_robber(board, players, player::DefaultRobotPlayer)
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

function choose_monopoly_resource(board, players, player::DefaultRobotPlayer)
    return get_random_resource()
end

function choose_year_of_plenty_resources(board, players, player::DefaultRobotPlayer)
    return get_random_resource(),get_random_resource()
end
function choose_robber_victim(board, player::DefaultRobotPlayer, potential_victims...)::PlayerType
    public_scores = count_victory_points_from_board(board)
    max_ind = argmax(v -> public_scores[v.player.team], potential_victims)
    
    
    @info "$(player.player.team) decided it is wisest to steal from the $(max_ind.player.team) player"
    return max_ind
end
function choose_card_to_steal(player::DefaultRobotPlayer)::Symbol
    random_sample_resources(player.player.resources, 1)[1]
end

function choose_play_devcard(board, players, player::DefaultRobotPlayer, devcards::Dict)::Union{Symbol,Nothing}
    if length(values(devcards)) > 0
        card = random_sample_resources(devcards, 1)[1]
        if card != :VictoryPoint
            return card
        end
    end
    return nothing
end

function choose_rest_of_turn(game::Game, board::Board, players::Vector{PlayerType}, player::DefaultRobotPlayer, actions::Set{Symbol})
    if :ConstructCity in actions
        coord = choose_building_location(board, players, player, :City)
        return (game, board) -> construct_city(board, player.player, coord)
    end
    if :ConstructSettlement in actions
        coord = choose_building_location(board, players, player, :Settlement)
        return (game, board) -> construct_settlement(board, player.player, coord)
    end
    if :ConstructRoad in actions
        coord = choose_road_location(board, players, player, false)
        coord1 = coord[1]
        coord2 = coord[2]
        return (game, board) -> construct_road(board, player.player, coord1, coord2)
    end
    if :BuyDevCard in actions
        return (game, board) -> buy_devcard(game, player.player)
    end
    if :PlayDevCard in actions
        devcards = get_admissible_devcards(player.player)
        card = choose_play_devcard(board, game.players, player, devcards)
        if card != nothing
            return (game, board) -> do_play_devcard(board, game.players, player, card)
        end
    elseif :ProposeTrade in actions
        if rand() > .8
            sampled = random_sample_resources(player.player.resources, 1)
            rand_resource_from = [sampled...]
            
            rand_resource_to = [get_random_resource()]
            while rand_resource_to[1] == rand_resource_from[1]
                rand_resource_to = [get_random_resource()]
            end
            return (game, board) -> propose_trade_goods(board, game.players, player, rand_resource_from, rand_resource_to)
        end
    end
    return nothing
end

function choose_who_to_trade_with(board::Board, player::DefaultRobotPlayer, players::Vector{PlayerType})::Symbol
    public_scores = count_victory_points_from_board(board)
    max_ind = argmax(v -> public_scores[v.player.team], players)
    @info "$(player.player.team) decided it is wisest to do business with $(max_ind.player.team) player"
    return max_ind.player.team
end

