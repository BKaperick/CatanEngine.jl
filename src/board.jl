function initialize_empty_board(dimensions)
    spaces = []
    for d in dimensions
        push!(spaces, repeat([nothing], d))
    end
    return spaces
end

#get_empty_spaces(board) = get_empty_spaces!(Vector{Tuple{Int, Int}}(), board)
#empty::Vector{Tuple{Int, Int}}, 
function get_empty_spaces(board)::Vector{Tuple{Int8, Int8}}
    building_coords = keys(board.coord_to_building)

    empty = Vector{Tuple{Int8, Int8}}(undef, sum(DIMS) - length(building_coords))
    
    next_i = Int16(1)

    for (r,row) in enumerate(board.spaces)
        for (c,value) in enumerate(row)
            if value === nothing && !((r,c) in building_coords)
                empty[next_i] = (r,c)
                next_i += 1
            end
        end
    end
    return empty
end

function get_neighbors(coord::Tuple{Int8, Int8})::Vector{Tuple{Int8, Int8}}
    neighbors = Vector{Tuple{Int8, Int8}}(undef, 3)
    i = Int8(1)
    r,c = coord
    if 1 < c
        #push!(neighbors, (r,c-1))
        neighbors[i] = (r,c-1)
        i += 1
    end
    if c < DIMS[r]
        #push!(neighbors, (r,c+1))
        neighbors[i] = (r,c+1)
        i += 1
    end
    if isodd(c)
        if r < length(DIMS)-1
            if DIMS[r]  < DIMS[r+1]
                #push!(neighbors, (r+1,c+1))
                neighbors[i] = (r+1,c+1)
                i += 1
            elseif DIMS[r] == DIMS[r+1]
                #push!(neighbors, (r+1,c))
                neighbors[i] = (r+1,c)
                i += 1
            end
        end
        if r > 1
            if DIMS[r-1]  > DIMS[r]  
                #push!(neighbors, (r-1, c+1))
                neighbors[i] = (r-1, c+1)
                i += 1
            elseif DIMS[r-1] == DIMS[r]  
                #push!(neighbors, (r-1,c))
                neighbors[i] = (r-1,c)
                i += 1
            end
        end
    elseif r > 1 && DIMS[r-1]  < DIMS[r]
        #push!(neighbors, (r-1, c-1))
        neighbors[i] = (r-1, c-1)
        i += 1
    end

    return neighbors[1:i-1]
    #return neighbors
end
