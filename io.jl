using Logging
include("board.jl")

function read_map(csvfile)::Board
    # Resource is a value W[ood],S[tone],G[rain],B[rick],P[asture]
    resourcestr_to_symbol = Dict(
                                  "W" => :Wood,
                                  "S" => :Stone,
                                  "G" => :Grain,
                                  "B" => :Brick,
                                  "P" => :Pasture,
                                  "D" => :Desert
                                )
    file_str = read(csvfile, String)
    board_state = [strip(line) for line in split(file_str,'\n') if !isempty(strip(line)) && strip(line)[1] != '#']
    tile_to_dicevalue = Dict()
    tile_to_resource = Dict()
    desert_tile = :Null
    for line in board_state
        tile_str,dice_str,resource_str = split(line,',')
        tile = Symbol(tile_str)
        resource = resourcestr_to_symbol[uppercase(resource_str)]
        dice = parse(Int, dice_str)

        tile_to_dicevalue[tile] = dice
        tile_to_resource[tile] = resource
        if resource == :Desert
            desert_tile = tile
        end
    end
    dicevalue_to_tiles = Dict([v => [] for (k,v) in tile_to_dicevalue])
    for (t,d) in tile_to_dicevalue
        push!(dicevalue_to_tiles[d], t)
    end

    println(dicevalue_to_tiles)
    board = Board(tile_to_dicevalue, dicevalue_to_tiles, tile_to_resource, desert_tile)
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
    values = split(line, " ")
    func_key = values[2]
    println(line)
    api_call = API_DICTIONARY[func_key]

    other_args = [eval(Meta.parse(a)) for a in values[3:end]]
    if values[1] == "board"
        api_call(board, other_args...)
    elseif values[1] == "game"
        api_call(game, other_args...)
    else
        player = team_to_player[eval(Meta.parse(values[1]))]
        api_call(player, other_args...)
    end
end
function load_gamestate(game, board, file)
    team_to_player = Dict([p.player.team => p.player for p in game.players])
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


function _parse_action(team, descriptor)
    human_response = lowercase(input(descriptor))
    if (human_response == "e")
        return Nothing
    end
    out_str = split(human_response, " ")
    fname = out_str[1]
    if fname in BOARD_API
        return log_action("board $fname", team, out_str[2:end]...)
        # board br :Robo (4,4) (4,5)
        # return "board $(out_str[1]) :$team $(join(out_str[2:end], " "))"
    end

    return human_response
end

function _parse_teams(descriptor)
    human_response = input(descriptor)
    return Symbol(String([i == 1 ? uppercase(c) : lowercase(c) for (i, c) in enumerate(human_response)]))
end
function _parse_ints(descriptor)
    human_response = input(descriptor)
    asints = Tuple([tryparse(Int, x) for x in split(human_response, ' ')])
    if all([x == nothing || x == Nothing for x in asints])
        return get_coord_from_human_tile_description(human_response)
    end
    return asints
end

function _parse_devcard(descriptor)
    reminder = join(["$k: $v" for (k,v) in HUMAN_DEVCARD_TO_SYMBOL], " ")
    println("($reminder)")
    dc_response = input(descriptor)
    if dc_response == ""
        return Nothing
    end
    return HUMAN_RESOURCE_TO_SYMBOL[uppercase(dc_response)]
end
function _parse_resources(descriptor)
    reminder = join(["$k: $v" for (k,v) in HUMAN_RESOURCE_TO_SYMBOL], " ")
    println("($reminder)")
    return Tuple([HUMAN_RESOURCE_TO_SYMBOL[uppercase(String(x))] for x in split(input(descriptor), ' ')])
end

