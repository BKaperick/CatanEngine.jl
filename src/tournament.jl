include("main.jl")
include("apis/player_api.jl")

SAVEFILEIO = open(SAVEFILE, "a")

team_and_playertype = [
                      (:Blue, EmpathRobotPlayer),
                      (:Green, DefaultRobotPlayer),
                      (:Cyan, DefaultRobotPlayer),
                      (:Yellow, DefaultRobotPlayer),
        ]
generate_players() = Vector{PlayerType}([player(team) for (team,player) in team_and_playertype])

# Surpress all normal logs
logger = ConsoleLogger(stderr, Logging.Warn)
global_logger(logger)
SAVE_GAME_TO_FILE = false

# Number of games to play per map
N = 100
# Number of maps to generate
M = 10
winners = Dict()

map_file = "_temp_map_file.csv"
for j=1:M
    map = generate_random_map(map_file)
    for i=1:N
        game = Game(generate_players())
        _,winner = initialize_game(game, map_file)

        k = winner
        if winner != nothing
            k = winner.player.team
        end
        if haskey(winners, k)
            winners[k] += 1
        else
            winners[k] = 1
        end
        if winner != nothing
            println("Game $i: $(winner.player.team)")
        end
    end
end
println(winners)

