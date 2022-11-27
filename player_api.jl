import Random

include("constants.jl")
include("structs.jl")
include("robo.jl")
include("default_robot_player.jl")
include("action_interface.jl")

# Players API

# Player API
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

# Human Player API
function roll_dice(player::HumanPlayer)::Int
    parse_int("Dice roll:")
end

function choose_cards_to_discard(player::HumanPlayer, amount)
    return parse_resources("$(player.player.team) discards: ")
end

function choose_building_location(board, players, player::HumanPlayer, building_type, is_first_turn = false)::Tuple{Int, Int}
    parse_ints("$(player.player.team) places a $(building_type):")
end
function choose_road_location(board, players, player::HumanPlayer, is_first_turn = false)::Vector{Tuple{Int,Int}}
    coords = parse_road_coord("$(player.player.team) places a Road:")
    if length(coords) == 4
        out = [Tuple(coords[1:2]);Tuple(coords[3:4])]
    else
        out = coords
    end
    @info out
    return out
end
function choose_place_robber(board, players, player::HumanPlayer)
    parse_tile("$(player.player.team) places the Robber:")
end

choose_robber_victim(board, player, potential_victim::Symbol) = potential_victim

function choose_year_of_plenty_resources(board, players, player::HumanPlayer)
    parse_resources("$(player.player.team) choose two resources for free:")
    return
end

function choose_monopoly_resource(board, players, player::HumanPlayer)
    parse_resources("$(player.player.team) will steal all:")
end
function choose_robber_victim(board, player::HumanPlayer, potential_victims...)
    if length(potential_victims) == 1
        return potential_victims[1]
    end
    parse_teams("$(player.player.team) chooses his victim among $(join([v.player.team for v in potential_victims],",")):")
end
function choose_card_to_steal(player::HumanPlayer)::Symbol
    parse_resources("$(player.player.team) lost his:")
end
function choose_play_devcard(board, players, player::HumanPlayer, devcards::Dict)
    parse_devcard("Will $(player.player.team) play a devcard before rolling? (Enter to skip):")
end

function assign_largest_army(players)
    max_ct = 3
    max_p = []
    for p in players
        if haskey(p.player.dev_cards_used, :Knight)
            ct = p.player.dev_cards_used[:Knight]
            if ct > max_ct
                max_ct = ct
                max_p = [p]
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

function choose_rest_of_turn(game, board, players, player::HumanPlayer, actions)
    header = "What does $(player.player.team) do next?\n"
    full_options = string(header, [ACTION_TO_DESCRIPTION[a] for a in actions]..., "\n[E]nd turn")
    action_and_args = parse_action(full_options)
    if action_and_args == :EndTurn
        return nothing
    end
    @warn keys(PLAYER_ACTIONS)
    func = PLAYER_ACTIONS[action_and_args[1]]
    return (game, board) -> func(game, board, player, action_and_args[2:end]...)
end

#function choose_rest_of_turn(game, board, players, player::RobotPlayer)
#    actions = values(PLAYER_ACTIONS)
#    for act in actions
#end

function steal_random_resource(from_player, to_player)
    stolen_good = choose_card_to_steal(from_player)
    input("Press Enter when $(to_player.team) is ready to see the message")
    @info "$(from_player.player.team) stole $stolen_good from $(to_player.team)"
    input("Press Enter again when you are ready to hide the message")
    run(`clear`)
    take_resource(from_player.player, stolen_good)
    give_resource(to_player.player, stolen_good)
end
function steal_random_resource(from_player::RobotPlayer, to_player::RobotPlayer)
    stolen_good = choose_card_to_steal(from_player)
    take_resource(from_player.player, stolen_good)
    give_resource(to_player.player, stolen_good)
end
function choose_who_to_trade_with(board, player::HumanPlayer, players)
    parse_team("$(join([p.player.team for p in players], ", ")) have accepted. Who do you choose?")
end

function choose_accept_trade(board, player::HumanPlayer, from_player::Player, from_goods, to_goods)
    parse_yesno("Does $(player.player.team) want to recieve $from_goods and give $to_goods to $(from_player.team) ?")
end

function roll_dice(player::RobotPlayer)::Int
    value = rand(1:6) + rand(1:6)
    @info "$(player.player.team) rolled a $value"
    return value
end
