function random_sample_resources(resources::Dict{Symbol, Int}, count::Int)
    items = []
    for (r,c) in resources
        append!(items, repeate([r], c))
    end
    return sample(items, count, replace=false)
end

function get_random_tile()::Symbol
    return sample(TILES, 1)[1]
end
function get_random_empty_coord(board)
    return sample(get_empty_spaces(board), 1)[1]
end
function robo_get_new_robber_tile(team)::Symbol
    return get_random_tile()
end
