include("main.jl")
# Configure players and table configuration
#TEAM_AND_PLAYERTYPE = [
#                      (:Green, HumanPlayer),
#                      (:Marron, RobotPlayer),
#                      (:Red, HumanPlayer),
#                      (:Blue, RobotPlayer)
#        ]
#PLAYERS = [player(team) for (team,player) in TEAM_AND_PLAYERTYPE]
game = nothing
println(ARGS)
if length(ARGS) >= 2
    println("Loading player types and map...")
    CONFIGFILE = ARGS[1]
    PLAYERS = read_players_from_config(CONFIGFILE)
    game = Game(PLAYERS)
    MAPFILE = ARGS[2]
end
if length(ARGS) >= 3
    LOGFILE = ARGS[3]
    load_game(game, LOGFILE)
elseif length(ARGS) < 4
    LOGFILEIO = open(LOGFILE, "a")
end
LOGFILEIO = open(LOGFILE, "a")
#initialize_game(game, "sample.csv", LOGFILE)
initialize_game(game, MAPFILE, LOGFILE)
