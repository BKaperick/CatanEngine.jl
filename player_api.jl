import Random

include("constants.jl")
include("structs.jl")
include("random_helper.jl")
include("human_player.jl")
include("robot_player.jl")
include("action_interface.jl")

# Players API


# Player API

# This function is useful to do any one-time computations of the player as soon as the board is generated.
function initialize_player(board::Board, player::PlayerType)
end

# Since we don't know which card the human took, we just give them the option to play anything
function get_admissible_devcards(player::HumanPlayer)
    return copy(DEVCARD_COUNTS)
end
get_admissible_devcards(player::RobotPlayer) = get_admissible_devcards(player.player)
function get_admissible_devcards(player::Player)
    if ~can_play_dev_card(player)
        return 
    end
    out = copy(player.dev_cards)
    if player.bought_dev_card_this_turn != nothing
        out[player.bought_dev_card_this_turn] -= 1
    end
    return out
end
function trade_resource_with_bank(player::Player, from_resource, to_resource)
    rate = player.ports[from_resource]
    for r in 1:rate
        take_resource(player, from_resource)
    end
    give_resource(player, to_resource)
end

function can_play_dev_card(player::Player)::Bool
    return sum(values(player.dev_cards)) > 0 && ~player.played_dev_card_this_turn
end

function get_total_vp_count(board, player::Player)
    return get_public_vp_count(board, player) + get_vp_count_from_dev_cards(player)
end
function get_public_vp_count(board, player::Player)
    points = count_victory_points_from_board(board, player.team)
    if player.has_largest_army
        points += 2
    end
    if player.has_longest_road
        points += 2
    end
    return points
end

function get_vp_count_from_dev_cards(player::Player)
    if haskey(player.dev_cards, :VictoryPoint)
        return player.dev_cards[:VictoryPoint]
    end
    return 0
end
function add_devcard(player::Player, devcard::Symbol)
    log_action(":$(player.team) ad", devcard)
    _add_devcard(player, devcard)
end
function _add_devcard(player::Player, devcard::Symbol)
    if haskey(player.dev_cards, devcard)
        player.dev_cards[devcard] += 1
    else
        player.dev_cards[devcard] = 1
    end
end
    
function play_devcard(player::Player, devcard::Symbol)
    log_action(":$(player.team) pd", devcard)
    _play_devcard(player, devcard)
end
function _play_devcard(player::Player, devcard::Symbol)
    player.dev_cards[devcard] -= 1
    if ~haskey(player.dev_cards_used, devcard)
        player.dev_cards_used[devcard] = 0
    end
    player.dev_cards_used[devcard] += 1
    player.played_dev_card_this_turn = true
end

function count_resources(player::Player)
    total = 0
    for r in keys(RESOURCE_TO_COUNT)
        total += count_resource(player, r)
    end
    return total
end
function count_resource(player::Player, resource::Symbol)::Int
    if haskey(player.resources, resource)
        return player.resources[resource]
    end
    return 0
end

function has_any_resources(player::Player)::Bool
    for (r,amt) in player.resources
        if amt > 0
            return true
        end
    end
    return false
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

function discard_cards(player, resources...)
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

function add_port(player::Player, resource::Symbol)
    log_action(":$(player.team) ap", resource)
    _add_port(player, resource)
end
function _add_port(player::Player, resource::Symbol)
    if haskey(player.ports, resource)
        player.ports[resource] = 2

    # Alternative is that this port is a 3:1 universal, so we change any exchange rates of 4 to 3
    else
        for (k,v) in player.ports
            if v == 4
                player.ports[k] = 3
            end
        end
    end
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
    else
        @warn "$(player.team) has insufficient $(resource) cards"
    end
end

function roll_dice(player::RobotPlayer)::Int
    value = rand(1:6) + rand(1:6)
    @info "$(player.player.team) rolled a $value"
    return value
end

function assign_largest_army(players)
    max_ct = 3
    max_p = Vector{PlayerType}()
    for p in players
        if haskey(p.player.dev_cards_used, :Knight)
            ct = p.player.dev_cards_used[:Knight]
            if ct > max_ct
                max_ct = ct
                max_p = Vector{PlayerType}([p])
            elseif ct == max_ct
                push!(max_p, p)
            end
        end
    end
    if length(max_p) == 0
        return nothing
    end
    
    if length(max_p) > 1
        winners = [p for p in max_p if p.player.has_largest_army]
        @assert length(winners) == 1
        winner = winners[1]
    else
        winner = max_p[1]
    end

    old_winner = [p for p in players if p.player.has_largest_army]
    if length(old_winner) > 0
        log_action(":$(old_winner[1].player.team) rl")
        _remove_largest_army(old_winner[1].player)
    end

    log_action(":$(winner.player.team) la")
    return _assign_largest_army(winner.player)
end
function _assign_largest_army(player::Player)
    player.has_largest_army = true
end
function _remove_largest_army(player::Player)
    player.has_largest_army = false
end

