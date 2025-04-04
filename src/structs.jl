
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
end

Game(players) = Game(deepcopy(DEVCARD_COUNTS), [deepcopy(p) for p in players], Set(), 0, false, false, false, rand(range(1,10000)))

struct Road
    coord1::Tuple{Int,Int}
    coord2::Tuple{Int,Int}
    team::Symbol
end

struct Building
    coord::Tuple{Int,Int}
    type::Symbol
    team::Symbol
end

mutable struct Board
    tile_to_dicevalue::Dict{Symbol,Int}
    #dicevalue_to_coords::Dict{Symbol,Int}
    dicevalue_to_tiles::Dict{Int,Vector{Symbol}}
    tile_to_resource::Dict{Symbol,Symbol}
    coord_to_building::Dict{Tuple,Building}
    coord_to_roads::Dict{Tuple,Set{Road}}
    coord_to_port::Dict{Tuple,Symbol}
    empty_spaces::Vector
    buildings::Array{Building,1}
    roads::Array{Road,1}
    robber_tile::Symbol
    spaces::Vector
    resources::Dict{Symbol,Int}
    # Team of player with the longest road card (is nothing if no player has a road at least 5 length)
    longest_road::Union{Nothing, Symbol}
    largest_army::Union{Nothing, Symbol}
end

Board(tile_to_value::Dict, dicevalue_to_tiles::Dict, tile_to_resource::Dict, 
      robber_tile::Symbol, coord_to_port::Dict) = Board(tile_to_value, 
      dicevalue_to_tiles, tile_to_resource, Dict(), Dict(), coord_to_port, 
      BoardApi.initialize_empty_board(DIMS), [], [], robber_tile, 
      BoardApi.initialize_empty_board(DIMS), 
      Dict([(r, MAX_RESOURCE) for r in RESOURCES]), 
      nothing, nothing)
Board(csvfile) = BoardApi.Board(csvfile)

function Base.deepcopy(board::Board)
    return Board(
                 deepcopy(board.tile_to_dicevalue),
                 deepcopy(board.dicevalue_to_tiles),
                 deepcopy(board.tile_to_resource),
                 deepcopy(board.coord_to_building),
                 deepcopy(board.coord_to_roads),
                 deepcopy(board.coord_to_port),
                 deepcopy(board.empty_spaces),
                 deepcopy(board.buildings),
                 deepcopy(board.roads),
                 board.robber_tile,
                 deepcopy(board.spaces),
                 deepcopy(board.resources),
                 board.longest_road,
                 board.largest_army
                    )
end

struct PreAction 
    name::Symbol
    admissible_args::Set
end

PreAction(name::Symbol) = PreAction(name, Set([]))

function PreAction(name::Symbol, admissible_args::Vector)
    PreAction(name, Set(admissible_args))
end
