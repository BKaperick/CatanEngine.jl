module Catan

using DocStringExtensions
using Logging
using Random
using StatsBase

logger = ConsoleLogger(stderr, Logging.Warn)
#logger = ConsoleLogger(stderr, Logging.Debug)
#logger = ConsoleLogger(stderr, Logging.Info)
#logger = ConsoleLogger(stderr, Logging.LogLevel(5000))
global_logger(logger)

include("constants.jl")
include("random_helper.jl")

include("players/structs.jl")
include("structs.jl")

include("parsing.jl")
include("io.jl")

include("apis/player_api.jl")
import .PlayerApi
include("players/human_player.jl")
include("players/robot_player.jl")
include("apis/board_api.jl")
import .BoardApi
include("apis/game_api.jl")
import .GameApi
include("apis/human_action_interface.jl")
include("trading.jl")

include("main.jl")
include("actions.jl")
include("game_runner.jl")
import .GameRunner

include("../test/helper.jl")

export DefaultRobotPlayer, RobotPlayer, Player, Board, Road, PlayerType, PlayerPublicView, Game,
    initialize_and_do_game!,
BoardApi, 
PlayerApi,
GameApi,
GameRunner,
PreAction

# Player methods to implement
export choose_accept_trade,
choose_building_location,
choose_one_resource_to_discard,
choose_monopoly_resource,
choose_place_robber,
choose_next_action,
choose_road_location,
choose_robber_victim,
choose_who_to_trade_with,
choose_resource_to_draw,
choose_card_to_steal,

do_post_game_action,
do_post_action

PLAYER_ACTIONS,
MAX_SETTLEMENT,
MAX_CITY,
MAX_ROAD

if length(ARGS) >= 2
    run(ARGS)
end

if length(ARGS) >= 2
    run(ARGS)
end

end
