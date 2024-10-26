module Catan
include("main.jl")

game = nothing
println(ARGS)

function run(args)
    if length(ARGS) >= 2
        CONFIGFILE = ARGS[1]
        PLAYERS = read_players_from_config(CONFIGFILE)
        game = Game(PLAYERS)
        MAPFILE = ARGS[2]
    end
    if length(ARGS) >= 3
        SAVEFILE = ARGS[3]
        global SAVEFILEIO = open(SAVEFILE, "a")
    end
    #initialize_game(game, "data/sample.csv", SAVEFILE)
    initialize_game(game, MAPFILE, SAVEFILE)
end

if length(ARGS) >= 2
    run(ARGS)
end

end
