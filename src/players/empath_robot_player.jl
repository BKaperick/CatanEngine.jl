include("../learning/feature_computation.jl")
include("../learning/production_model.jl")

function get_probability_of_victory_estimate(board::Board, players::Vector{PlayerPublicView}, player::PlayerPublicView)::Float
end

function get_probability_of_victory_estimate(board::Board, players::Vector{PlayerPublicView}, player::PlayerPublicView)::Float
end

# get_legal_actions(board, player)

function choose_next_action(board::Board, players::Vector{PlayerPublicView}, player::EmpathRobotPlayer, actions::Set{Symbol})
    action_functions = get_legal_action_functions(board, players, player, actions)
    best_action_index = 0
    best_action_proba = -1

    current_features = compute_features(board, player.player)
    current_win_proba = predict_model(player.machine, board, player)
    @info "$(player.player.team) thinks his chance of winning is $(current_win_proba)"
    
    for (i,action_func!) in enumerate(action_functions)
        # TODO are there any weird side effects on board if we pass a fresh Game here?
        hypoth_board = deepcopy(board)
        hypoth_player = deepcopy(player)
        action_func!(Game([DefaultRobotPlayer(p.team) for p in players]), hypoth_board)
        p = predict_model(player.machine, board, player)
        if p > best_action_proba
            best_action_proba = p
            best_action_index = i
        end
    end

    # Only do an action if it will improve his estimated chances of winning
    if best_action_proba > current_win_proba
        @info "And his chance of winning will go to $(best_action_proba) with this next move"
        return action_functions[best_action_index]
    end
    return nothing

end

function get_legal_action_functions(board::Board, players::Vector{PlayerPublicView}, player::EmpathRobotPlayer, actions::Set{Symbol})
    #legal_actions = get_legal_actions(game, board, player) # ::Set{Symbol}
    action_functions = []

    if :ConstructCity in actions
        candidates = get_admissible_city_locations(board, player.player)
        for coord in candidates
            push!(action_functions, (g, b) -> construct_city(b, player.player, coord))
        end
    end
    if :ConstructSettlement in actions
        candidates = get_admissible_settlement_locations(board, player.player)
        for coord in candidates
            push!(action_functions, (g, b) -> construct_settlement(b, player.player, coord))
        end
    end
    if :ConstructRoad in actions
        candidates = get_admissible_road_locations(board, player.player)
        for coord in candidates
            push!(action_functions, (g, b) -> construct_road(b, player.player, coord[1], coord[2]))
        end
    end

    if :BuyDevCard in actions
        push!(action_functions, (g, board) -> buy_devcard(g, player.player))
    end
    if :PlayDevCard in actions
        devcards = get_admissible_devcards(player.player)
        for (card,cnt) in devcards
            # TODO how do we stop them playing devcards first turn they get them?  Is this correctly handled in get_admissible call?
            if card != :VictoryPoint
                push!(action_functions, (g, b) -> do_play_devcard(b, g.players, player, card))
            end
        end
    elseif :ProposeTrade in actions
        sampled = random_sample_resources(player.player.resources, 1)
        rand_resource_from = [sampled...]
        rand_resource_to = [get_random_resource()]
        while rand_resource_to[1] == rand_resource_from[1]
            rand_resource_to = [get_random_resource()]
        end
        push!(action_functions, (g, b) -> propose_trade_goods(b, g.players, player, rand_resource_from, rand_resource_to))
    end
    return action_functions
end

function save_parameters_after_game_end(file::IO, board::Board, players::Vector{PlayerType}, player::EmpathRobotPlayer, winner_team::Symbol)
    features = compute_features(board, player.player)

    # For now, we just use a binary label to say who won
    label = get_csv_friendly(player.player.team == winner_team)
    values = join([get_csv_friendly(f[2]) for f in features], ",")
    
    println("values = $values,$label")
    write(file, "$values,$label\n")
end

"""
    get_new_mutation(last_mutation::Dict{Symbol, AbstractFloat})

Randomly perturb the existing mutation returning transformed dict
"""
function get_new_mutation(last_mutation::Dict, magnitude::AbstractFloat)::Dict{Symbol, AbstractFloat}
    mutation_vector = magnitude * (rand([-1, 1]))
    possible_actions = collect(keys(ACTION_TO_DESCRIPTION))
    key = sample(possible_actions)
    
    if length(keys(last_mutation)) == 0
        return Dict(key => mutation_vector)
    end

    if haskey(last_mutation, key)
        last_mutation[key] += mutation_vector
    else
        last_mutation[key] = mutation_vector
    end
    return last_mutation
end

# TODO implement this based on ML model, only accept trade if win proba augments more than the other player's win proba from the trade
# function choose_accept_trade(board::Board, player::RobotPlayer, from_player::PlayerPublicView, from_goods::Vector{Symbol}, to_goods::Vector{Symbol})::Bool
