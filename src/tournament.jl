include("main.jl")
include("apis/player_api.jl")

SAVEFILEIO = open(SAVEFILE, "a")

team_and_playertype = [
                      (:Blue, EmpathRobotPlayer),
                      (:Green, EmpathRobotPlayer),
                      (:Cyan, EmpathRobotPlayer),
                      (:Yellow, EmpathRobotPlayer),
        ]
players = Vector{PlayerType}([player(team) for (team,player) in team_and_playertype])

# Surpress all normal logs
logger = ConsoleLogger(stderr, Logging.Warn)
global_logger(logger)
SAVE_GAME_TO_FILE = false

N = 9
winners = Dict()
for i=1:N
    game = Game(copy(players))
    winner = initialize_game(game, "data/sample.csv")

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
println(winners)

