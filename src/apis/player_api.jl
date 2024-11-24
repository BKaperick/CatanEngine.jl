import Random
include("../players/human_player.jl")
include("../players/robot_player.jl")
include("../players/empath_robot_player.jl")
include("human_action_interface.jl")

# Players API

#
# Meta-game Player API: for initializing and storing results for purposes of algorithm training
#

"""
    initialize_player(board::Board, player::PlayerType)

This function is useful to do any one-time computations of the player as soon 
as the board is generated.
"""
function initialize_player(board::Board, player::PlayerType)
end

"""
    save_parameters_after_game_end(board::Board, player::PlayerType)

After the game, store or update parameters based on the end state
"""
function save_parameters_after_game_end(file::IO, board::Board, players::Vector{PlayerType}, player::PlayerType, winner_team::Symbol)
end


# Player API


# Since we don't know which card the human took, we just give them the option to play anything
function get_admissible_devcards(player::HumanPlayer)
    return deepcopy(DEVCARD_COUNTS)
end
get_admissible_devcards(player::RobotPlayer) = get_admissible_devcards(player.player)
function get_admissible_devcards(player::Player)
    if ~can_play_dev_card(player)
        return 
    end
    out = deepcopy(player.dev_cards)
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

    # TODO these checks should never need to happen
    if haskey(player.dev_cards, devcard)
        player.dev_cards[devcard] -= 1
    end
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

function assign_largest_army!(players::Vector{PlayerType})
    
    # Gather all players who've played at least three Knights
    max_ct = 3
    player_and_count = Vector{Tuple{PlayerType, Int}}()
    for p in players
        if haskey(p.player.dev_cards_used, :Knight)
            ct = p.player.dev_cards_used[:Knight]
            if ct >= 3
                push!(player_and_count, (p, ct))
            end
            if ct > max_ct
                max_ct = ct
            end
        end
    end

    # If noone has crossed threshold, then exit
    if length(player_and_count) == 0
        return nothing
    end
    
    # Gather those with the max number of knights, as well as the current LargestArmy holder
    admissible = [(p,c) for (p,c) in player_and_count if c == max_ct]
    old_winners = [p for p in players if p.player.has_largest_army]
    @assert length(old_winners) <= 1
    if length(old_winners) > 0
        old_winner = old_winners[1]
    else
        old_winner = nothing
    end
    
    # Most often there is only one admissible person
    if length(admissible) == 1 
        winner = admissible[1][1]
        _transfer_largest_army(old_winner, winner)
        return nothing
    
    # If noone dethrones current winner
    elseif length(admissible) > 1 
        if old_winner != nothing
            return nothing
        else
            println(player_and_count)
            println(admissible)
            println(old_winners)
            @assert false
        end
    end

    _transfer_largest_army(old_winner, winner)
end

function _transfer_largest_army(old_winner::Union{PlayerType, Nothing}, new_winner::Union{PlayerType, Nothing})
    # Don't fill up log with removing and re-adding LargestArmy to same player
    if old_winner != nothing && new_winner != nothing && new_winner.player.team == old_winner.player.team
        return
    end

    if old_winner != nothing
        log_action(":$(old_winner.player.team) rl")
        _remove_largest_army(old_winner.player)
    end

    if new_winner != nothing
        log_action(":$(new_winner.player.team) la")
        _assign_largest_army(new_winner.player)
    end
end

function _assign_largest_army(player::Player)
    player.has_largest_army = true
end
function _remove_largest_army(player::Player)
    player.has_largest_army = false
end
