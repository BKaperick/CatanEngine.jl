macro safeparse(ex)
    quote
        try
            xx = $(esc(ex))
        catch e
            if e isa InterruptException || e isa StopException
                throw(e)
            else
                @error "parsing error: $e"
            end

        end
    end
end
function parse_generic(io::IO, descriptor, parsing_func, reminder = nothing)
    x = nothing
    while x == nothing
        if reminder != nothing
            @info reminder
        end
        x = @safeparse parsing_func(io, descriptor)
    end
    return x
end

function input(io::IO, prompt::AbstractString)
    println(prompt)
    response = readline(io)
    if response == "quit"
        close(SAVEFILEIO)
        stop()
    end
    return response
end

parse_teams(io, desc)           = parse_generic(io, desc, _parse_teams)
parse_team(io, desc)            = parse_generic(io, desc, _parse_symbol)
parse_tile(io, desc)            = parse_generic(io, desc, _parse_tile)
parse_yesno(io, desc)           = parse_generic(io, desc, _parse_yesno)
parse_road_coord(io, desc)      = parse_generic(io, desc, _parse_road_coord)
parse_resources_str(io, desc)   = parse_generic(io, desc, _parse_resources_str)
parse_resources(io, desc)       = parse_generic(io, desc, _parse_resources)
parse_devcard(io, desc)         = parse_generic(io, desc, _parse_devcard)
parse_int(io, desc)             = parse_generic(io, desc, _parse_int)
parse_ints(io, desc)            = parse_generic(io, desc, _parse_ints)
parse_action(io, desc)          = parse_generic(io, desc, _parse_action)

_parse_symbol(desc) = _parse_symbol(stdin, desc)
function _parse_symbol(io, desc)
    return Symbol(titlecase(desc))
end

function _parse_tile(io, desc)
    tile = Symbol(titlecase(input(io, desc)))
    if haskey(TILE_TO_COORDS, tile)
        return tile
    else
        return nothing
    end
end

function _parse_yesno(io, desc)
    human_response = lowercase(input(io, desc))
    return human_response[1] == 'y'
end

function _parse_action(io, descriptor)
    human_response = lowercase(input(io, descriptor))
    if (human_response[1] == 'e')
        return (:EndTurn)
    end
    out_str = split(human_response, " ")
    fname = out_str[1]
    
    func = HUMAN_ACTIONS[fname]

    if fname == "bs" || fname == "bc"
        human_coords = out_str[2]
        @info human_coords
        return (func, [get_coord_from_human_tile_description(human_coords)])
    elseif fname == "br"
        human_coords = out_str[2]
        @info human_coords
        @info [get_road_coords_from_human_tile_description(human_coords)]
        return (func, [get_road_coords_from_human_tile_description(human_coords)...])
    elseif fname == "pt" # pt 2 w w g g
        amount_are_mine = parse(Int, out_str[2])
        goods = join(out_str[3:end], " ")
        return (func, [], amount_are_mine, [_parse_resources_str(goods)...])
    elseif fname == "bd"
        return (func, [])
    elseif fname == "pd"
        return (func, [], 0, nothing, _parse_symbol(out_str[2]))
    end

    ArgumentError("\"$human_response\" was not a valid command.")
end

function _parse_teams(io, descriptor)
    human_response = input(io, descriptor)
    return Symbol(String(titlecase(human_response)))
end
function _parse_road_coord(io, descriptor)
    human_response = input(io, descriptor)
    asints = Tuple([tryparse(Int, x) for x in split(human_response, ' ')])
    if all([x == nothing || x == nothing for x in asints])
        roadcoords = get_road_coords_from_human_tile_description(human_response)
        if length(roadcoords) == 0
            throw(KeyError("parse error, road coords not valid"))
        end
        return roadcoords
    end
end

function _parse_int(io, descriptor)
    ints = _parse_ints(io, descriptor)
    return ints[1]
end

function _parse_ints(io, descriptor)
    human_response = input(io, descriptor)
    asints = Tuple([tryparse(Int, x) for x in split(human_response, ' ')])
    if all([x == nothing || x == nothing for x in asints])
        return get_coord_from_human_tile_description(human_response)
    end
    return asints
end

function _parse_devcard(io, descriptor)
    reminder = join(["$k: $v" for (k,v) in HUMAN_DEVCARD_TO_SYMBOL], " ")
    @info "($reminder)"
    dc_response = input(io, descriptor)
    if dc_response in ["", "n", "no"]
        return :nothing
    end
    return HUMAN_DEVCARD_TO_SYMBOL[uppercase(dc_response)]
end

function _parse_resources(io::IO, descriptor::String)
    reminder = join(["$k: $v" for (k,v) in HUMAN_RESOURCE_TO_SYMBOL], " ")
    @info "($reminder)"
    _parse_resources_str(input(io, descriptor))
end

function _parse_resources_str(string_of_resources)
    return Tuple([HUMAN_RESOURCE_TO_SYMBOL[uppercase(String(x))] for x in split(string_of_resources, ' ')])
end

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

function _intersect_tiles_mapping(desc, tile_to_dict)
    desc = strip(uppercase(desc))
    coords = [tile_to_dict[Symbol(d)] for d in desc]
    return intersect(coords...)
end
_intersect_tiles_string_edge_coords(desc) = _intersect_tiles_mapping(desc, TILE_TO_EDGE_COORDS);
_intersect_tiles_string_coords(desc) = _intersect_tiles_mapping(desc, TILE_TO_COORDS);

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
            candidate = _get_ambiguous_edge_tile(desc)
            if length(candidate) < 1
                throw("Coordinate $desc doesn't exist")
            else
                return candidate[1]
            end
        elseif reduc == 1
            candidate = [TILE_TO_ISOLATED_EDGE_COORDS[get_tile_from_human_tile_description(desc[1])]...]
            if length(candidate) < 1
                throw("Coordinate $desc doesn't exist")
            else
                return candidate[1]
            end
        end
        return pop!(_intersect_tiles_string_coords(desc))
    end

    if length(desc) == 2
        return pop!(_intersect_tiles_string_edge_coords(desc))
    end
end
