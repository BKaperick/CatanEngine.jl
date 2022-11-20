mutable struct Board
    tile_to_dicevalue::Dict{Symbol,Int}
    #dicevalue_to_coords::Dict{Symbol,Int}
    dicevalue_to_tiles::Dict{Int,Vector{Symbol}}
    tile_to_resource::Dict{Symbol,Symbol}
    coord_to_building::Dict{Tuple,Building}
    coord_to_roads::Dict{Tuple,Set{Road}}
    coord_to_port::Dict{Tuple,Symbol}
    empty_spaces::Vector
    buildings::Array{Building,1}
    roads::Array{Road,1}
    robber_tile::Symbol
    spaces::Vector
end

Board(tile_to_value::Dict, dicevalue_to_tiles::Dict, tile_to_resource::Dict, robber_tile::Symbol, coord_to_port::Dict) = Board(tile_to_value, dicevalue_to_tiles, tile_to_resource, Dict(), Dict(), coord_to_port, initialize_empty_board(DIMS), [], [], robber_tile, initialize_empty_board(DIMS))

function initialize_empty_board(dimensions)
    spaces = []
    for d in dimensions
        push!(spaces, repeat([Nothing], d))
    end
    return spaces
end

function get_empty_spaces(board)
    empty = []
    building_coords = keys(board.coord_to_building)
    for (r,row) in enumerate(board.spaces)
        for (c,value) in enumerate(row)
            if value == Nothing && ~(value in building_coords)
                push!(empty, (r,c))
            end
        end
    end
    return empty
end
function get_neighbors(coord)
    neighbors = []
    r,c = coord
    if 1 < c
        push!(neighbors, (r,c-1))
    end
    if c < DIMS[r]
        push!(neighbors, (r,c+1))
    end
    if isodd(c)
        if r < length(DIMS)-1
            if DIMS[r]  < DIMS[r+1]
                push!(neighbors, (r+1,c+1))
            elseif DIMS[r] == DIMS[r+1]
                push!(neighbors, (r+1,c))
            end
        elseif r > 1
            if DIMS[r-1]  > DIMS[r]  
                push!(neighbors, (r-1, c+1))
            elseif DIMS[r-1] == DIMS[r]  
                push!(neighbors, (r-1,c))
            end
        end
    elseif r > 1 && DIMS[r-1]  < DIMS[r]
        push!(neighbors, (r-1, c-1))
    end
    return Set(neighbors)
end
