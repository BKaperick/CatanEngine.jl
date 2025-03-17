"""
This is the API for the board manipulation.  These are the supported functions to manipulate the board state, while leaving the player states untouched.

The human and robot choices about what to place and where are made elsewhere prior to calls to these methods.

It supports 

create_board(csvfile::String)
build_city(board::Board, team::Symbol, coord::Tuple{Int, Int})
build_settlement(board::Board, team::Symbol, coord::Tuple{Int, Int})
build_road(board::Board, team::Symbol, coord1::Tuple{Int, Int}, coord2::Tuple{Int, Int})
count_victory_points_from_board(board)

#TODO move to a separate player api
harvest_resource(board::Board, team::Symbol, resource::Symbol, quantity::Int)
"""

module BoardApi
using ..Catan: Board, Building, Road, log_action, 
MAX_ROAD, MAX_SETTLEMENT, MAX_CITY, DIMS, COORD_TO_TILES, VP_AWARDS
include("../board.jl")

macro api_name(x)
    API_DICTIONARY[string(x)] = x
end

function create_board(csvfile::String)
    read_map(csvfile)
end

function count_settlements(board, team)
    return length(get_settlement_locations(board, team))
end
function count_roads(board, team)
    return length([r for r in board.roads if r.team == team])
end
function count_cities(board, team)
    return length(get_city_locations(board, team))
end

function print_board_stats(board::Board, team::Symbol)
    @info "$(count_roads(board, team)) roads"
    @info "$(count_settlements(board, team)) settlements"
    @info "$(count_cities(board, team)) cities"
end

function get_building_locations(board, team::Symbol)::Vector{Tuple}
    [c for (c,b) in board.coord_to_building if b.team == team]
end

function get_settlement_locations(board, team::Symbol)::Vector{Tuple}
    [c for (c,b) in board.coord_to_building if b.team == team && b.type == :Settlement]
end

function get_city_locations(board, team::Symbol)::Vector{Tuple}
    [c for (c,b) in board.coord_to_building if b.team == team && b.type == :City]
end

function get_road_locations(board, team::Symbol)
    [c for (c,r) in board.coord_to_roads if any([road.team == team for road in r])]
end

function build_city(board::Board, team::Symbol, coord::Tuple{Int, Int})::Building
    log_action("board bc", team, coord)
    @info "$team builds city at intersection of $(join(COORD_TO_TILES[coord], ","))"
    _build_city(board, team, coord)
end
function _build_city(board, team, coord::Tuple{Int, Int})::Building
    
    # Remove current settlement
    current_settlement = nothing
    try
        current_settlement = board.coord_to_building[coord]
    catch e
        throw("$team doesn't have a settlement at this location")
    end    
    filter!(b -> b.coord != current_settlement.coord, board.buildings)

    # Add a city in its place
    city = Building(coord, :City, team)
    push!(board.buildings, city)
    board.coord_to_building[coord] = city
    return city
end

function build_settlement(board::Board, team::Symbol, coord::Union{Nothing, Tuple{Int, Int}})::Building
    log_action("board bs", board, team, coord)
    @info "$team builds settlement at intersection of $(join(COORD_TO_TILES[coord], ","))"
    _build_settlement(board, team, coord)
end
function _build_settlement(board, team, coord::Tuple{Int,Int})::Building
    building = Building(coord, :Settlement, team)
    push!(board.buildings, building)
    board.coord_to_building[coord] = building
    return building
end

function build_road(board::Board, team::Symbol, coord1::Union{Nothing, Tuple{Int, Int}}, coord2::Union{Nothing, Tuple{Int, Int}})::Road
    log_action("board br", board, team, coord1, coord2)
    @info "$team builds road at $(join(intersect(COORD_TO_TILES[coord1],COORD_TO_TILES[coord2]), "-"))"
    _build_road(board, team, coord1, coord2)
end
function _build_road(board, team::Symbol, coord1::Tuple{Int, Int}, coord2::Tuple{Int, Int})::Road
    road = Road(coord1, coord2, team)
    push!(board.roads, road)
    for coord in [coord1, coord2]
        if haskey(board.coord_to_roads, coord)
            push!(board.coord_to_roads[coord], road)
        else
            board.coord_to_roads[coord] = Set([road])
        end
    end
    _award_longest_road(board)
    return road
end

#TODO is this a bug?
#_build_road(board, team, human_coords::String) = _build_settlement(board, team, get_coords_from_human_tile_description(human_coords)...)

function _award_longest_road(board) 
    teams = [Set([r.team for r in board.roads])...]
    team_to_length = Dict{Symbol, Int}()
    max_length = 4
    for team in teams
        current_len = get_max_road_length(board, team)
        max_length = current_len > max_length ? current_len : max_length
        team_to_length[team] = current_len 
    end
    
    # Do nothing if max road length is <= 4
    if max_length == 4
        return
    end
    
    for (team,len) in team_to_length
        if len == max_length
            # If the current longest road holder still has the longest road, he wins (even in case of ties)
            if board.longest_road != nothing && len == team_to_length[board.longest_road]
                return
            else
                board.longest_road = team
                return
            end
        end
    end
end

function get_max_road_length(board, team)
    team_roads = [r for r in board.roads if r.team == team]
    if length(team_roads) == 0
        return 0
    end

    max_length = 0

    coord_to_team_roads = Dict([c => Set([rr for rr in r if rr.team == team]) for (c,r) in board.coord_to_roads])
    @debug coord_to_team_roads
    for current in team_roads

        skip_coords = Set([c for (c,b) in board.coord_to_building if b.team != team])
        roads_seen = Set{Road}()

        # Note that `roads_seen` value updates within the recursived function 
        # are preserved so we won't revisit the existing ones
        len_left = _recursive_roads_skip_coord(roads_seen, current, current.coord1, skip_coords, coord_to_team_roads)
        len_right = _recursive_roads_skip_coord(roads_seen, current, current.coord2, skip_coords, coord_to_team_roads)
        
        # Subtract one since both left and right branch count the current road
        total_length = len_left + len_right - 1

        # Take the max of all road segments calculated for this team
        max_length = total_length > max_length ? total_length : max_length
    end
    return max_length
end

"""
    _recursive_roads_skip_coord(roads_seen::Set{Road}, current::Road, root_coord::Tuple, skip_coords::Set{Tuple{Int64,Int64}}, coord_to_roads)

Returns the length of the longest unexplored branch starting from `root_coord`. 
The length includes the current road, so minimum value is 1.
We stop exploring if we reach a coord in `skip_coords`, which is used to stop counting in the case of intersecting opponent constructions.
"""
function _recursive_roads_skip_coord(roads_seen::Set{Road}, current::Road, root_coord::Tuple, skip_coords, coord_to_roads)
    coord_to_explore = current.coord1 == root_coord ? current.coord2 : current.coord1
    push!(roads_seen, current)

    # setdiff is used handle infinite counting in case of loops 
    roads_to_explore = setdiff(coord_to_roads[coord_to_explore], roads_seen)
    #println("(in recursive call $(length(roads_seen)) $(length(roads_to_explore))")
    
    # Base case - road ends on an opponent's building, or it's a deadend -- count only the current road
    if (coord_to_explore in skip_coords) || (length(roads_to_explore) == 0)
        return 1
    end
    
    max_val = 0
    for road in roads_to_explore
        branch = _recursive_roads_skip_coord(roads_seen, road, coord_to_explore, skip_coords, coord_to_roads)
        max_val = branch > max_val ? branch : max_val
    end
    return 1 + max_val
end

function count_victory_points_from_board(board, team)
    count = 0
    for building in board.buildings
        if building.team == team
            if building.type == :Settlement
                count += VP_AWARDS[:Settlement]
            else
                count += VP_AWARDS[:City]
            end
        end
    end
    if board.longest_road == team
        count += 2
    end
    return count
end

function count_victory_points_from_board(board)
    teams = [Set([b.team for b in board.buildings])...]
    out = Dict()
    for team in teams
        out[team] = count_victory_points_from_board(board, team)
    end
    return out
end

function move_robber(board::Board, tile)
    log_action("board mr", tile)
    _move_robber(board, tile)
end
function _move_robber(board, tile)
    board.robber_tile = tile
end
    



#
# Construction validation
#

"""
    `get_admissible_settlement_locations(board, team::Symbol, first_turn = false)::Vector{Tuple{Int,Int}}`

Returns a vector of all legal locations to place a settlement:
1. Always respect the distance-from-other-buildings rule (most not be neighboring another city or settlement)
2. Must not exceed `MAX_SETTLEMENT`
3. If it's not the first turn, it must be adjacent to a road of the same team
"""
function get_admissible_settlement_locations(board, team::Symbol, first_turn = false)::Vector{Tuple{Int,Int}}

    # Some quick checks to eliminate most spaces
    if count_settlements(board, team) >= MAX_SETTLEMENT
        return []
    end
    coords_near_player_road = get_road_locations(board, team)
    empty = get_empty_spaces(board)
    if first_turn
        admissible = empty
    else
        admissible = intersect(empty, coords_near_player_road)
    end
    
    # More complex check after we've done the first filtration
    return filter(c -> is_valid_settlement_placement(board, team, c, first_turn), admissible)
end

function is_valid_settlement_placement(board, team, coord, is_first_turn::Bool = false)::Bool
    if coord == nothing
        return false
    end
    # 1. There cannot be another building at the same location
    if haskey(board.coord_to_building, coord)
        @debug "[Invalid settlement] 1. There cannot be another settlement at the same location"
        return false
    end
    
    # 2. New building cannot be neighbors of an existing building
    for neigh in get_neighbors(coord)
        if haskey(board.coord_to_building, neigh)
            @debug "[Invalid settlement] 2. New building cannot be neighbors of an existing building"
            return false
        end
    end

    # Last condition does not need to be checked on first turn
    if is_first_turn
        return true
    end

    # 3. New building must be next to a road of the same team
    if haskey(board.coord_to_roads, coord)
        roads = board.coord_to_roads[coord]
        if ~any([r.team == team for r in roads])
            @debug "[Invalid settlement] 3. New building must be next to a road of the same team"
            return false
        end
    end

    return true
end

function is_valid_city_placement(board, team, coord)::Bool
    if coord == nothing
        return false
    end
    
    if haskey(board.coord_to_building, coord)
        existing = board.coord_to_building[coord]
        return existing.team == team && existing.type == :Settlement
    end
    return false
end

function get_admissible_city_locations(board, team::Symbol)::Vector{Tuple{Int,Int}}
    if count_cities(board, team) >= MAX_CITY
        return []
    end
    get_settlement_locations(board, team)
end

function is_valid_road_placement(board, team::Symbol, coord1, coord2)::Bool
    if coord1 == nothing || coord2 == nothing
        return false
    end

    # 1. There cannot be another road at the same location
    if haskey(board.coord_to_roads, coord1)
        if any([(coord2 == road.coord1 || coord2 == road.coord2) for road in board.coord_to_roads[coord1]])
            @debug "[Invalid road] 1. There cannot be another road at the same location"
            return false
        end
    end

    # 2. Must have a neighboring road of same team, without separation by different color building
    found_neighbor = false
    for coord in [coord1, coord2]
        if haskey(board.coord_to_roads, coord)
            for road in board.coord_to_roads[coord]
                if road.team == team
                    if ~haskey(board.coord_to_building, coord) || (board.coord_to_building[coord].team == team)
                        return true
                    end
                end
            end
        end

        # (This condition is only needed on first turn)
        # 3. If no road neighboring, we at least need a building of this team to be adjacent
        if haskey(board.coord_to_building, coord) && board.coord_to_building[coord].team == team
            found_neighbor = true
        end
    end
    if ~found_neighbor
        @debug "[Invalid road] never found a valid neighbor"
    end
    return found_neighbor
end

function get_admissible_road_locations(board::Board, team::Symbol, is_first_turn = false)::Vector{Vector{Tuple{Int,Int}}}
    if count_roads(board, team) >= MAX_ROAD
        return []
    end
    start_coords = []
    coords_near_player_road = get_road_locations(board, team)
    coords_near_player_buildings = get_building_locations(board, team)

    # This is because on the first turn (placement of first 2 settlements), the 
    # second road must be attached to the second settlement
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
            if is_valid_road_placement(board, team, c, n)
                push!(road_coords, [c,n])
            end
        end
    end
    return road_coords
end

function _assign_largest_army(board::Board, team::Union{Symbol, Nothing})
    # Noop if team already has largest army
    if board.largest_army != team && team != nothing
        log_action("board la :$team")
        board.largest_army = team
    end
end

"""
    `get_public_vp_count(board::Board, team::Symbol)::Int`

Returns all victory points publicly-visible for `team`.  I.e. Buildings, 
longest road, and largest army.  (Everything except dev card VPs)
"""
function get_public_vp_count(board::Board, team::Symbol)::Int
    points = BoardApi.count_victory_points_from_board(board, team)
    if board.largest_army == team
        points += 2
    end
    return points
end

end
