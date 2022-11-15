using StatsBase
include("structs.jl")
include("constants.jl")
include("io.jl")
include("api.jl")
include("player_api.jl")
include("game_api.jl")
include("board.jl")
include("human.jl")
include("robo.jl")

API_DICTIONARY = Dict(
                      # Game commands
                      "dd" => _draw_devcard,
                      "ss" => _set_starting_player,

                      # Board commands
                      "bc" => _build_city,
                      "bs" => _build_settlement,
                      "br" => _build_road,
                      "mr" => _move_robber,

                      # Players commands

                      # PlayerType commands
                      "gr" => _give_resource,
                      "tr" => _take_resource,

                      # Player commands
                      "dc" => _discard_cards,
                      "pd" => _play_devcard,
                      "ad" => _add_devcard,


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


function team_with_two_adjacent_roads(roads, coord)
    roads = get_adjacent_roads(roads, coord)
    if length(roads) < 2
        return Nothing
    end
    for team in TEAMS
        if count([r for r in roads if r.team == team]) >= 2
            return team
        end
    end
    return Nothing
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

# TODO think about combining with choose_validate_build_X methods.
# For now, we can just keep player input unvalidated to ensure smoother gameplay
function construct_city(board, player::Player, coord)
    pay_construction(player, :City)
    build_city(board, player.team, coord)
end
function construct_settlement(board, player::Player, coord)
    pay_construction(player, :Settlement)
    build_settlement(board, player.team, coord)
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
        if choose_accept_trade(player, from_player.player, from_goods, to_goods)
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

function do_knight_action(board, players, player)
    move_robber(board, choose_place_robber(board, players, player))
    potential_victims = get_potential_theft_victims(board, players, player, new_tile)
    if length(potential_victims) > 0
        chosen_victim = choose_robber_victim(board, players, player, potential_victims...)
        steal_random_resource(player, chosen_victim)
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
        steal_random_resource(player, chosen_victim)
    end
end

function get_settlement_locations(board, player::Player)::Vector{Tuple}
    [c for (c,b) in board.coord_to_building if b.team == player.team && b.type == :Settlement]
end

function get_admissible_city_locations(board, player::Player)::Vector{Tuple}
    get_settlement_locations(board, player)
end

function get_admissible_settlement_locations(board, player::Player)::Vector{Tuple}
    coords_near_player_road = [c for (c,roads) in board.coord_to_roads if any([r.team == player.team for r in roads])]
    empty = board.empty_spaces
    admissible = intersect(empty, coords_near_player_road)
    valid = []
    for coord in admissible
        if is_valid_settlement_placement(board, team, coord)
            push!(valid, coord)
        end
    end
    return valid
end

function get_potential_theft_victims(board, players, thief, new_tile)
    potential_victims = []
    for c in [cc for cc in TILE_TO_COORDS[new_tile] if haskey(board.coord_to_building, cc)]
        team = board.coord_to_building[c].team
        victim = [p for p in players if p.player.team == team][1]
        if (sum(values(victim.player.resources)) > 0) && (team != thief.player.team)
            push!(potential_victims, victim)
        end
    end
    return potential_victims
end

function do_turn(game, board, player)
    if sum(values(player.player.dev_cards)) > 0
        card = choose_play_devcard(board, game.players, player)
        if card == :Knight
            do_knight_action(board, game.players, player)
        end
        play_devcard(player.player, card)
    end
    value = roll_dice(player)
    handle_dice_roll(board, game.players, player, value)
    
    next_action = "tmp"
    while next_action != Nothing
        next_action = choose_rest_of_turn(board, game.players, player)
        if next_action != Nothing
            next_action(game, board)
        end
    end
end

function buy_devcard(game::Game, player::Player)
    card = draw_devcard(game)
    pay_construction(player, :DevelopmentCard)
    add_devcard(player, card)
end

function someone_has_won(board, players)::Bool
    return get_winner(board, players) != Nothing
end
function get_winner(board, players)#::Union{Player, Nothing}
    board_points = count_victory_points_from_board(board) 
    for player in players
        player_points = player.player.vp_count + board_points[player.player.team]
        if player_points >= 10
            println("WINNER $player_points ($player)")
            return player
        end
    end
    return Nothing
end
function initialize_game(game::Game, csvfile::String, logfile)
    board = read_map(csvfile)
    game, board = load_gamestate(game, board, logfile)
    do_game(game, board, false)
end
function initialize_game(game::Game, csvfile::String)
    board = read_map(csvfile)
    print_board(board)
    for (t,r) in board.tile_to_resource
        println("$t => $r")
    end

    do_game(game, board, true)
end

function choose_validate_building(board, players, player, building_type, coord = Nothing)
    if building_type == :Settlement
        validation_check = is_valid_settlement_placement
    else
        validation_check = is_valid_city_placement
    end
    while (!validation_check(board, player.player.team, coord))
        coord = choose_building_location(board, players, player, building_type)
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

function choose_validate_build_road(board, players, player)
    road_coord1 = Nothing
    road_coord2 = Nothing
    while (!is_valid_road_placement(board, player.player.team, road_coord1, road_coord2))
        road_coord = choose_road_location(board, PLAYERS, player)
        road_coord1 = road_coord[1]
        road_coord2 = road_coord[2]
    end
    build_road(board, player.player.team, road_coord1, road_coord2)
end

function do_first_turn(board, players)
    for player in players
        choose_validate_build_settlement(board, players, player)
        choose_validate_build_road(board, players, player)
    end
    for player in reverse(players)
        settlement = choose_validate_build_settlement(board, players, player)
        choose_validate_build_road(board, players, player)
        
        for tile in COORD_TO_TILES[settlement.coord]
            resource = board.tile_to_resource[tile]
            give_resource(player.player, resource)
        end
    end
end

function do_set_turn_order(game)
    out_players = []
    values = []
    for player in game.players
        push!(values, roll_dice(player))
    end

    set_starting_player(game, argmax(values))
end

function do_game(game::Game, board::Board, play_first_turn)
    if play_first_turn
        # Here we need to pass the whole game so we can modify the players list order in-place
        do_set_turn_order(game) 
        do_first_turn(board, game.players)
    end
    while ~someone_has_won(board, game.players)
        for player in game.players
            do_turn(game, board, player)
        end
    end
end



