import Random

include("constants.jl")
include("structs.jl")

function _parse_ints(descriptor)
    return Tuple([parse(Int, x) for x in split(input(descriptor), ' ')])
end

# Player API

function give_resource(player::Player, resource::Symbol)
    if haskey(player.resources, resource)
        player.resources[resource] += 1
    else
        player.resources[resource] = 1
    end
end

# Human Player API
function roll_dice(player::HumanPlayer)::Int
    _parse_ints("Dice roll:")[1]
end

function choose_building_location(board, players, player::HumanPlayer, building_type)::Tuple{Int, Int}
    _parse_ints("$(player.player.team) places a $(building_type):")
end
function choose_road_location(board, players, player::HumanPlayer)::Vector{Tuple{Int,Int}}
    coords = _parse_ints("$(player.player.team) places a Road:")
    out = [Tuple(coords[1:2]);Tuple(coords[3:4])]
    println(typeof(out))
    println(out)
    return out
end


# Robot Player API.  Your RobotPlayer type must implement these methods

function roll_dice(player::RobotPlayer)::Int
    value = rand(1:6) + rand(1:6)
    println("Robot rolled a $value")
    return value
end
function choose_road_location(board, players, player::RobotPlayer)::Vector{Tuple{Int,Int}}
    #TODO implement
    my_buildings = [b.coord for b in board.buildings if b.team == player.player.team]

    coord1 = rand(my_buildings)
    empty = get_empty_spaces(board)
    empty_neighbors = [n for n in get_neighbors(coord1) if n in empty]
    out = [coord1;rand(empty_neighbors)]
    println(out)
    return out
end
function choose_building_location(board, players, player::RobotPlayer, building_type)::Tuple{Int, Int}
    #TODO implement
    rand(get_empty_spaces(board))
end

