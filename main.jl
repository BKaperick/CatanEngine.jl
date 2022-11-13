using StatsBase
include("structs.jl")
include("constants.jl")
include("io.jl")
include("api.jl")
include("player_api.jl")
include("board.jl")
include("human.jl")
include("robo.jl")





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

function harvest_resource(player::Player, resource::Symbol, quantity::Int)
    for i in 1:quantity
        harvest_resource(player, resource)
    end
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

# TODO: remove Player from here.  We shouldn't be book-keeping vp points here.  just create a method that takes in board state and players and outputs dict of team -> vp.
# We want build_building to be called by board api that only modifies board state.
function build_building(board, team::Symbol, coord::Tuple{Int, Int}, type::Symbol)
    building = Building(coord, type, team)
    push!(board.buildings, building)
    board.coord_to_building[coord] = building
    return building
end


function harvest_resource(building::Building, resource::Symbol)
    if building.type == :Settlement
        harvest_resource(building.team, resource, 1)
    elseif building.type == :City
        harvest_resource(building.team, resource, 2)
    end
end

function building_gets_resource(building, dice_value, robber_tile::Symbol)::Symbol
    if building.coord == robber_tile
        return Nothing
    end
    tile = COORD_TO_TILES[building.coord]
    if TILE_TO_DICEVAL[tile] == dice_value
        return TILE_TO_RESOURCE[tile]
    end
    return Nothing
end

buildings = Array{Building,1}()

function move_robber(board::Board, coord)
    board.robber_tile = coord
end
function roll_dice(board::Board, value)

    # In all cases except 7, we allocate resources
    if value != 7
        for building in board.buildings
            resource = building_gets_resource(building, value, board.robber_tile)
            harvest_resource(building, resource)
        end
    else
        do_robber_move(board)
    end
end

function get_new_robber_tile(team)::Symbol
    if TEAM_TO_TYPE == :Human
        return human_get_new_robber_tile(team)
    else
        return robo_get_new_robber_tile(team)
    end
end

function do_robber_move(board, team)
    move_robber(board, get_new_robber_tile(team))
    for (t,p) in TEAM_TO_PLAYER
        r_count = Public_Info(p).resource_count
        if r_count > 7
            to_lose = random_sample_resources(p.resources, Int(floor(r_count / 2)))
            for r in to_lose
                p.resources[r] -= 1
            end
        end
    end  
end

function do_turn(buildings, player)
    value = human_roll_dice(player)
    roll_dice(buildings, value)
    if TEAM_TO_TYPE[player.team] == :Robot
    end
end
function someone_has_won()::Bool
    return get_winner() != Nothing
end
function get_winner()#::Union{Player, Nothing}
    for kvp in TEAM_TO_PLAYER
        if kvp[2].vp_count >= 10
            return kvp[1]
        end
    end
    return Nothing
end
function initialize_game(csvfile::String)
    board = read_map(csvfile)
    do_game(board)
end

function do_build_settlement(board, player)
    if TEAM_TO_TYPE[player.team] != :Robot
        human_build_settlement(board, player)
    else
        robo_build_settlement(board, player)
    end
end

function is_valid_building_placement(board, team, coord)::Bool
    return true
    #TODO implement
end

function is_valid_road_placement(board, team, coord1, coord2)::Bool
    return true
    #TODO implement
end

function choose_validate_building(board, players, player, building_type)
    coord = Nothing
    while (!is_valid_building_placement(board, player.team, settlement_coord))
        coord = choose_building_location(board, PLAYERS, player, building_type)
    end
    return coord
end
function choose_validate_build_settlement(board, players, player)
    coord = choose_validate_building(board, players, player, :Settlement)
    build_settlement(board, player.team, coord)
end
function choose_validate_build_city(board, players, player)
    coord = choose_validate_building(board, players, player, :City)
    build_city(board, player.team, coord)
end
function choose_validate_build_road(board, players, player)
    road_coord1 = Nothing
    road_coord2 = Nothing
    while (!is_valid_road_placement(board, player.team, road_coord1, road_coord2))
        road_coord = choose_road_location(board, PLAYERS, player)
        road_coord1 = road_coord[1:2]
        road_coord2 = road_coord[3:4]
    end
    build_road(board, player.team, road_coord1, road_coord2)
end

function do_first_turn(board)
    for player in PLAYERS
        choose_validate_build_settlement(board, players, player)
        choose_validate_build_road(board, players, player)
    end
    for player in reverse(PLAYERS)
        choose_validate_build_settlement(board, players, player)
        choose_validate_build_road(board, players, player)
        
        for tile in COORD_TO_TILES[settlement.coord]
            resource = board.tile_to_resource[tile]
            give_resource(player, resource)
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
function give_resource(player::Player, resource::Symbol)
    if haskey(player.resources, resource)
        player.resources[resource] += 1
    else
        player.resources[resource] = 1
    end
end

function do_game(board::Board)
    do_first_turn(board)
    while someone_has_won() == Nothing
        for player in PLAYERS
            do_turn(board.buildings, player)
        end
    end
end

board = create_board("sample.csv")
build_settlement(board, :Blue, (2,3))
build_road(board, :Blue, (2,3), (2,4))
build_settlement(board, :Green, (6,3))
print_board(board);
