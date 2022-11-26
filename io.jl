using Logging
include("board.jl")

macro safeparse(ex)
    quote
        try
            $(esc(ex))
        catch e
            if e isa InterruptException
                throw(e)
            else
                println("parsing error: $e")
            end

        end
    end
end

function read_map(csvfile)::Board
    # Resource is a value W[ood],S[tone],G[rain],B[rick],P[asture]
    resourcestr_to_symbol = HUMAN_RESOURCE_TO_SYMBOL
    file_str = read(csvfile, String)
    board_state = [strip(line) for line in split(file_str,'\n') if !isempty(strip(line)) && strip(line)[1] != '#']
    tile_to_dicevalue = Dict()
    tile_to_resource = Dict()
    desert_tile = :Null
    ports = Dict()
    for line in board_state
        if count(",", line) == 2
            tile_str,dice_str,resource_str = split(line,',')
            tile = Symbol(tile_str)
            resource = resourcestr_to_symbol[uppercase(resource_str)]
            dice = parse(Int, dice_str)

            tile_to_dicevalue[tile] = dice
            tile_to_resource[tile] = resource
            if resource == :Desert
                desert_tile = tile
            end
        elseif count(",", line) == 1
            println(line)
            port,resource_str = split(line,',')
            portnum = parse(Int,port)
            ports[portnum] = resourcestr_to_symbol[uppercase(resource_str)]
        end
    end
    dicevalue_to_tiles = Dict([v => [] for (k,v) in tile_to_dicevalue])
    for (t,d) in tile_to_dicevalue
        push!(dicevalue_to_tiles[d], t)
    end
    
    coord_to_port = Dict()
    for (c,pnum) in COORD_TO_PORTNUM
        if haskey(ports, pnum)
            coord_to_port[c] = ports[pnum]
        else
            coord_to_port[c] = :All
        end
    end

    println(dicevalue_to_tiles)
    board = Board(tile_to_dicevalue, dicevalue_to_tiles, tile_to_resource, desert_tile, coord_to_port)
    @assert length(keys(board.tile_to_dicevalue)) == length(keys(TILE_TO_COORDS)) # 17
    t = sum(values(board.tile_to_dicevalue))
    @assert sum(values(board.tile_to_dicevalue)) == 133 "Sum of dice values is $(sum(values(board.tile_to_dicevalue))) instead of 133"
    @assert length([r for r in values(board.tile_to_resource) if r == :Wood]) == RESOURCE_TO_COUNT[:Wood]
    @assert length([r for r in values(board.tile_to_resource) if r == :Stone]) == RESOURCE_TO_COUNT[:Stone]
    @assert length([r for r in values(board.tile_to_resource) if r == :Grain]) == RESOURCE_TO_COUNT[:Grain]
    @assert length([r for r in values(board.tile_to_resource) if r == :Brick]) == RESOURCE_TO_COUNT[:Brick]
    @assert length([r for r in values(board.tile_to_resource) if r == :Pasture]) == RESOURCE_TO_COUNT[:Pasture]
    @assert length([r for r in values(board.tile_to_resource) if r == :Desert]) == RESOURCE_TO_COUNT[:Desert]
    return board
end


function print_building(building)
    name = string(string(building.team)[1])
    if building.type == :Settlement
        return lowercase(name)
    else
        return name
    end
end

function print_road(road)
    return lowercase(string(string(road.team)[1]))
end



function serialize_action(fname::String, args...)
    arg_strs = []
    for arg in args
        if typeof(arg) == Symbol
            push!(arg_strs, ":$arg")
        elseif typeof(arg) <: AbstractString
            push!(arg_strs, "\"$arg\"")
        elseif typeof(arg) == Board
            #push!(arg_strs, "board")
        else
            push!(arg_strs, replace(string(arg), " " => ""))
        end
    end
    string("$fname ", join(arg_strs, " "))
end
function log_action(fname::String, args...)
    serialized = serialize_action(fname, args...)
    outstring = string(serialized, "\n")
    println(outstring)
    write(LOGFILEIO, outstring)
    return serialized
end
function log_action(f, expression)
    write(LOGFILEIO, "$(string(expression))\n")
end

function read_action()
end

function execute_api_call(game::Game, board::Board, line::String)
    team_to_player = Dict([p.player.team => p.player for p in game.players])
    values = split(line, " ")
    func_key = values[2]
    println(line)
    api_call = API_DICTIONARY[func_key]

    other_args = [eval(Meta.parse(a)) for a in values[3:end]]
    filter!(x -> x != nothing, other_args)
    if values[1] == "board"
        api_call(board, other_args...)
    elseif values[1] == "game"
        if length(other_args) > 0
            api_call(game, other_args...)
        else
            api_call(game)
        end
    else
        player = team_to_player[eval(Meta.parse(values[1]))]
        api_call(player, other_args...)
    end
end
function load_gamestate(game, board, file)
    for line in readlines(file)
        execute_api_call(game, board, line)
    end
    print_board(board)
    return game, board
end

function input(prompt::String)
    println(prompt)
    response = readline()
    if response == "quit"
        close(LOGFILEIO)
        stop()
    end
    return response
end

stop(text="Stop.") = throw(StopException(text))

struct StopException{T}
    S::T
end

function Base.showerror(io::IO, ex::StopException, bt; backtrace=true)
    Base.with_output_color(get(io, :color, false) ? :green : :nothing, io) do io
        showerror(io, ex.S)
    end
end
function parse_team(desc)
    while true
        return _parse_team(desc)
    end
end
@safeparse function _parse_team(desc)
    return Symbol(titlecase(input(desc)))
end
function parse_yesno(desc)
    while true
        return _parse_yesno(desc)
    end
end
@safeparse function _parse_yesno(desc)
    human_response = lowercase(input(desc))
    return human_response[1] == 'y'
end


function parse_action(player::HumanPlayer, descriptor)
    while true
        return _parse_action(player, descriptor)
    end
end
@safeparse function _parse_action(player::HumanPlayer, descriptor)
    human_response = lowercase(input(descriptor))
    if (human_response[1] == 'e')
        return nothing
    end
    out_str = split(human_response, " ")
    fname = out_str[1]
    
    func = HUMAN_ACTIONS[fname]

    if fname == "bs" || fname == "bc"
        human_coords = out_str[2]
        println(human_coords)
        return (func,player, [get_coord_from_human_tile_description(human_coords)])
    elseif fname == "br"
        human_coords = join(out_str[2:3], " ")
        return (func, player, [get_coords_from_human_tile_description(human_coords)...])
    elseif fname == "pt" # pt 2 w w g g
        amount_are_mine = parse(Int, out_str[2])
        goods = join(out_str[3:end], " ")
        return (func, player, [], amount_are_mine, [_parse_resources_str(goods)...])
    elseif fname == "bd" || fname == "pd"
        return (func, player, [])
    end

    ArgumentError("\"$human_response\" was not a valid command.")
end

@safeparse function _parse_teams(descriptor)
    human_response = input(descriptor)
    return Symbol(String(titlecase(human_response)))
end

function parse_road_coord(descriptor)
    while true
        return _parse_road_coord(descriptor)
    end
end
@safeparse function _parse_road_coord(descriptor)
    human_response = input(descriptor)
    asints = Tuple([tryparse(Int, x) for x in split(human_response, ' ')])
    if all([x == nothing || x == nothing for x in asints])
        return get_road_coords_from_human_tile_description(human_response)
    end
end

function parse_int(descriptor)
    while true
        return _parse_int(descriptor)
    end
end
@safeparse function _parse_int(descriptor)
    ints = _parse_ints(descriptor)
    return ints[1]
end

function parse_ints(descriptor)
    while true
        return _parse_ints(descriptor)
    end
end
@safeparse function _parse_ints(descriptor)
    human_response = input(descriptor)
    asints = Tuple([tryparse(Int, x) for x in split(human_response, ' ')])
    if all([x == nothing || x == nothing for x in asints])
        return get_coord_from_human_tile_description(human_response)
    end
    return asints
end

function parse_devcard(descriptor)
    while true
        _parse_devcard(desriptor)
    end
end
@safeparse function _parse_devcard(descriptor)
    while true
        try
            reminder = join(["$k: $v" for (k,v) in HUMAN_DEVCARD_TO_SYMBOL], " ")
            println("($reminder)")
            dc_response = input(descriptor)
            if dc_response in ["", "n", "no"]
                return nothing
            end
            return HUMAN_DEVCARD_TO_SYMBOL[uppercase(dc_response)]
        catch e
            println("parsing error: $e")
        end
    end
end
function parse_resources(descriptor)
    while true
        return _parse_resources(descriptor)
    end
end
@safeparse function _parse_resources(descriptor)
    reminder = join(["$k: $v" for (k,v) in HUMAN_RESOURCE_TO_SYMBOL], " ")
    println("($reminder)")
    _parse_resources_str(input(descriptor))
end
function parse_resources_str(string_of_resources)
    while true
        return _parse_resources_str(string_of_resources)
    end
end
@safeparse function _parse_resources_str(string_of_resources)
    return Tuple([HUMAN_RESOURCE_TO_SYMBOL[uppercase(String(x))] for x in split(string_of_resources, ' ')])
end

