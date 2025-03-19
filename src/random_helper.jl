function has_any_elements(sym_dict::Dict{Symbol, Int})
    return sum(values(sym_dict)) > 0
end
function random_sample_resources(resources::Dict{Symbol, Int}, count::Int)::Union{Nothing,Vector{Symbol}}
    items = Vector{Symbol}()
    for (r,c) in resources
        if c > 0
            append!(items, repeat([r], c))
        end
    end
    @debug resources
    if length(items) == 0
        return nothing
    end
    return sample(items, count, replace=false)
end

function get_random_tile(board)::Symbol
    candidates = [keys(board.tile_to_dicevalue)...]
    return sample(candidates, 1)[1]
end
function get_random_empty_coord(board)
    return sample(get_empty_spaces(board), 1)[1]
end

function get_random_resource()
    return sample([RESOURCES...])
end
