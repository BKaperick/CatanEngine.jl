mutable struct Board
    tile_to_dicevalue::Dict{Symbol,Int}
    tile_to_resource::Dict{Symbol,Symbol}
    empty_spaces::Vector
    buildings::Array{Building,1}
    roads::Array{Road,1}
    robber_tile::Symbol
end

Board(tile_to_value::Dict, tile_to_resource::Dict, robber_tile::Symbol) = Board(tile_to_value, tile_to_resource, initialize_empty_board(DIMS), [], [], robber_tile)

function initialize_empty_board(dimensions)
    spaces = []
    for d in dimensions
        push!(spaces, repeat([Nothing], d))
    end
    return spaces
end

function get_empty_spaces(board)
    empty = []
    for (r,row) in enumerate(board.empty_spaces)
        for (c,value) in enumerate(row)
            if value == Nothing
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

@assert get_neighbors((3,10)) == Set([(3,9),(3,11),(2,9)])
@assert get_neighbors((6,3)) == Set([(6,2),(6,4),(5,4)])
@assert get_neighbors((1,7)) == Set([(1,6),(2,8)])
@assert get_neighbors((1,7)) == Set([(1,6),(2,8)])
