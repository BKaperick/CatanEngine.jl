import Random

include("constants.jl")
include("structs.jl")
include("robo.jl")
include("human.jl")

# Players API

# Player API

function play_devcard(player::Player, devcard::Symbol)
    log_action(":$(player.team) pd", devcard)
    _play_devcard(player, devcard)
end
function _play_devcard(player::Player, devcard::Symbol)
    player.dev_cards[devcard] -= 1
    if ~haskey(player.dev_cards_used)
        player.dev_cards_used[devcard] = 0
    end
    player.dev_cards_used[devcard] += 1
end

function has_enough_resources(player::Player, resources::Dict{Symbol,Int})::Bool
    for (r,amt) in resources
        if !haskey(player.resources, r)
            return false
        end
        if player.resources[r] < amt
            return false
        end
    end
    return true
end

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
    if length(coords) == 4
        out = [Tuple(coords[1:2]);Tuple(coords[3:4])]
    else
        out = coords
    end
    println(out)
    return out
end
function choose_place_robber(board, players, player::HumanPlayer)
    _parse_ints("$(player.player.team) places the Robber:")
end

choose_robber_victim(board, player, potential_victim::Symbol) = potential_victim

function choose_robber_victim(board, player::HumanPlayer, potential_victims...)
    if length(potential_victims) == 1
        return potential_victims[1]
    end
    _parse_teams("$(player.player.team) chooses his victim among $(join([v.player.team for v in potential_victims],",")):")
end
function choose_card_to_steal(player::HumanPlayer)::Symbol
    _parse_resources("$(player.player.team) lost his:")
end

function choose_play_devcard(board, players, player::HumanPlayer)
    _parse_devcard("Will $(player.player.team) play a devcard before rolling? (Enter to skip):")
end

function execute_api_call(game, board, player::HumanPlayer, api_call_str)
    execute_api_call(game, board, api_call_str)
end

function execute_api_call(game, board, player::RobotPlayer, api_call_str)
    api_call_str() # robot just returns the function rather than encoding as a string
end

function choose_rest_of_turn(game, board, players, player::HumanPlayer)
    full_options = """
    What does $(player.player.team) do next?
    [tg] Trade
    [bc] Build city
    [bs] Build settlement
    [E]nd turn
    """
    action = _parse_action(player.player.team, full_options)

end
function choose_rest_of_turn(game, board, players, player::RobotPlayer)
    return () -> build_settlement(board, player.player.team,(1,2))
end

function steal_random_resource(from_player, to_player)
    stolen_good = choose_card_to_steal(from_player)
    input("Press Enter when $(to_player.player.team) is ready to see the message")
    println("$(from_player.player.team) stole $stolen_good from $(to_player.player.team)")
    input("Press Enter again when you are ready to hide the message")
    run(`clear`)
    take_resource(from_player.player, stolen_good)
    give_resource(to_player.player, stolen_good)
end


# Robot Player API.  Your RobotPlayer type must implement these methods

function roll_dice(player::RobotPlayer)::Int
    value = rand(1:6) + rand(1:6)
    println("$(player.player.team) rolled a $value")
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
        sampled_value = get_random_tile(board)

        # Rules say you have to move the robber, can't leave it in place
        if sampled_value == board.robber_tile
            continue
        end
        validated = true
        neighbors = TILE_TO_COORDS[sampled_value]
        for c in neighbors
            if haskey(board.coord_to_building, c) && board.coord_to_building[c].team == player.player.team
                validated = false
            end
        end
    end
    return sampled_value
end
function choose_robber_victim(board, player::RobotPlayer, potential_victims...)::PlayerType
    public_scores = count_victory_points_from_board(board)
    max_ind = argmax(v -> public_scores[v.player.team], potential_victims)
    println("$(player.player.team) decided it is wisest to steal from the $(max_ind.player.team) player")
    return max_ind
end
function choose_card_to_steal(player::RobotPlayer)::Symbol
    random_sample_resources(player.player.resources, 1)[1]
end
