EmpathRobotPlayer(team::Symbol) = EmpathRobotPlayer(Player(team), .5, .5, Dict())

function get_probability_of_victory_estimate(board::Board, players::Vector{PlayerPublicView}, player::PlayerPublicView)::Float
end

function get_probability_of_victory_estimate(board::Board, players::Vector{PlayerPublicView}, player::PlayerPublicView)::Float
end

"""
"""
function save_parameters_after_game_end(file::IO, game::Game, board::Board, players::Vector{PlayerType}, player::PlayerType)
    features = compute_features(game, board, player.player)
    header = join(['"' + string(f[1]) + '"' for f in features], ",")
    values = join([f[2] for f in features], ",")
    if filesize("data_game.csv") == 0
        write(file, header + "\n")
    end
    write(file, values + "\n")
end
