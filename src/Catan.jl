module Catan
include("main.jl")

game = nothing
println(ARGS)

function run(args)
    if length(ARGS) >= 1
        CONFIGFILE = ARGS[1]
        PLAYERS = read_players_from_config(CONFIGFILE)
        game = Game(PLAYERS)
    end
    if length(ARGS) >= 2
        MAPFILE = ARGS[2]
    else
        MAPFILE = generate_random_map("_temp_map_file.csv")
    end
    if length(ARGS) >= 3
        SAVEFILE = ARGS[3]
        if SAVE_GAME_TO_FILE
            global SAVEFILEIO = open(SAVEFILE, "a")
        end
    end
    #initialize_game(game, "data/sample.csv", SAVEFILE)
    initialize_and_do_game!(game, MAPFILE, SAVEFILE)
end

if length(ARGS) >= 2
    run(ARGS)
end

end
