module Catan
include("main.jl")

export DefaultRobotPlayer, RobotPlayer, Player, Board, PlayerType, PlayerPublicView, Game,
    initialize_and_do_game!

# Additionally used for testing
export get_coord_from_human_tile_description,
get_road_coords_from_human_tile_description,
get_neighbors,
read_map,
load_gamestate!,
reset_savefile

# Player methods to implement
export choose_accept_trade,
choose_building_location,
choose_cards_to_discard,
choose_monopoly_resource,
choose_place_robber,
choose_play_devcard,
choose_next_action,
choose_road_location,
choose_robber_victim,
choose_who_to_trade_with,
choose_year_of_plenty_resources,
choose_card_to_steal,

PLAYER_ACTIONS,
MAX_SETTLEMENT,
MAX_CITY

game = nothing
println(ARGS)
reset_savefile("game_$(Dates.format(now(), "HHMMSS")).txt")

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
        reset_savefile(SAVEFILE)

        if SAVE_GAME_TO_FILE
            global SAVEFILEIO = open(SAVEFILE, "a")
        end
    else
        reset_savefile("./data/savefile.txt")
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
    reset_savefile("./data/savefile.txt")
    #SAVEFILE = "./data/savefile.txt"
    #if SAVE_GAME_TO_FILE
    #    global SAVEFILEIO = open(SAVEFILE, "a")
    #end
    initialize_and_do_game!(game, MAPFILE, SAVEFILE)
end

if length(ARGS) >= 2
    run(ARGS)
end

if length(ARGS) >= 2
    run(ARGS)
end

end
