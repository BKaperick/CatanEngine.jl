using StatsBase
include("structs.jl")
include("constants.jl")
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

function read_map(csvfile)::Board
    # Resource is a value W[ood],S[tone],G[rain],B[rick],P[asture]
    resourcestr_to_symbol = Dict(
                                  "W" => :Wood,
                                  "S" => :Stone,
                                  "G" => :Grain,
                                  "B" => :Brick,
                                  "P" => :Pasture,
                                  "D" => :Desert
                                )
    file_str = read(csvfile, String)
    board_state = [strip(line) for line in split(file_str,'\n') if !isempty(strip(line)) && strip(line)[1] != '#']
    tile_to_dicevalue = Dict()
    tile_to_resource = Dict()
    desert_tile = :Null
    for line in board_state
        tile_str,dice_str,resource_str = split(line,',')
        tile = Symbol(tile_str)
        resource = resourcestr_to_symbol[uppercase(resource_str)]
        dice = parse(Int, dice_str)

        tile_to_dicevalue[tile] = dice
        tile_to_resource[tile] = resource
        if resource == :Desert
            desert_tile = tile
        end
    end
    board = Board(tile_to_dicevalue, tile_to_resource, desert_tile)
    @assert length(keys(board.tile_to_dicevalue)) == length(keys(TILE_TO_COORDS)) # 17
    t = sum(values(board.tile_to_dicevalue))
    @assert sum(values(board.tile_to_dicevalue)) == 133 "Sum of dice values is $(sum(values(board.tile_to_dicevalue))) instead of 133"
    @assert length([r for r in values(board.tile_to_resource) if r == :Wood]) == RESOURCE_TO_COUNT[:Wood]
    @assert length([r for r in values(board.tile_to_resource) if r == :Stone]) == RESOURCE_TO_COUNT[:Stone]
    @assert length([r for r in values(board.tile_to_resource) if r == :Grain]) == RESOURCE_TO_COUNT[:Grain]
    @assert length([r for r in values(board.tile_to_resource) if r == :Brick]) == RESOURCE_TO_COUNT[:Brick]
    @assert length([r for r in values(board.tile_to_resource) if r == :Pasture]) == RESOURCE_TO_COUNT[:Pasture]
    @assert length([r for r in values(board.tile_to_resource) if r == :Desert]) == RESOURCE_TO_COUNT[:Desert]
    return board
end
function harvest_resource(team::Symbol, resource::Symbol, quantity::Int)
    for i in 1:quantity
        harvest_resource(TEAM_TO_PLAYER[team], resource)
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
build_city(buildings, team, coord) = build_building(buildings, team, coord, :City)
build_settlement(buildings, team, coord) = build_building(buildings, team, coord, :Settlement)
function construct_city(buildings, team::Symbol, coord)
    pay_construction(team, :City)
    build_city(buildings, team, coord)
end
function construct_settlement(buildings, team::Symbol, coord)
    pay_construction(team, :Settlement)
    build_settlement(buildings, team, coord)
end

function pay_construction(team::Symbol, construction::Symbol)
    cost = COSTS[construction]
    player = TEAM_TO_PLAYER[team]
    pay_price(player, cost)
end

function build_building(buildings, team::Symbol, coord::Tuple{Int, Int}, type::Symbol)
    city = Building(coord, type)
    push!(buildings, city)
    player = TEAM_TO_PLAYER[team]
    player.vp_count += VP_AWARDS[type]
    return city
end

function build_road(roads, team::Symbol, coord1::Tuple{Int, Int}, coord2::Tuple{Int, Int})
    road = Road(coord1, coord2, team)
    push!(roads, road)
    player = TEAM_TO_PLAYER[team]
    award_longest_road(roads)
    return road
end

function award_longest_road(roads::Array{Road, 1})
    # TODO
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

function do_turn(buildings, team)
    value = human_roll_dice(team)
    roll_dice(buildings, value)
    if team == :Robo
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


function do_first_turn(board)
    for team in TEAMS
        if team != :Robo
            human_build_settlement(board.buildings, team)
            human_build_road(board.roads, team)
        else
            robo_build_settlement(board.buildings, team)
            robo_build_road(board.roads, team)
        end
    end
    for team in reverse(TEAMS)
        if team != :Robo
            settlement = human_build_settlement(board.buildings, team)
            human_build_road(board.roads, team)
        else
            settlement = robo_build_settlement(board.buildings, team)
            robo_build_road(board.roads, team)
        end
        for tile in COORD_TO_TILES[settlement.coord]
            resource = board.tile_to_resource[tile]
            give_resource(TEAM_TO_PLAYER[team], resource)
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
        for team in TEAMS
            do_turn(board.buildings, team)
        end
    end
end
