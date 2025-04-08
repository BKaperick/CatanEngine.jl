using Dates
using Logging
using TOML

function reset_configs(config_file, base_dir)
    config_path = joinpath(base_dir, config_file)
    configs = TOML.parsefile(config_path)::Dict{String, Any}
    user_configs = configs["UserSettings"]
    global player_configs = configs["PlayerSettings"]
    
    global DATA_DIR = joinpath(base_dir, user_configs["DATA_DIR"])
    global SAVE_GAME_TO_FILE = user_configs["SAVE_GAME_TO_FILE"]
    global PRINT_BOARD = user_configs["PRINT_BOARD"]
    global MAX_TURNS = user_configs["MAX_TURNS"]
    
    logger_output = user_configs["LOG_OUTPUT"]
    #log_level = eval(Meta.parse(user_configs["LOG_LEVEL"]))
    log_level_str = user_configs["LOG_LEVEL"]
    if log_level_str == "Logging.Info"
        log_level = Logging.Info
    elseif log_level_str == "Logging.Warn"
        log_level = Logging.Warn
    else
        log_level = Logging.Debug
    end



    logger_io = stderr
    if logger_output == "stderr"
        logger_io = stderr
        global logger = ConsoleLogger(logger_io, log_level)
    else
        logger_io = open(logger_output, "w+")
        write(logger_io, "")
        close(logger_io)
        logger_io = open(logger_output, "w+")
        global logger = SimpleLogger(logger_io, log_level)
    end
    global_logger(logger)
    reset_savefile(joinpath(base_dir, joinpath(base_dir, user_configs["SAVE_FILE"])))
    global player_configs = configs["PlayerSettings"]
    println("Configs loaded from $config_path")
    println("player configs: $player_configs")
end

function parse_configs(config_path)
    configs = TOML.parsefile(config_path)::Dict{String, Any}
    user_configs = configs["UserSettings"]
    player_configs = configs["PlayerSettings"]
    
    logger_output = user_configs["LOG_OUTPUT"]
    #log_level = eval(Meta.parse(user_configs["LOG_LEVEL"]))
    log_level_str = user_configs["LOG_LEVEL"]
    if log_level_str == "Logging.Info"
        log_level = Logging.Info
    elseif log_level_str == "Logging.Warn"
        log_level = Logging.Warn
    else
        log_level = Logging.Debug
    end


    logger_io = stderr
    if logger_output == "stderr"
        logger_io = stderr
        logger = ConsoleLogger(logger_io, log_level)
    else
        logger_io = open(logger_output, "w+")
        write(logger_io, "")
        close(logger_io)
        logger_io = open(logger_output, "w+")
        logger = SimpleLogger(logger_io, log_level)
    end
    user_configs["LOG_LEVEL"] = log_level
    global_logger(logger)

    player_configs = configs["PlayerSettings"]
    println("Configs loaded from $config_path")
    return user_configs, player_configs, logger
end

MAX_CITY = 4
MAX_SETTLEMENT = 5
MAX_ROAD = 14
MAX_RESOURCE = 25

function reset_savefile(path, io, configs::Dict)
    configs["SAVE_FILE"] = path
    configs["SAVE_FILE_IO"] = io
end

function reset_savefile(path, configs::Dict)
    configs["SAVE_FILE"] = path

    if configs["SAVE_GAME_TO_FILE"]
        io = open(path, "w"); write(io,""); close(io)
    end
    configs["SAVE_FILE_IO"] = open(path, "a")
    println("Savefile set to $path")
end

VP_AWARDS = Dict([
                  :Settlement => 1,
                  :City => 2,
                  :Road => 0,
                  :LargestArmy => 2,
                  :LongestRoad => 2
                 ])

HUMAN_ACTIONS = Dict(
    "bs" => :ConstructSettlement,
    "bc" => :ConstructCity,
    "br" => :ConstructRoad,
    "pt" => :ProposeTrade,
    "bd" => :BuyDevCard,
    "pd" => :PlayDevCard
   )
ACTION_TO_DESCRIPTION = Dict(
    :ProposeTrade => "[pt] Propose trade (e.g. \"pt 2 w w g g\")",
    :ConstructCity => "[bc] Build city",
    :ConstructSettlement => "[bs] Build settlement",
    :ConstructRoad => "[br] Build road",
    :BuyDevCard => "[bd] Buy development card",
    :PlayDevCard => "[pd] Play development card"
   )


COSTS = Dict([
              :Settlement => Dict([
                                   :Wood => 1,
                                   :Brick => 1,
                                   :Pasture => 1,
                                   :Grain => 1
                                  ]),
              :City => Dict([
                             :Grain => 2,
                             :Stone => 3
                            ]),
              :DevelopmentCard => Dict([
                                        :Pasture => 1,
                                        :Stone => 1,
                                        :Grain => 1
                                       ]),
              :Road => Dict([
                             :Brick => 1,
                             :Wood => 1
                            ])
             ])

HUMAN_DEVCARD_TO_SYMBOL = Dict([
"K" => :Knight,
"M" => :Monopoly,
"Y" => :YearOfPlenty,
"R" => :RoadBuilding,
"V" => :VictoryPoint
])

DEVCARD_COUNTS = Dict([
                               :Knight => 14,
                               :RoadBuilding => 2,
                               :YearOfPlenty => 2,
                               :Monopoly => 2,
                               :VictoryPoint => 5
                              ])

HUMAN_RESOURCE_TO_SYMBOL = Dict([
"W" => :Wood,
"S" => :Stone,
"G" => :Grain,
"B" => :Brick,
"P" => :Pasture,
"D" => :Desert
])

RESOURCES = Set([
                 :Wood,
                 :Stone,
                 :Grain,
                 :Brick,
                 :Pasture
                ])

RESOURCE_TO_COUNT = Dict([
    :Wood => 4
    :Stone => 3
    :Grain => 4
    :Brick => 3
    :Pasture => 4
    :Desert => 1
   ]) 
DICEVALUE_TO_COUNT = Dict([
    2 => 1
    3 => 2
    4 => 2
    5 => 2
    6 => 2
    7 => 1
    8 => 2
    9 => 2
    10 => 2
    11 => 2
    12 => 1
   ]) 

COORD_TO_PORTNUM = Dict([
                         (1,1) => 1,
                         (1,2) => 1,
                         (1,4) => 2,
                         (1,5) => 2,
                         (2,8) => 3,
                         (2,9) => 3,
                         (3,11) => 4,
                         (3,12) => 4,
                         (5,8) => 5,
                         (5,9) => 5,
                         (6,4) => 6,
                         (6,5) => 6,
                         (6,1) => 7,
                         (6,2) => 7,
                         (4,1) => 8,
                         (4,2) => 8,
                         (3,2) => 9,
                         (2,1) => 9
                        ])
TILE_TO_ISOLATED_EDGE_COORDS = Dict([
                      :A => Set([(1,1),(1,2)]),
                      :B => Set([(1,4)]),
                      :C => Set([(1,6),(1,7)]),
                      
                      :D => Set([(2,1)]),
                      :E => Set(),
                      :F => Set(),
                      :G => Set([(2,9)]),
                      
                      :H => Set([(3,1),(4,1)]),
                      :I => Set(),
                      :J => Set(),
                      :K => Set(),
                      :L => Set([(3,11),(4,11)]),
                      
                      :M => Set([(5,1)]),
                      :N => Set(),
                      :O => Set(),
                      :P => Set([(5,9)]),
                      
                      :Q => Set([(6,1),(6,2)]),
                      :R => Set([(6,4)]),
                      :S => Set([(6,6),(6,7)]),
                           ])
TILE_TO_EDGE_COORDS = Dict(
                      :A => Set([(1,1),(1,2),(1,3),(2,2)]),
                      :B => Set([(1,3),(1,4),(1,5)]),
                      :C => Set([(1,5),(1,6),(1,7),(2,8)]),
                      
                      :D => Set([(2,1),(2,2),(3,2)]),
                      :E => Set(),
                      :F => Set(),
                      :G => Set([(2,8),(2,9),(3,10)]),
                      
                      :H => Set([(3,1),(3,2),(4,1),(4,2)]),
                      :I => Set(),
                      :J => Set(),
                      :K => Set(),
                      :L => Set([(3,10),(3,11),(4,10),(4,11)]),
                      
                      :M => Set([(5,1),(5,2),(4,2)]),
                      :N => Set(),
                      :O => Set(),
                      :P => Set([(5,8),(5,9),(4,10)]),
                      
                      :Q => Set([(6,1),(6,2),(6,3),(5,2)]),
                      :R => Set([(6,3),(6,4),(6,5)]),
                      :S => Set([(6,5),(6,6),(6,7),(5,8)]),
                     )
TILE_TO_COORDS = Dict(
                      :A => Set([(1,1),(1,2),(1,3),(2,2),(2,3),(2,4)]),
                      :B => Set([(1,3),(1,4),(1,5),(2,4),(2,5),(2,6)]),
                      :C => Set([(1,5),(1,6),(1,7),(2,6),(2,7),(2,8)]),
                      
                      :D => Set([(2,1),(2,2),(2,3),(3,2),(3,3),(3,4)]),
                      :E => Set([(2,3),(2,4),(2,5),(3,4),(3,5),(3,6)]),
                      :F => Set([(2,5),(2,6),(2,7),(3,6),(3,7),(3,8)]),
                      :G => Set([(2,7),(2,8),(2,9),(3,8),(3,9),(3,10)]),
                      
                      :H => Set([(3,1),(3,2),(3,3),(4,1),(4,2),(4,3)]),
                      :I => Set([(3,3),(3,4),(3,5),(4,3),(4,4),(4,5)]),
                      :J => Set([(3,5),(3,6),(3,7),(4,5),(4,6),(4,7)]),
                      :K => Set([(3,7),(3,8),(3,9),(4,7),(4,8),(4,9)]),
                      :L => Set([(3,9),(3,10),(3,11),(4,9),(4,10),(4,11)]),
                      
                      :M => Set([(5,1),(5,2),(5,3),(4,2),(4,3),(4,4)]),
                      :N => Set([(5,3),(5,4),(5,5),(4,4),(4,5),(4,6)]),
                      :O => Set([(5,5),(5,6),(5,7),(4,6),(4,7),(4,8)]),
                      :P => Set([(5,7),(5,8),(5,9),(4,8),(4,9),(4,10)]),
                      
                      :Q => Set([(6,1),(6,2),(6,3),(5,2),(5,3),(5,4)]),
                      :R => Set([(6,3),(6,4),(6,5),(5,4),(5,5),(5,6)]),
                      :S => Set([(6,5),(6,6),(6,7),(5,6),(5,7),(5,8)]),
                     )
TILES = [t for t in keys(TILE_TO_COORDS)]
COORD_TO_TILES = Dict()
for elem in TILE_TO_COORDS
    # print("elem: ", elem, "\n")
    tile = elem[1]
    coords = elem[2]
    for c in coords
        if haskey(COORD_TO_TILES,c)
            push!(COORD_TO_TILES[c], tile)
        else
            COORD_TO_TILES[c] = Set([tile])
        end
    end
end
DIMS = [7,9,11,11,9,7]

DICEVALUE_TO_PROBA_WEIGHT = Dict(
                                 2 => 1,
                                 12 => 1,
                                 3 => 2,
                                 11 => 2,
                                 4 => 3,
                                 10 => 3,
                                 5 => 4,
                                 9 => 4,
                                 6 => 5,
                                 8 => 5,
                                 7 => 0
                                )
