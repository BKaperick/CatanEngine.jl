include("board.jl")

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

macro api_name(x)
    API_DICTIONARY[string(x)] = x
end
macro log(x)
    log_action(LOGFILE, x)
end

function create_board(csvfile::String)
    # log_action("board.cb", csvfile)
    read_map(csvfile)
end

function build_building(board, team::Symbol, coord::Tuple{Int, Int}, type::Symbol)
    building = Building(coord, type, team)
    push!(board.buildings, building)
    board.coord_to_building[coord] = building
    return building
end

function build_city(board::Board, team::Symbol, coord::Tuple{Int, Int})
    log_action("board bc", team, coord)
    _build_city(board, team, coord)
end
_build_city(team, coord) = build_building(BOARD, team, coord, :City)

function build_settlement(board::Board, team::Symbol, coord::Union{Nothing, Tuple{Int, Int}})
    log_action("board bs", board, team, coord)
    _build_settlement(board, team, coord)
end
function _build_settlement(board, team, coord)
    build_building(board, team, coord, :Settlement)
end

function build_road(board::Board, team::Symbol, coord1::Union{Nothing, Tuple{Int, Int}}, coord2::Union{Nothing, Tuple{Int, Int}})
    log_action("board br", board, team, coord1, coord2)
    _build_road(board, team, coord1, coord2)
end
function _build_road(board, team::Symbol, coord1::Tuple{Int, Int}, coord2::Tuple{Int, Int})
    road = Road(coord1, coord2, team)
    push!(board.roads, road)
    for coord in [coord1, coord2]
        if haskey(board.coord_to_roads, coord)
            push!(board.coord_to_roads[coord], road)
        else
            board.coord_to_roads[coord] = Set([road])
        end
    end
    _award_longest_road(board.roads)
    return road
end

function _award_longest_road(roads::Array{Road, 1})
    # TODO implement
end

function harvest_resource(board, team::Symbol, resource::Symbol, quantity::Int)
    log_action("board hr", board, team, resource, quantity)
    _harvest_resource(board, team, resource, quantity)
end
_harvest_resource(board::Board, team::Symbol, resource::Symbol, quantity::Int) = harvest_resource(board, TEAM_TO_PLAYER[team], resource, quantity)


function count_victory_points_from_board(board, team)
    count = 0
    for building in board.buildings
        if building.team == team
            if building.type == :Settlement
                count += 1
            else
                count += 2
            end
        end
    end
    return count
end

function count_victory_points_from_board(board)
    out = Dict()
    for team in TEAMS
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
    




# Construction validation

function is_valid_settlement_placement(board, team, coord)::Bool
    if coord == Nothing
        return false
    end
    
    # 1. New building cannot be neighbors of an existing building
    for neigh in get_neighbors(coord)
        if haskey(board.coord_to_building, neigh)
            println("[Invalid settlement] 1. New building cannot be neighbors of an existing building")
            return false
        end
    end

    # 2. New building must be next to a road of the same team
    if haskey(board.coord_to_roads, coord)
        roads = board.coord_to_roads[coord]
        if ~any([r.team == team for r in roads])
            println("[Invalid settlement] 2. New building must be next to a road of the same team")
            return false
        end
    end

    return true
end

function is_valid_city_placement(board, team, coord)::Bool
    if coord == Nothing
        return false
    end
    
    if haskey(board.coord_to_building, coord)
        existing = board.coord_to_building[coord]
        return existing.team == team && existing.type == :Settlement
    end
    return false
end

function is_valid_road_placement(board, team::Symbol, coord1, coord2)::Bool
    if coord1 == Nothing || coord2 == Nothing
        return false
    end

    # 1. There cannot be another road at the same location
    if haskey(board.coord_to_roads, coord1)
        if any([(coord2 == road.coord1 || coord2 == road.coord2) for road in values(board.coord_to_roads)])
            println("[Invalid road] 1. There cannot be another road at the same location")
            return false
        end
    end

    # 2. Must have a neighboring road of same team, without separation by different color building
    found_neighbor = false
    for coord in [coord1, coord2]
        println("$coord, $(haskey(board.coord_to_building, coord)), $team")
        if haskey(board.coord_to_roads, coord)
            for road in values(board.coord_to_roads[coord])
                if road.team == team
                    if ~haskey(board.coord_to_building, coord) || (board.coord_to_building[coord].team == team)
                        return true
                    end
                end
            end
        end

        # 3. If no road neighboring, we at least need a building of this team to be adjacent
        if haskey(board.coord_to_building, coord) && board.coord_to_building[coord].team == team
            found_neighbor = true
        end
    end
    if ~found_neighbor
        println("[Invalid road] never found a valid neighbor")
    end
    return found_neighbor
end

