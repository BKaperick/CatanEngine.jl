function initialize_empty_board()::Vector{Vector{Bool}}
    #spaces = SVector{DIMS_ROWS, SVector{DIMS_COLS, Bool}}()
    #spaces = SVector{DIMS_ROWS, Vector{DIMS_COLS, Bool}}()
    spaces = []
    for d in DIMS
        push!(spaces, repeat([false], d))
    end
    return spaces
end

function get_empty_spaces(board)::Vector{Tuple{Int8, Int8}}
    empty = Vector{Tuple{Int8, Int8}}(undef, sum(DIMS)) # - length(building_coords))
    
    next_i = Int16(0)

    for (r,row) in enumerate(board.spaces)
        for (c,value) in enumerate(row)
            if !value
                next_i += 1
                empty[next_i] = (r,c)
            end
        end
    end
    return empty[1:next_i]
end

function get_neighbors(coord::Tuple{Integer, Integer})::Vector{Tuple{Int8, Int8}}
    neighbors = Vector{Tuple{Int8, Int8}}(undef, 3)
    i = Int8(1)
    r,c = coord
    if 1 < c
        neighbors[i] = (r,c-1)
        i += 1
    end
    if c < DIMS[r]
        neighbors[i] = (r,c+1)
        i += 1
    end
    if isodd(c)
        if r < length(DIMS)-1
            if DIMS[r]  < DIMS[r+1]
                neighbors[i] = (r+1,c+1)
                i += 1
            elseif DIMS[r] == DIMS[r+1]
                neighbors[i] = (r+1,c)
                i += 1
            end
        end
        if r > 1
            if DIMS[r-1]  > DIMS[r]  
                neighbors[i] = (r-1, c+1)
                i += 1
            elseif DIMS[r-1] == DIMS[r]  
                neighbors[i] = (r-1,c)
                i += 1
            end
        end
    elseif r > 1 && DIMS[r-1]  < DIMS[r]
        neighbors[i] = (r-1, c-1)
        i += 1
    end

    return neighbors[1:i-1]
end
