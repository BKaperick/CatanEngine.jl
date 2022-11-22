include("main.jl")
# Configure players and table configuration
TEAM_AND_PLAYERTYPE = [
                      (:Green, HumanPlayer),
                      (:Marron, RobotPlayer),
                      (:Red, HumanPlayer),
                      (:Blue, RobotPlayer)
        ]
PLAYERS = [player(team) for (team,player) in TEAM_AND_PLAYERTYPE]

game = Game(PLAYERS)
if length(ARGS) > 0
    LOGFILE = ARGS[1]
    LOGFILEIO = open(LOGFILE, "a")
    #initialize_game(game, "sample.csv", LOGFILE)
    initialize_game(game, "julie.csv", LOGFILE)
else
    LOGFILEIO = open(LOGFILE, "a")
    initialize_game(game, "julie.csv")
end
