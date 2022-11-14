using StatsBase
include("structs.jl")
include("constants.jl")
include("io.jl")
include("api.jl")
include("player_api.jl")
include("board.jl")
include("human.jl")
include("robo.jl")

API_DICTIONARY = Dict(
                      # Board commands
                      "bc" => _build_city,
                      "bs" => _build_settlement,
                      "br" => _build_road,
                      "hr" => _harvest_resource,
                      "mr" => _move_robber,

                      # Players commands
                      "ss" => _set_starting_player,

                      # PlayerType commands
                      "gr" => _give_resource,
                      "tr" => _take_resource,

                      # Player commands
                      "dc" => _discard_cards,


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

function try_construct_settlement(buildings, roads, team::Symbol, coord)::Bool
    player = TEAM_TO_PLAYER[team]
    team_with_roads_through_coord = team_with_two_adjacent_roads(roads, coord) 
    if team_with_roads_through_coord != Nothing && team_with_roads_through_coord != team
        return false
    end
    if !has_enough_resources(player, COSTS[:Settlement])
        return false
    end
    for neigh in get_neighbors(coord)
        if any([b.coord == neigh for b in buildings])
            return false
        end
    end
    construct_settlement(buildings, team, coord)
    return true
end

function try_construct_city(buildings, team::Symbol, coord)::Bool
    player = TEAM_TO_PLAYER[team]
    if !has_enough_resources(player, COSTS[:City])
        return false
    end
    construct_city(buildings, team, coord)
    return true
end

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
    for resource in keys(cost)
        player.resources[resource] -= cost[resource]
    end
end
function construct_city(board, team::Symbol, coord)
    pay_construction(team, :City)
    build_city(board, team, coord)
end
function construct_settlement(board, team::Symbol, coord)
    pay_construction(team, :Settlement)
    build_settlement(board, team, coord)
end

function pay_construction(team::Symbol, construction::Symbol)
    cost = COSTS[construction]
    player = TEAM_TO_PLAYER[team]
    pay_price(player, cost)
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
            discard_cards(player.player, resources_to_discard)
        end
    end  
    potential_victims = get_potential_theft_victims(board, players, player, new_tile)
    if length(potential_victims) > 0
        chosen_victim = choose_robber_victim(board, player, potential_victims...)
        steal_random_resource(player, chosen_victim)
    end
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

function do_turn(board, players, player)
    value = roll_dice(player)
    handle_dice_roll(board, players, player, value)
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
function initialize_game(csvfile::String, players, logfile)
    board = read_map(csvfile)
    board = load_gamestate(board, players, logfile)
    do_game(board, players, false)
end
function initialize_game(csvfile::String, players)
    board = read_map(csvfile)
    do_game(board, players, true)
end

function choose_validate_building(board, players, player, building_type)
    coord = Nothing
    while (!is_valid_building_placement(board, player.player.team, coord))
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

function get_turn_order(players)
    out_players = []
    values = []
    for player in players
        println("$(player.player.team)")
        push!(values, roll_dice(player))
    end

    set_starting_player(players, argmax(values))
end

function do_game(board::Board, players::Vector{PlayerType}, play_first_turn)
    if play_first_turn
        players = get_turn_order(players) 
        do_first_turn(board, players)
    end
    while ~someone_has_won(board, players)
        for player in players
            do_turn(board, players, player)
        end
    end
end

PLAYERS = PLAYERS[sortperm([p.player.team for p in PLAYERS])]

if length(ARGS) > 0
    LOGFILE = ARGS[1]
    LOGFILEIO = open(LOGFILE, "a")
    initialize_game("sample.csv", PLAYERS, LOGFILE)
else
    LOGFILEIO = open(LOGFILE, "a")
    initialize_game("sample.csv", PLAYERS)
end

