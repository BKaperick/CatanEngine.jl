import Random

include("constants.jl")
include("structs.jl")
include("robo.jl")
include("human.jl")

function _parse_ints(descriptor)
    human_response = input(descriptor)
    asints = Tuple([tryparse(Int, x) for x in split(human_response, ' ')])
    println("$asints, $(all([x == nothing || x == Nothing for x in asints]))")
    if all([x == nothing || x == Nothing for x in asints])
        return get_coord_from_human_tile_description(human_response)
    end
    return asints
end

function _parse_resources(descriptor)
    reminder = join(["$k: $v" for (k,v) in HUMAN_RESOURCE_TO_SYMBOL], " ")
    println("($reminder)")
    return Tuple([HUMAN_RESOURCE_TO_SYMBOL[uppercase(String(x))] for x in split(input(descriptor), ' ')])
end

# Player API
function discard_cards(player, resources)
    log_action(":$(player.team) dc", resources...)
    _discard_cards(player, resources...)
end
function _discard_cards(player, resources...)
    for r in resources
        _take_resource(player, r)
    end
end

function count_cards(player::Player)
    sum(values(player.resources))
end

function give_resource(player::Player, resource::Symbol)
    log_action(":$(player.team) gr", resource)
    _give_resource(player, resource)
end
function _give_resource(player::Player, resource::Symbol)
    if haskey(player.resources, resource)
        player.resources[resource] += 1
    else
        player.resources[resource] = 1
    end
end
function take_resource(player::Player, resource::Symbol)
    log_action(":$(player.team) tr", resource)
    _take_resource(player, resource)
end
function _take_resource(player::Player, resource::Symbol)
    if haskey(player.resources, resource) && player.resources[resource] > 0
        player.resources[resource] -= 1
    end
end

# Human Player API
function roll_dice(player::HumanPlayer)::Int
    _parse_ints("Dice roll:")[1]
end

function choose_cards_to_discard(player::HumanPlayer, amount)
    return _parse_resources("$(player.player.team) discards: ")
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
function choose_place_robber(board, players, player::HumanPlayer)
    _parse_ints("$(player.player.team) places the Robber:")
end


# Robot Player API.  Your RobotPlayer type must implement these methods

function roll_dice(player::RobotPlayer)::Int
    value = 7 #rand(1:6) + rand(1:6)
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

function choose_cards_to_discard(player::RobotPlayer, amount)
    return random_sample_resources(player.player.resources, amount)
end

function choose_place_robber(board, players, player::RobotPlayer)
    validated = false
    sampled_value = Nothing
    while ~validated
        validated = true
        sampled_value = get_random_tile(board)
        println("random tile = $sampled_value")
        neighbors = TILE_TO_COORDS[sampled_value]
        for c in neighbors
            if haskey(board.coord_to_building, c) && board.coord_to_building[c].team == player.player.team
                println("validation failed: $c is a neighbor of $sampled_value")
                validated = false
            end
        end
    end
    println("$(player.player.team) placing robber at $(sampled_value)")
    return sampled_value
end
