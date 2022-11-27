using StatsBase
include("structs.jl")
include("constants.jl")
include("io.jl")
include("api.jl")
include("player_api.jl")
include("game_api.jl")
include("board.jl")
include("draw_board.jl")
include("robo.jl")
#include("action_interface.jl")

API_DICTIONARY = Dict(
                      # Game commands
                      "dd" => _draw_devcard,
                      "ss" => _set_starting_player,
                      "st" => _start_turn,
                      "fp" => _finish_player_turn,
                      "ft" => _finish_turn,

                      # Board commands
                      "bc" => _build_city,
                      "bs" => _build_settlement,
                      "br" => _build_road,
                      "mr" => _move_robber,

                      # Players commands

                      # Player commands
                      "gr" => _give_resource,
                      "tr" => _take_resource,
                      "dc" => _discard_cards,
                      "pd" => _play_devcard,
                      "ad" => _add_devcard,
                      "ap" => _add_port,
                      "la" => _assign_largest_army,
                      "rl" => _remove_largest_army,
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

function can_pay_price(player::Player, cost::Dict)::Bool
    for resource in keys(cost)
        if player.resources[resource] < cost[resource]
            return false
        end
    end
    return true
end
function pay_price(player::Player, cost::Dict)
    resources = keys(cost)
    for (r,amount) in cost
        discard_cards(player, repeat([r], amount)...)
    end
end

function do_play_devcard(board, players, player, card::Union{Nothing,Symbol})
    if card != nothing
        do_devcard_action(board, players, player, card)
        play_devcard(player.player, card)
        assign_largest_army(players)
    end
end

# TODO think about combining with choose_validate_build_X methods.
# For now, we can just keep player input unvalidated to ensure smoother gameplay
function construct_city(board, player::Player, coord)
    pay_construction(player, :City)
    build_city(board, player.team, coord)
end
function construct_settlement(board, player::Player, coord)
    pay_construction(player, :Settlement)
    if haskey(board.coord_to_port, coord)
        add_port(player, board.coord_to_port[coord])
    end
    build_settlement(board, player.team, coord)
end
function construct_road(board, player::Player, coord1, coord2)
    pay_construction(player, :Road)
    build_road(board, player.team, coord1, coord2)
end

function pay_construction(player::Player, construction::Symbol)
    cost = COSTS[construction]
    pay_price(player, cost)
end
function propose_trade_goods(board, players, from_player, amount::Int, resource_symbols...)
    from_goods = resource_symbols[1:amount]
    to_goods = resource_symbols[amount+1:end]
    return propose_trade_goods(board, players, from_player, from_goods, to_goods)
end
function propose_trade_goods(board, players, from_player, from_goods, to_goods)
    accepted = []
    for player in players
        # Don't propose trade to yourself
        if player.player.team == from_player.player.team
            continue
        end
        if choose_accept_trade(board, player, from_player.player, from_goods, to_goods)
            push!(accepted, player)
        end
    end
    if length(accepted) == 0
        return
    end
    to_player_team = choose_who_to_trade_with(board, from_player, accepted)
    to_player = [p for p in accepted if p.player.team == to_player_team][1]
    trade_goods(from_player.player, to_player.player, [from_goods...], [to_goods...])
end


function trade_goods(players, from_player::Player, to_player_team::Symbol, amount::Int, resource_symbols...)
    to_player = [p for p in players if p.player.team == to_player_team]
    from_goods = resource_symbols[1:amount]
    to_goods = resource_symbols[amount+1:end]
    return trade_goods(from_player, to_player, from_goods, to_goods)
end

function trade_goods(from_player::Player, to_player::Player, from_goods::Vector{Symbol}, to_goods::Vector{Symbol})
    for resource in from_goods
        take_resource(from_player, resource)
        give_resource(to_player, resource)
    end
    for resource in to_goods
        take_resource(to_player, resource)
        give_resource(from_player, resource)
    end
end

function harvest_resource(players, building::Building, resource::Symbol)
    player = [p for p in players if p.player.team == building.team][1]
    if building.type == :Settlement
        give_resource(player.player, resource)
    elseif building.type == :City
        give_resource(player.player, resource)
        give_resource(player.player, resource)
    end
end

buildings = Array{Building,1}()

function handle_dice_roll(board::Board, players, player, value)

    # In all cases except 7, we allocate resources
    if value != 7
        for tile in board.dicevalue_to_tiles[value]
            resource = board.tile_to_resource[tile]
            if tile == board.robber_tile
                continue
            end
            for coord in TILE_TO_COORDS[tile]
                if coord in keys(board.coord_to_building)
                    building = board.coord_to_building[coord]
                    harvest_resource(players, building, resource)
                end
            end
        end
    else
        do_robber_move(board, players, player)
    end
end

function do_devcard_action(board, players, player, card::Symbol)
    if card == :Knight
        do_knight_action(board, players, player)
    elseif card == :Monopoly
        do_monopoly_action(board, players, player)
    elseif card == :YearOfPlenty
        do_year_of_plenty_action(board, players, player)
    elseif card == :RoadBuilding
        do_road_building_action(board, players, player)
    end
end

function do_road_building_action(board, players, player)
    choose_validate_build_road(board, players, player, false)
    choose_validate_build_road(board, players, player, false)
end
function do_year_of_plenty_action(board, players, player)
    r1, r2 = choose_year_of_plenty_resources(board, players, player)
    give_resource(player.player, r1)
    give_resource(player.player, r2)
end

function do_monopoly_action(board, players, player)
    res = choose_monopoly_resource(board, players, player)
    for victim in players
        for i in 1:count_resource(victim.player, res)
            take_resource(victim.player, res)
            give_resource(player.player, res)
        end
    end
end

function do_knight_action(board, players, player)
    new_tile = move_robber(board, choose_place_robber(board, players, player))
    potential_victims = get_potential_theft_victims(board, players, player, new_tile)
    if length(potential_victims) > 0
        chosen_victim = choose_robber_victim(board, player, potential_victims...)
        steal_random_resource(chosen_victim, player)
    end
end

function do_robber_move(board, players, player)
    new_tile = move_robber(board, choose_place_robber(board, players, player))
    for p in players
        
        r_count = count_cards(player.player)
        if r_count > 7
            resources_to_discard = choose_cards_to_discard(player, Int(floor(r_count / 2)))
            discard_cards(player.player, resources_to_discard...)
        end
    end  
    potential_victims = get_potential_theft_victims(board, players, player, new_tile)
    if length(potential_victims) > 0
        chosen_victim = choose_robber_victim(board, player, potential_victims...)
        steal_random_resource(chosen_victim, player)
    end
end

function get_admissible_city_locations(board, player::Player)::Vector{Tuple}
    if count_cities(board, player.team) >= MAX_CITY
        return []
    end
    get_settlement_locations(board, player.team)
end

function get_admissible_settlement_locations(board, player::Player, first_turn = false)::Vector{Tuple}
    if count_settlements(board, player.team) >= MAX_SETTLEMENT
        return []
    end
    coords_near_player_road = get_road_locations(board, player.team)
    empty = get_empty_spaces(board)
    if first_turn
        admissible = empty
    else
        admissible = intersect(empty, coords_near_player_road)
    end

    valid = []
    for coord in admissible
        if is_valid_settlement_placement(board, player.team, coord)
            push!(valid, coord)
        end
    end
    return valid
end
function get_admissible_road_locations(board, player::Player, is_first_turn = false)
    if count_roads(board, player.team) >= MAX_ROAD
        return []
    end
    start_coords = []
    coords_near_player_road = get_road_locations(board, player.team)
    coords_near_player_buildings = get_building_locations(board, player.team)

    # This is because on the first turn (placement of first 2 settlements), the second road must be attached to the second
    # settlement
    if is_first_turn
        filter!(c -> !(c in coords_near_player_road), coords_near_player_buildings)
    else 
        append!(start_coords, coords_near_player_road)
    end
    append!(start_coords, coords_near_player_buildings)
    start_coords = Set(unique(start_coords))
    road_coords = []
    for c in start_coords
        ns = get_neighbors(c)
        for n in ns
            if is_valid_road_placement(board, player.team, c, n)
                push!(road_coords, [c,n])
            end
        end
    end
    return road_coords
end

function get_potential_theft_victims(board, players, thief, new_tile)
    potential_victims = []
    for c in [cc for cc in TILE_TO_COORDS[new_tile] if haskey(board.coord_to_building, cc)]
        team = board.coord_to_building[c].team
        victim = [p for p in players if p.player.team == team][1]
        if has_any_resources(victim.player) && (team != thief.player.team)
            @info "vr: $(victim.player.resources)"
            push!(potential_victims, victim)
        end
    end
    return potential_victims
end

function do_turn(game, board, player)
    if can_play_dev_card(player.player)
        devcards = get_admissible_devcards(player.player)
        card = choose_play_devcard(board, game.players, player, devcards)
        do_play_devcard(board, game.players, player, card)
    end
    value = roll_dice(player)
    handle_dice_roll(board, game.players, player, value)
    
    next_action = "tmp"
    while next_action != nothing
        next_action = choose_rest_of_turn(game, board, game.players, player)
        if next_action != nothing
            next_action(game, board)
        end
    end
end

function buy_devcard(game::Game, player::Player)
    card = draw_devcard(game)
    pay_construction(player, :DevelopmentCard)
    add_devcard(player, card)
end

function someone_has_won(game, board, players)::Bool
    return get_winner(game, board, players) != nothing
end
function get_winner(game, board, players)::Union{Nothing,PlayerType}
    board_points = count_victory_points_from_board(board) 
    for player in players
        player_points = get_total_vp_count(board, player.player)
        if player_points >= 10
            @info "WINNER $player_points ($player)"
            print_board(board)
            print_player_stats(game, board, player.player)
            return player
        end
    end
    return nothing
end
function initialize_game(game::Game, csvfile::String, logfile)
    board = read_map(csvfile)
    game, board = load_gamestate(game, board, logfile)
    do_game(game, board)
end
function initialize_game(game::Game, csvfile::String)
    board = read_map(csvfile)
    # print_board(board)
    for (t,r) in board.tile_to_resource
        @debug "$t => $r"
    end

    do_game(game, board)
end

function choose_validate_building(board, players, player, building_type, coord = nothing)
    if building_type == :Settlement
        validation_check = is_valid_settlement_placement
    else
        validation_check = is_valid_city_placement
    end
    while (!validation_check(board, player.player.team, coord))
        coord = choose_building_location(board, players, player, building_type, true)
    end
    return coord
end

function choose_validate_build_settlement(board, players, player)
    coord = choose_validate_building(board, players, player, :Settlement)
    build_settlement(board, player.player.team, coord)
end

function choose_validate_build_city(board, players, player)
    coord = choose_validate_building(board, players, player, :City)
    build_city(board, player.player.team, coord)
end

function choose_validate_build_road(board, players, player, is_first_turn = false)
    road_coord1 = nothing
    road_coord2 = nothing
    while (!is_valid_road_placement(board, player.player.team, road_coord1, road_coord2))
        road_coord = choose_road_location(board, players, player, is_first_turn)
        @debug "road_coord: $road_coord"
        if road_coord == nothing
            print_board(board)
            return
        end
        road_coord1 = road_coord[1]
        road_coord2 = road_coord[2]
    end
    build_road(board, player.player.team, road_coord1, road_coord2)
end

function do_first_turn(game, board, players)
    if !game.first_turn_forward_finished
        do_first_turn_forward(game, board, players)
    end
    do_first_turn_reverse(game, board, players)
end
function do_first_turn_forward(game, board, players)
    for player in get_players_to_play(game)
        choose_validate_build_settlement(board, players, player)
        choose_validate_build_road(board, players, player, true)
        finish_player_turn(game, player.player.team)
    end
    finish_turn(game)
end
function do_first_turn_reverse(game, board, players)
    for player in reverse(get_players_to_play(game))
        settlement = choose_validate_build_settlement(board, players, player)
        choose_validate_build_road(board, players, player, true)
        
        for tile in COORD_TO_TILES[settlement.coord]
            resource = board.tile_to_resource[tile]
            give_resource(player.player, resource)
        end
    end
end

function do_set_turn_order(game)
    if !game.turn_order_set
        out_players = []
        values = []
        for player in game.players
            push!(values, roll_dice(player))
        end

        set_starting_player(game, argmax(values))
    end
end

function do_game(game::Game, board::Board)
    if game.turn_num == 0
        # Here we need to pass the whole game so we can modify the players list order in-place
        do_set_turn_order(game) 
        do_first_turn(game, board, game.players)
    end

    while ~someone_has_won(game, board, game.players)
        
        start_turn(game)
        for player in get_players_to_play(game)
            do_turn(game, board, player)
        end
    end
end

function print_player_stats(game, board, player::Player)
    public_points = get_public_vp_count(board, player)
    total_points = get_total_vp_count(board, player)
    @info "$(player.team) has $total_points points on turn $(game.turn_num) ($public_points points were public)"
    @info "$(count_roads(board, player.team)) roads"
    @info "$(count_settlements(board, player.team)) settlements"
    @info "$(count_cities(board, player.team)) cities"
    if player.has_largest_army
        @info "Largest Army ($(player.dev_cards_used[:Knight]) knights)"
    end
    if player.has_longest_road
        @info "Longest road"
    end
    if get_vp_count_from_dev_cards(player) > 0
        @info "$(get_vp_count_from_dev_cards(player)) points from dev cards"
    end
    @info player
end



