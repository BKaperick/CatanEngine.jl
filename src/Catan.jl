module Catan
include("main.jl")

export DefaultRobotPlayer, RobotPlayer, Player

game = nothing
println(ARGS)

function run(args)
    if length(args) >= 1
        CONFIGFILE = args[1]
        PLAYERS = read_players_from_config(CONFIGFILE)
    end
    return run(args, PLAYERS)
end
function run(args, PLAYERS)
    if length(args) >= 1
        game = Game(PLAYERS)
    end
    if length(args) >= 2
        MAPFILE = args[2]
    else
        MAPFILE = generate_random_map("_temp_map_file.csv")
    end
    if length(args) >= 3
        SAVEFILE = args[3]
        if SAVE_GAME_TO_FILE
            global SAVEFILEIO = open(SAVEFILE, "a")
        end
    else
        SAVEFILE = "./data/savefile.txt"
        io = open(SAVEFILE, "w")
        write(io,"")
        close(io)
        if SAVE_GAME_TO_FILE
            global SAVEFILEIO = open(SAVEFILE, "a")
        end
    end
    #initialize_game(game, "data/sample.csv", SAVEFILE)
    initialize_and_do_game!(game, MAPFILE, SAVEFILE)
end

function run(players::Vector{PlayerType})
    game = Game(players)
    MAPFILE = generate_random_map("_temp_map_file.csv")
    SAVEFILE = "./data/savefile.txt"
    io = open(SAVEFILE, "w"); write(io,""); close(io)
    if SAVE_GAME_TO_FILE
        global SAVEFILEIO = open(SAVEFILE, "a")
    end
    initialize_and_do_game!(game, MAPFILE, SAVEFILE)
end

if length(ARGS) >= 2
    run(ARGS)
end

if length(ARGS) >= 2
    run(ARGS)
end

end
