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

function choose_place_robber(board::Board, players::Vector{PlayerType}, player::HumanPlayer)
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
function choose_card_to_steal(player::RobotPlayer)::Symbol
    random_sample_resources(player.player.resources, 1)[1]
end

function choose_play_devcard(board, players, player::HumanPlayer, devcards::Dict)
    p = parse_devcard("Will $(player.player.team) play a devcard before rolling? (Enter to skip):")
    if p == :nothing
        return nothing
    end
end

function choose_next_action(game, board, players, player::HumanPlayer, actions)
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

#function choose_next_action(game, board, players, player::RobotPlayer)
#    actions = values(PLAYER_ACTIONS)
#    for act in actions
#end

function steal_random_resource(from_player, to_player)
    stolen_good = choose_card_to_steal(from_player)
    input("Press Enter when $(to_player.player.team) is ready to see the message")
    @info "$(to_player.player.team) stole $stolen_good from $(from_player.player.team)"
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
