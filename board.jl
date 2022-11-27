
function initialize_empty_board(dimensions)
    spaces = []
    for d in dimensions
        push!(spaces, repeat([nothing], d))
    end
    return spaces
end

function get_empty_spaces(board)
    empty = []
    building_coords = keys(board.coord_to_building)
    for (r,row) in enumerate(board.spaces)
        for (c,value) in enumerate(row)
            if value == nothing && !(value in building_coords)
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
