# Human Player API

# Since we don't know which card the human took, we just give them the option to play anything
function get_admissible_devcards(player::HumanPlayer)
    return deepcopy(DEVCARD_COUNTS)
end

function roll_dice(player::HumanPlayer)::Int
    parse_int(player.io, "Dice roll:")
end

function choose_cards_to_discard(player::HumanPlayer, amount)
    return parse_resources(player.io, "$(player.player.team) discards: ")
end

function choose_building_location(board::Board, players::Vector{PlayerPublicView}, player::HumanPlayer, candidates::Vector{Tuple{Int,Int}}, building_type::Symbol, is_first_turn = false)::Union{Nothing, Tuple{Int, Int}}
    if building_type == :Settlement
        validation_check = is_valid_settlement_placement
    else
        validation_check = is_valid_city_placement
    end
    coord = nothing
    while (!validation_check(board, player.player.team, coord))
        coord = parse_ints(player.io, "$(player.player.team) places a $(building_type):")
    end
end
function choose_road_location(board::Board, players::Vector{PlayerPublicView}, player::HumanPlayer, candidates::Vector{Tuple})::Vector{Tuple{Int,Int}}
    road_coord1 = nothing
    road_coord2 = nothing
    road_coords = Vector{Tuple{Int,Int}}()
    while (!is_valid_road_placement(board, player.player.team, road_coord1, road_coord2))
        coords = parse_road_coord(player.io, "$(player.player.team) places a Road:")
        if length(coords) == 4
            road_coords = [Tuple(coords[1:2]);Tuple(coords[3:4])]
        else
            road_coords = coords
        end
        @debug "road_coord: $road_coords"
        road_coord1 = road_coords[1]
        road_coord2 = road_coords[2]
    end
    @info road_coords
    return road_coords
end

function choose_place_robber(board::Board, players::Vector{PlayerType}, player::HumanPlayer)
    parse_tile(player.io, "$(player.player.team) places the Robber:")
end

function choose_year_of_plenty_resources(board, players, player::HumanPlayer)
    parse_resources(player.io, "$(player.player.team) choose two resources for free:")
    return
end

function choose_monopoly_resource(board, players, player::HumanPlayer)
    parse_resources(player.io, "$(player.player.team) will steal all:")
end
function choose_robber_victim(board, player::HumanPlayer, potential_victims...)
    @info "$([p.player.team for p in potential_victims])"
    if length(potential_victims) == 1
        return potential_victims[1]
    end
    team = parse_teams(player.io, "$(player.player.team) chooses his victim among $(join([v.player.team for v in potential_victims],",")):")
    return [p for p in potential_victims if p.player.team == team][1]
end
function choose_card_to_steal(player::HumanPlayer)::Symbol
    parse_resources(player.io, "$(player.player.team) lost his:")[1]
end

function choose_play_devcard(board, players, player::HumanPlayer, devcards::Dict)
    p = parse_devcard(player.io, "Will $(player.player.team) play a devcard before rolling? (Enter to skip):")
    if p == :nothing
        return nothing
    end
end

function choose_next_action(board, players, player::HumanPlayer, actions)
    header = "What does $(player.player.team) do next?\n"
    full_options = string(header, [ACTION_TO_DESCRIPTION[a] for a in actions]..., "\n[E]nd turn")
    action_and_args = parse_action(player.io, full_options)
    if action_and_args == :EndTurn
        return nothing
    end
    @warn keys(PLAYER_ACTIONS)
    func = PLAYER_ACTIONS[action_and_args[1]]
    return (game, b, p) -> func(game, b, p, action_and_args[2:end]...)
end

function choose_steal_random_resource(from_player, to_player)
    stolen_good = choose_card_to_steal(from_player)
    input(stdin, "Press Enter when $(to_player.player.team) is ready to see the message")
    @info "$(to_player.player.team) stole $stolen_good from $(from_player.player.team)"
    input(stdin, "Press Enter again when you are ready to hide the message")
    run(`clear`)
    return stolen_good
end

function choose_steal_random_resource(from_player::HumanPlayer, to_player::HumanPlayer)
    stolen_good = choose_card_to_steal(from_player)
    @info "$(to_player.player.team) stole something from $(from_player.player.team)"
    return stolen_good
end

function choose_who_to_trade_with(board, player::HumanPlayer, players)
    parse_team(player.io, "$(join([p.player.team for p in players], ", ")) have accepted. Who do you choose?")
end

function choose_accept_trade(board, player::HumanPlayer, from_player::Player, from_goods, to_goods)
    parse_yesno(player.io, "Does $(player.player.team) want to recieve $from_goods and give $to_goods to $(from_player.team) ?")
end
