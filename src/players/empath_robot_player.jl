include("../learning/feature_computation.jl")
include("../learning/production_model.jl")


"""
    `choose_next_action(board::Board, players::Vector{PlayerPublicView}, player::EmpathRobotPlayer, actions::Set{Symbol})`

Gathers all legal actions, and chooses the one that most increases the player's probability of victory, based on his `player.machine` model.  If no action increases the probability of victory, then do nothing.
"""
function choose_next_action(board::Board, players::Vector{PlayerPublicView}, player::EmpathRobotPlayer, actions::Set{Symbol})
    action_functions = get_legal_action_functions(board, players, player, actions)
    best_action_index = 0
    best_action_proba = -1

    current_features = compute_features(board, player.player)
    current_win_proba = predict_model(player.machine, board, player)
    @info "$(player.player.team) thinks his chance of winning is $(current_win_proba)"
    
    for (i,action_func!) in enumerate(action_functions)

        # Deep copy game objects, apply the proposed action, and compute win probability
        # TODO this is an illogical approach for non-deterministic actions like drawing 
        # a card...
        hypoth_board = deepcopy(board)
        hypoth_player = deepcopy(player)
        hypoth_game = Game([DefaultRobotPlayer(p.team) for p in players])
        action_func!(hypoth_game, hypoth_board, hypoth_player)
        p = predict_model(hypoth_player.machine, hypoth_board, hypoth_player)
        
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

function save_parameters_after_game_end(file::IO, board::Board, players::Vector{PlayerType}, player::EmpathRobotPlayer, winner_team::Symbol)
    features = compute_features(board, player.player)

    # For now, we just use a binary label to say who won
    label = get_csv_friendly(player.player.team == winner_team)
    values = join([get_csv_friendly(f[2]) for f in features], ",")
    
    println("values = $values,$label")
    write(file, "$values,$label\n")
end

# TODO implement this based on ML model, only accept trade if win proba augments more than the other player's win proba from the trade
# function choose_accept_trade(board::Board, player::RobotPlayer, from_player::PlayerPublicView, from_goods::Vector{Symbol}, to_goods::Vector{Symbol})::Bool
