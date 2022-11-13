using Logging

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
#    dicevalue_to_coords = Dict()
#    for (t,d) in tile_to_dicevalue
#        if d in dicevalue_to_coords
#            push!(dicevalue_to_coords[d], TILE_TO_COORDS[t]...)
#        else
#            dicevalue_to_coords[d] = [TILE_TO_COORDS[t]...]
#        end
#    end

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

function log_action(fname::String, args...)
    arg_strs = []
    for arg in args
        if typeof(arg) == Symbol
            push!(arg_strs, ":$arg")
        elseif typeof(arg) == String
            push!(arg_strs, "\"$arg\"")
        elseif typeof(arg) == Board
            #push!(arg_strs, "board")
        else
            push!(arg_strs, replace(string(arg), " " => ""))
        end
    end
    outstring = string("$fname ", join(arg_strs, " "), "\n")
    write(LOGFILEIO, outstring)
end
function log_action(f, expression)
    write(LOGFILEIO, "$(string(expression))\n")
end

function read_action()
end

function load_gamestate(board, players, file)

    team_to_player = Dict([p.player.team => p.player for p in players])
    for line in readlines(file)
        values = split(line, " ")
        func_key = values[2]
        api_call = API_DICTIONARY[func_key]
        println(values)

        other_args = [eval(Meta.parse(a)) for a in values[3:end]]
        println(other_args)
        if values[1] == "board"
            api_call(board, other_args...)
        else
            player = team_to_player[eval(Meta.parse(values[1]))]
            api_call(player, other_args...)
        end
    end
    print_board(board)
    return board
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

