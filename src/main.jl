using StatsBase, DocStringExtensions
#include("structs.jl")
include("constants.jl")
include("io.jl")
include("apis/human_action_interface.jl")
include("players/human_player.jl")
include("players/robot_player.jl")
include("apis/board_api.jl")
include("apis/player_api.jl")
include("apis/game_api.jl")
# include("board.jl")
include("draw_board.jl")
include("random_helper.jl")
import .BoardApi
import .PlayerApi

API_DICTIONARY = Dict(
                      # Game commands
                      "dt" => _reset_dice_true,
                      "df" => _reset_dice_false,
                      "dd" => _draw_devcard,
                      "dr" => _draw_resource,
                      "ss" => _set_starting_player,
                      "st" => _start_turn,
                      "fp" => _finish_player_turn,
                      "ft" => _finish_turn,

                      # Board commands
                      "bc" => BoardApi._build_city!,
                      "bs" => BoardApi._build_settlement!,
                      "br" => BoardApi._build_road!,
                      "mr" => BoardApi._move_robber!,
                      "la" => BoardApi._assign_largest_army!,

                      # Players commands

                      # Player commands
                      "gr" => PlayerApi._give_resource!,
                      "tr" => PlayerApi._take_resource!,
                      "dc" => PlayerApi._discard_cards,
                      "pd" => PlayerApi._play_devcard,
                      "ad" => PlayerApi._add_devcard,
                      "ap" => PlayerApi._add_port
                     )




#function Int turn(Private_Info current_player, List{Public_Info} other_players):
#end

#     *-*-*-*-*-*-*
#     |   |   |   |
#   *-*-*-*-*-*-*-*-*
#   |   |   |   |   |
# *-*-*-*-*-*-*-*-*-*-*
# |   |   |   |   |   |
# *-*-*-*-*-*-*-*-*-*-*
#   |   |   |   |   |
#   *-*-*-*-*-*-*-*-*
#     |   |   |   |
#     *-*-*-*-*-*-*
#
# Coordinate in (row, column)

#       61-62-63-64-65-66-67
#       |  Q  |  R  |  S  |
#    51-52-53-54-55-56-57-58-59
#    |  M  |  N  |  O  |  P  |
# 41-42-43-44-45-46-47-48-49-4!-4@
# |  H  |  I  |  J  |  K  |  L  |
# 31-32-33-34-35-36-37-38-39-3!-3@
#    |  D  |  E  |  F  |  G  |
#    21-22-23-24-25-26-27-28-29
#       |  A  |  B  |  C  |
#       11-12-13-14-15-16-17

function team_with_two_adjacent_roads(roads, coord)::Union{Symbol,Nothing}
    roads = get_adjacent_roads(roads, coord)
    if length(roads) < 2
        return nothing
    end
    for team in TEAMS
        if count([r for r in roads if r.team == team]) >= 2
            return team
        end
    end
    return nothing
end

function get_adjacent_roads(roads, coord)
    adjacent = []
    for road in roads
        if road.coord1 == coord || road.coord2 == coord
            push!(adjacent, road)
        end
    end
    return adjacent
end

function do_play_devcard(board::Board, players, player, card::Union{Nothing,Symbol})
    if card != nothing
        do_devcard_action(board, players, player, card)
        PlayerApi.play_devcard(player.player, card)
        decide_and_assign_largest_army!(board, players)
    end
end

function decide_and_assign_largest_army!(board, players)
    la_team = decide_largest_army(board, players)
    BoardApi.assign_largest_army!(board, la_team)
end

function decide_largest_army(board::Board, players::Vector{PlayerType})::Union{Nothing, Symbol}
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
        return
    end
    
    # Gather those with the max number of knights, as well as the current LargestArmy holder
    admissible = [(p,c) for (p,c) in player_and_count if c == max_ct]
    old_winner = (board.largest_army == nothing) ? nothing : [p.player for p in players if p.player.team == board.largest_army][1]
    
    # Most often there is only one admissible person
    # So we transfer directly to them and exit
    if length(admissible) == 1 
        winner = admissible[1][1].player
        return winner.team
    
    # Don't need to do anything else, as the current holder keeps it, and never should happen that
    # there are multiple, since this assign gets called often enough
    elseif length(admissible) > 1 && old_winner == nothing
        @assert false
    end
end


# TODO think about combining with choose_validate_build_X methods.
# For now, we can just keep player input unvalidated to ensure smoother gameplay
function construct_city(board, player::Player, coord)
    PlayerApi.pay_construction(player, :City)
    BoardApi.build_city!(board, player.team, coord)
end
function construct_settlement(board, player::Player, coord)
    PlayerApi.pay_construction(player, :Settlement)
    if haskey(board.coord_to_port, coord)
        PlayerApi.add_port(player, board.coord_to_port[coord])
    end
    BoardApi.build_settlement!(board, player.team, coord)
end
function construct_road(board, player::Player, coord1, coord2)
    PlayerApi.pay_construction(player, :Road)
    BoardApi.build_road!(board, player.team, coord1, coord2)
end

function propose_trade_goods(board::Board, players::Vector{PlayerType}, from_player::PlayerType, amount::Int, resource_symbols...)
    from_goods = collect(resource_symbols[1:amount])
    to_goods = collect(resource_symbols[amount+1:end])
    return propose_trade_goods(board, players, from_player, from_goods, to_goods)
end
function propose_trade_goods(board::Board, players::Vector{PlayerType}, from_player::PlayerType, from_goods, to_goods)
    to_goods_dict = Dict{Symbol,Int}()
    for g in to_goods
        if haskey(to_goods_dict,g)
            to_goods_dict[g] += 1
        else
            to_goods_dict[g] = 1
        end
    end
    accepted = Vector{Player}()
    accepted_public = Vector{PlayerPublicView}()
    from_player_public = PlayerPublicView(from_player.player)
    for player in players
        # Don't propose trade to yourself
        if player.player.team == from_player.player.team
            continue
        end
        if choose_accept_trade(board, player, from_player_public, from_goods, to_goods)
            @info "$(player.player.team) accepts the trade proposal"
            # We do this after the "choose" step to not leak information from player's hand
            if PlayerApi.has_enough_resources(player.player, to_goods_dict) 
                push!(accepted, player.player)
                push!(accepted_public, PlayerPublicView(player.player))
            end
        end
    end
    if length(accepted) == 0
        @info "Noone accepted"
        return
    end
    to_player_team = choose_who_to_trade_with(board, from_player, accepted_public)
    to_player = [p for p in accepted if p.team == to_player_team][1]
    trade_goods(from_player.player, to_player, [from_goods...], [to_goods...])
end


function trade_goods(players, from_player::Player, to_player_team::Symbol, amount::Int, resource_symbols...)
    to_player = [p for p in players if p.player.team == to_player_team]
    from_goods = resource_symbols[1:amount]
    to_goods = resource_symbols[amount+1:end]
    return trade_goods(from_player, to_player, from_goods, to_goods)
end

function trade_goods(from_player::Player, to_player::Player, from_goods::Vector{Symbol}, to_goods::Vector{Symbol})
    for resource in from_goods
        PlayerApi.take_resource!(from_player, resource)
        PlayerApi.give_resource!(to_player, resource)
    end
    for resource in to_goods
        PlayerApi.take_resource!(to_player, resource)
        PlayerApi.give_resource!(from_player, resource)
    end
end

function harvest_one_resource(game, players, player_and_types::Vector{Tuple{Player, Symbol}}, resource::Symbol)
    total_remaining = game.resources[resource]
    player_and_counts = [(player, t == :Settlement ? 1 : 2) for (player, t) in player_and_types]
    total_needed = sum([x[2] for x in player_and_counts])
    if total_needed == 0
        return
    end
    if total_needed <= total_remaining
        for (player,count) in player_and_counts
            #@info "$(player.team) harvests $count $resource"
            for i=1:count
                PlayerApi.give_resource!(player, resource)
                draw_resource(game, resource)
            end
        end
    else
        # If multiple people harvest, but there aren't enough resources,
        # noone gets any.
        # If only one person needs it, then we give them the rest
        num_teams = length(Set([x[1].team for x in player_and_counts]))
        if num_teams == 1
            player = player_and_counts[1][1]
            @info "$(player.team) harvests $total_needed $resource"
            for i=1:total_remaining
                PlayerApi.give_resource!(player, resource)
                draw_resource(game, resource)
            end
        end
    end
end

function harvest_resources(game, board, players, dice_value)
    # Dict of resource -> (player -> count)
    resource_to_harvest_targets = Dict([(r, Vector{Tuple{Player, Symbol}}()) for r in collect(keys(RESOURCE_TO_COUNT))]) 
    for tile in board.dicevalue_to_tiles[dice_value]
        resource = board.tile_to_resource[tile]
        # Don't harvest Desert, and don't harvest the robber resource
        if tile == board.robber_tile || resource == :Desert
            continue
        end
        for coord in TILE_TO_COORDS[tile]
            if coord in keys(board.coord_to_building)
                building = board.coord_to_building[coord]
                player = [p.player for p in players if p.player.team == building.team][1]
                push!(resource_to_harvest_targets[resource], (player, building.type))
            end
        end
    end
    for r in collect(keys(resource_to_harvest_targets))
        harvest_one_resource(game, players, resource_to_harvest_targets[r], r)
    end
end

buildings = Array{Building,1}()

function handle_dice_roll(game, board::Board, players::Vector{PlayerType}, player::PlayerType, value)
    # In all cases except 7, we allocate resources
    if value != 7
        harvest_resources(game, board, players, value)
    else
        do_robber_move(board, players, player)
    end
    set_dice_true(game)
end

function do_devcard_action(board, players::Vector{PlayerType}, player::PlayerType, card::Symbol)
    players_public = [PlayerPublicView(p) for p in players]
    if card == :Knight
        do_knight_action(board, players, player)
    elseif card == :Monopoly
        do_monopoly_action(board, players, player)
    elseif card == :YearOfPlenty
        do_year_of_plenty_action(board, players_public, player)
    elseif card == :RoadBuilding
        do_road_building_action(board, players_public, player)
    end
end

function do_road_building_action(board, players::Vector{PlayerPublicView}, player::PlayerType)
    choose_validate_build_road!(board, players, player, false)
    choose_validate_build_road!(board, players, player, false)
end
function do_year_of_plenty_action(board, players::Vector{PlayerPublicView}, player::PlayerType)
    r1, r2 = choose_year_of_plenty_resources(board, players, player)
    PlayerApi.give_resource!(player.player, r1)
    PlayerApi.give_resource!(player.player, r2)
end

function do_monopoly_action(board, players::Vector{PlayerType}, player)
    players_public = [PlayerPublicView(p) for p in players]
    res = choose_monopoly_resource(board, players_public, player)
    for victim in players
        @info "$(victim.player.team) gives $(PlayerApi.count_resource(victim.player, res)) $res to $(player.player.team)"
        for i in 1:PlayerApi.count_resource(victim.player, res)
            PlayerApi.take_resource!(victim.player, res)
            PlayerApi.give_resource!(player.player, res)
        end
    end
end

function do_knight_action(board, players::Vector{PlayerType}, player)
    players_public = [PlayerPublicView(p) for p in players]
    new_tile = BoardApi.move_robber!(board, choose_place_robber(board, players_public, player))
    potential_victims = get_potential_theft_victims(board, players, player, new_tile)
    if length(potential_victims) > 0
        chosen_victim = choose_robber_victim(board, player, potential_victims...)
        steal_random_resource(chosen_victim, player)
    end
end

function do_robber_move(board, players::Vector{PlayerType}, player)
    players_public = [PlayerPublicView(p) for p in players]
    new_tile = BoardApi.move_robber!(board, choose_place_robber(board, players_public, player))
    @info "$(player.player.team) moves robber to $new_tile"
    for p in players
        
        r_count = PlayerApi.count_cards(player.player)
        if r_count > 7
            resources_to_discard = choose_cards_to_discard(player, Int(floor(r_count / 2)))
            PlayerApi.discard_cards(player.player, resources_to_discard...)
        end
    end  
    potential_victims = get_potential_theft_victims(board, players, player, new_tile)
    if length(potential_victims) > 0
        chosen_victim = choose_robber_victim(board, player, potential_victims...)
        steal_random_resource(chosen_victim, player)
    end
end

function get_legal_actions(game, board, player)::Set{Symbol}
    actions = Set{Symbol}()
    if PlayerApi.has_enough_resources(player, COSTS[:City]) && length(BoardApi.get_admissible_city_locations(board, player.team)) > 0
        push!(actions, :ConstructCity)
    end
    if PlayerApi.has_enough_resources(player, COSTS[:Settlement]) && length(BoardApi.get_admissible_settlement_locations(board, player.team)) > 0
        push!(actions, :ConstructSettlement)
    end
    if PlayerApi.has_enough_resources(player, COSTS[:Road]) && length(BoardApi.get_admissible_road_locations(board, player.team)) > 0
        push!(actions, :ConstructRoad)
    end
    if PlayerApi.has_enough_resources(player, COSTS[:DevelopmentCard]) && can_draw_devcard(game)
        push!(actions, :BuyDevCard)
    end
    if PlayerApi.can_play_dev_card(player)
        push!(actions, :PlayDevCard)
    end
    if PlayerApi.has_any_resources(player)
        push!(actions, :ProposeTrade)
    end
    return actions
end

function get_potential_theft_victims(board::Board, players::Vector{PlayerType}, thief::PlayerType, new_tile)
    potential_victims = []
    for c in [cc for cc in TILE_TO_COORDS[new_tile] if haskey(board.coord_to_building, cc)]
        team = board.coord_to_building[c].team
        @info [p.player.team for p in players]
        @info team
        victim = [p for p in players if p.player.team == team][1]
        if PlayerApi.has_any_resources(victim.player) && (team != thief.player.team)
            @debug "vr: $(victim.player.resources)"
            push!(potential_victims, victim)
        end
    end
    return potential_victims
end

"""
    `do_turn(game::Game, board::Board, player::PlayerType)`

Called each turn except the first turn.  See `do_first_turn` for first turn behavior.
"""
function do_turn(game::Game, board::Board, player::PlayerType)
    if PlayerApi.can_play_dev_card(player.player)
        devcards = get_admissible_devcards(player)
        card = choose_play_devcard(board, [PlayerPublicView(p) for p in game.players], player, devcards)
        
        do_play_devcard(board, game.players, player, card)
    end
    if !game.rolled_dice_already
        value = roll_dice(player)
        handle_dice_roll(game, board, game.players, player, value)
    end
    
    next_action = "tmp"
    while next_action != nothing
        actions = get_legal_actions(game, board, player.player)

        @debug "actions for $player: $actions"
        if length(actions) == 0
            @info "no legal actions"
            break
        end
        next_action = choose_next_action(board, [PlayerPublicView(p) for p in game.players], player, actions)
        if next_action != nothing
            next_action(game, board, player)
        end
    end
    @debug "setting dice false"
    set_dice_false(game)
    @debug "finishing player turn"
    finish_player_turn(game, player.player.team)
end

function buy_devcard(game::Game, player::Player)
    card = draw_devcard(game)
    PlayerApi.pay_construction(player, :DevelopmentCard)
    PlayerApi.add_devcard(player, card)
end

function someone_has_won(game, board, players::Vector{PlayerType})::Bool
    return get_winner(game, board, players) != nothing
end
function get_winner(game, board, players::Vector{PlayerType})::Union{Nothing,PlayerType}
    winner = nothing
    for player in players
        player_points = get_total_vp_count(board, player.player)
        if player_points >= 10
            @info "WINNER $player_points ($player)"
            if PRINT_BOARD
                print_board(board)
            end
            print_player_stats(game, board, player.player)
            winner = player
        end
    end
    return winner
end

initialize_and_do_game!(game::Game, map_file::String) = initialize_and_do_game!(game, map_file, SAVEFILE)
function initialize_and_do_game!(game::Game, map_file::String, in_progress_game_file)::Tuple{Board, Union{PlayerType, Nothing}}
    board = read_map(map_file)
    if SAVE_GAME_TO_FILE
        load_gamestate!(game, board, in_progress_game_file)
    end
    for p in game.players
        initialize_player(board, p)
    end
    winner = do_game(game, board)
    return board, winner
end

function choose_validate_build_settlement!(board::Board, players::Vector{PlayerPublicView}, player::PlayerType, is_first_turn = false)
    candidates = BoardApi.get_admissible_settlement_locations(board, player.player.team, is_first_turn)
    coord = choose_building_location(board, players, player, candidates, :Settlement)
    if coord != nothing
        BoardApi.build_settlement!(board, player.player.team, coord)
    end
end

function choose_validate_build_city!(board::Board, players::Vector{PlayerPublicView}, player::PlayerType)
    candidates = BoardApi.get_admissible_city_locations(board, player.player.team)
    coord = choose_building_location(board, players, player, candidates, :City)
    if coord != nothing
        BoardApi.build_city!(board, player.player.team, coord)
    end
end

function choose_validate_build_road!(board::Board, players::Vector{PlayerPublicView}, player::PlayerType, is_first_turn = false)
    candidates = BoardApi.get_admissible_road_locations(board, player.player.team, is_first_turn)
    coord = choose_road_location(board, players, player, candidates)
    if coord != nothing
        BoardApi.build_road!(board, player.player.team, coord[1], coord[2])
    end
end

function do_first_turn(game, board::Board, players)
    if !game.first_turn_forward_finished
        do_first_turn_forward(game, board, players)
    end
    do_first_turn_reverse(game, board, players)
end
function do_first_turn_forward(game, board, players)
    for player in get_players_to_play(game)
        # TODO we really only need to re-calculate the player who just played,
        # but we can optimize later if needed
        players_public = [PlayerPublicView(p) for p in players]
        choose_validate_build_settlement!(board, players_public, player, true)
        choose_validate_build_road!(board, players_public, player, true)
        finish_player_turn(game, player.player.team)
    end
    finish_turn(game)
end
function do_first_turn_reverse(game, board, players)
    for player in reverse(get_players_to_play(game))
        players_public = [PlayerPublicView(p) for p in players]
        settlement = choose_validate_build_settlement!(board, players_public, player, true)
        choose_validate_build_road!(board, players_public, player, true)
        
        for tile in COORD_TO_TILES[settlement.coord]
            resource = board.tile_to_resource[tile]
            PlayerApi.give_resource!(player.player, resource)
        end
    end
end

function do_game(game::Game, board::Board)::Union{PlayerType, Nothing}
    if game.turn_num == 0
        # Here we need to pass the whole game so we can modify the players list order in-place
        do_set_turn_order(game) 
        do_first_turn(game, board, game.players)
    end

    while ~someone_has_won(game, board, game.players)
        start_turn(game)

        # We can't just use game.players since we need to handle re-loading from a game paused mid-turn
        for player in get_players_to_play(game)
            do_turn(game, board, player)
        end
        finish_turn(game)

        if game.turn_num >= 5000
            break
        end
    end
    winner = get_winner(game, board, game.players)

    # Post game steps (writing features, updating models, etc)
    do_post_game_action(board, game.players, winner)
    return winner
end

function get_total_vp_count(board, player::Player)
    return BoardApi.get_public_vp_count(board, player.team) + PlayerApi.get_vp_count_from_dev_cards(player)
end

function print_player_stats(game, board, player::Player)
    public_points = BoardApi.get_public_vp_count(board, player.team)
    total_points = get_total_vp_count(board, player)
    @info "$(player.team) has $total_points points on turn $(game.turn_num) ($public_points points were public)"
    BoardApi.print_board_stats(board, player.team)
    if board.largest_army == player.team
        @info "Largest Army ($(player.dev_cards_used[:Knight]) knights)"
    end
    if board.longest_road == player.team
        @info "Longest road"
    end
    if get_vp_count_from_dev_cards(player) > 0
        @info "$(get_vp_count_from_dev_cards(player)) points from dev cards"
    end
    @info player
end

"""
    initialize_player(board::Board, player::PlayerType)

This function is useful to do any one-time computations of the player as soon 
as the board is generated.
"""
function initialize_player(board::Board, player::PlayerType)
end

