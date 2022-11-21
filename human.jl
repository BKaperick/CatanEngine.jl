
get_tile_from_human_tile_description(desc) = Symbol(uppercase(desc))
function get_coords_from_human_tile_description(desc...)
    coords = []
    for d in desc
        push!(coords, get_coord_from_human_tile_description(desc)...)
    end
    return coords
end

function _get_ambiguous_edge_tile(desc)
    freqs = [count(x,desc) for x in desc]
    repeat = get_tile_from_human_tile_description(desc[argmax(freqs)])
    other = get_tile_from_human_tile_description(desc[argmin(freqs)])
    candidates = TILE_TO_ISOLATED_EDGE_COORDS[repeat]
    others = TILE_TO_ISOLATED_EDGE_COORDS[other]
    best = nothing
    min_dist = Inf
    for c in candidates
        d = minimum([ (o[1] - c[1])^2 + (o[2] - c[2])^2 for o in others])
        if d < min_dist
            min_dist = d
            best = c
        end
    end
    return best,repeat,other
end

function _intersect_tiles_string_coords(desc)
    desc = strip(uppercase(desc))
    coords = [TILE_TO_COORDS[Symbol(d)] for d in desc]
    return intersect(coords...)
end

function get_road_coords_from_human_tile_description(desc)
    if length(desc) == 2
        return [_intersect_tiles_string_coords(desc)...]
    elseif length(desc) == 3
        reduc = length(Set(desc))
        if reduc == 2
            coord1,repeat_tile,other_tile = _get_ambiguous_edge_tile(desc)
            edge_intersect = intersect(TILE_TO_EDGE_COORDS[repeat_tile], TILE_TO_EDGE_COORDS[other_tile])
            return [coord1,pop!(edge_intersect)]
        elseif reduc == 1
            tile = get_tile_from_human_tile_description(desc[1]) 
            return [TILE_TO_ISOLATED_EDGE_COORDS[tile]...]
        end
    end
end
function get_coord_from_human_tile_description(desc)
    if length(desc) > 3
        return get_coords_from_human_tile_description(split(desc, " "))
    end
    
    # Single coordinate
    if length(desc) == 3
        reduc = length(Set(desc))
        # repeated letter
        if reduc == 2
            return _get_ambiguous_edge_tile(desc)[1]
        elseif reduc == 1
            return [TILE_TO_ISOLATED_EDGE_COORDS[get_tile_from_human_tile_description(desc[1])]...][1]
        end
        return pop!(_intersect_tiles_string_coords(desc))
    end
end
