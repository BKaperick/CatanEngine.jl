include("../learning/feature_computation.jl")
include("../learning/production_model.jl")

function get_probability_of_victory_estimate(board::Board, players::Vector{PlayerPublicView}, player::PlayerPublicView)::Float
end

function get_probability_of_victory_estimate(board::Board, players::Vector{PlayerPublicView}, player::PlayerPublicView)::Float
end

# get_legal_actions(board, player)

function choose_next_action(board::Board, players::Vector{PlayerPublicView}, player::RobotPlayer, actions::Set{Symbol})
    #legal_actions = get_legal_actions(game, board, player) # ::Set{Symbol}
    current_features = compute_features(board, player.player)
    current_win_proba = predict_model(machine, board, player)
    @info "$(player.player.team) thinks his chance of winning is $(current_win_proba)"
    for action in actions
    end
end
function save_parameters_after_game_end(file::IO, board::Board, players::Vector{PlayerType}, player::EmpathRobotPlayer, winner_team::Symbol)
    features = compute_features(board, player.player)

    # For now, we just use a binary label to say who won
    label = get_csv_friendly(player.player.team == winner_team)
    values = join([get_csv_friendly(f[2]) for f in features], ",")
    
    println("values = $values,$label")
    write(file, "$values,$label\n")
end
