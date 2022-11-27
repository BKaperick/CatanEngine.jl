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
    SAVEFILE = ARGS[3]
    load_game(game, SAVEFILE)
elseif length(ARGS) < 4
    SAVEFILEIO = open(SAVEFILE, "a")
end
SAVEFILEIO = open(SAVEFILE, "a")
#initialize_game(game, "sample.csv", SAVEFILE)
initialize_game(game, MAPFILE, SAVEFILE)
