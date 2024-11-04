include("../learning/feature_computation.jl")

function get_probability_of_victory_estimate(board::Board, players::Vector{PlayerPublicView}, player::PlayerPublicView)::Float
end

function get_probability_of_victory_estimate(board::Board, players::Vector{PlayerPublicView}, player::PlayerPublicView)::Float
end

function save_parameters_after_game_end(file::IO, game::Game, board::Board, players::Vector{PlayerType}, player::EmpathRobotPlayer, winner_team::Symbol)
    features = compute_features(game, board, player.player)

    # For now, we just use a binary label to say who won
    label = get_csv_friendly(player.player.team == winner_team)
    values = join([get_csv_friendly(f[2]) for f in features], ",")
    
    println("values = $values,$label")
    write(file, "$values,$label\n")
end
