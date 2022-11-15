include("main.jl")
# Configure players and table configuration
TEAM_AND_PLAYERTYPE = [
                      (:Blue, HumanPlayer),
                      (:Brown, HumanPlayer),
                      #(:Orange, HumanPlayer),
                      #(:Green, HumanPlayer),
                      (:Robo, RobotPlayer)
        ]
PLAYERS = [player(team) for (team,player) in TEAM_AND_PLAYERTYPE]

game = Game(PLAYERS)
if length(ARGS) > 0
    LOGFILE = ARGS[1]
    LOGFILEIO = open(LOGFILE, "a")
    initialize_game(game, "sample.csv", LOGFILE)
else
    LOGFILEIO = open(LOGFILE, "a")
    initialize_game(game, "sample.csv")
end
