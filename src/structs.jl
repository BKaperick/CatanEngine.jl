
mutable struct Game
    devcards::Dict{Symbol,Int}
    players::Vector{PlayerType}
    # This field is needed in order to reload a game that was saved and quit in the middle of a turn
    already_played_this_turn::Set{Symbol}
    turn_num::Int
    turn_order_set::Bool
    first_turn_forward_finished::Bool
    rolled_dice_already::Bool
    unique_id::Int
    configs::Dict{String, Any}
end

Game(players) = Game(players, Dict{String, Any}())
Game(players, configs) = Game(get_devcard_counts(configs), [deepcopy(p) for p in players], Set(), 1, false, false, false, rand(range(1,10000)), configs)

struct Road
    coord1::Tuple{Int8,Int8}
    coord2::Tuple{Int8,Int8}
    team::Symbol
end

struct Building
    coord::Tuple{Int8,Int8}
    type::Symbol
    team::Symbol
end

mutable struct Board
    tile_to_dicevalue::Dict{Symbol,Int8}
    #dicevalue_to_coords::Dict{Symbol,Int}
    dicevalue_to_tiles::Dict{Int8,Vector{Symbol}}
    tile_to_resource::Dict{Symbol,Symbol}
    coord_to_building::Dict{Tuple{Int8,Int8},Building}
    coord_to_roads::Dict{Tuple{Int8, Int8}, Set{Road}}
    coord_to_port::Dict{Tuple{Int8,Int8},Symbol}
    buildings::Array{Building,1}
    roads::Array{Road,1}
    robber_tile::Symbol
    spaces::Vector{Vector{Bool}}
    resources::Dict{Symbol,Int}
    # Team of player with the longest road card (is nothing if no player has a road at least 5 length)
    longest_road::Union{Nothing, Symbol}
    largest_army::Union{Nothing, Symbol}
    configs::Dict
end

Board(tile_to_value::Dict, dicevalue_to_tiles::Dict, tile_to_resource::Dict, 
      robber_tile::Symbol, coord_to_port::Dict, configs::Dict) = Board(tile_to_value, 
      dicevalue_to_tiles, tile_to_resource, Dict(), Dict(), coord_to_port, 
      [], [], robber_tile, 
      BoardApi.initialize_empty_board(DIMS), 
      Dict([(r, configs["GameSettings"]["MaxComponents"]["RESOURCE"]) for r in RESOURCES]), 
      nothing, nothing, configs)
Board(csvfile) = BoardApi.Board(csvfile)

function Base.deepcopy(board::Board)
    return Board(
                 deepcopy(board.tile_to_dicevalue),
                 deepcopy(board.dicevalue_to_tiles),
                 deepcopy(board.tile_to_resource),
                 deepcopy(board.coord_to_building),
                 deepcopy(board.coord_to_roads),
                 deepcopy(board.coord_to_port),
                 deepcopy(board.buildings),
                 deepcopy(board.roads),
                 board.robber_tile,
                 deepcopy(board.spaces),
                 deepcopy(board.resources),
                 board.longest_road,
                 board.largest_army,
                 board.configs
                    )
end

struct PreAction 
    name::Symbol
    admissible_args::Vector
    PreAction(name::Symbol, admissible_args::Vector) = new(name, unique(admissible_args))
end

struct ChosenAction
    name::Symbol
    args::Tuple
    ChosenAction(name::Symbol, args...) = new(name, args)
end

PreAction(name::Symbol) = PreAction(name, [])
PreAction(name::Symbol, admissible_args::Set) = PreAction(name, collect(admissible_args))
