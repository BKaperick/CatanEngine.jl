function get_parsed_file_lines(file_str)
    [strip(line) for line in split(file_str,'\n') if !isempty(strip(line)) && strip(line)[1] != '#']
end


function read_player_constructors_from_config(player_configs::Dict)::Vector{Tuple{String, Symbol}}
    players = []
    for (name,configs) in collect(player_configs)
        if ~(configs isa Dict)
            continue
        end
        @debug "$name -> $configs"
        playertype = configs["TYPE"]
        name_sym = Symbol(name)
        @debug "Added player $name_sym of type $playertype"
        player = (playertype, name_sym)
        push!(players, player)
    end
    return players
end
function read_players_from_config(player_configs::Dict)::Vector{PlayerType}
    @debug "starting to read lines"
    players = []
    for (name,configs) in collect(player_configs)
        playertype = configs["TYPE"]
        name_sym = _parse_symbol(name)
        @debug "Added player $name_sym of type $playertype"
        player = eval(Meta.parse("$playertype(:$name_sym, player_configs)"))
        push!(players, player)
    end
    return players
end

function read_map(configs::Dict)::Board
    csvfile = configs["MAP_FILE"]
    # Resource is a value W[ood],S[tone],G[rain],B[rick],P[asture]
    resourcestr_to_symbol = HUMAN_RESOURCE_TO_SYMBOL
    file_str = read(csvfile, String)
    if length(file_str) == 0
        error("Empty file: $file_str")
    end
    board_state = get_parsed_file_lines(file_str)
    if length(board_state) == 0
        error("File contains no uncommented lines: $file_str")
    end
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
            @debug line
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

    @debug dicevalue_to_tiles
    board = Board(tile_to_dicevalue, dicevalue_to_tiles, tile_to_resource, desert_tile, coord_to_port, configs)
    @assert length(keys(board.tile_to_dicevalue)) == length(keys(TILE_TO_COORDS)) # 17
    t = sum(values(board.tile_to_dicevalue))
    @assert sum(values(board.tile_to_dicevalue)) == 133 "Sum of dice values is $(t) instead of 133"
    @assert length([r for r in values(board.tile_to_resource) if r == :Wood]) == RESOURCE_TO_COUNT[:Wood]
    @assert length([r for r in values(board.tile_to_resource) if r == :Stone]) == RESOURCE_TO_COUNT[:Stone]
    @assert length([r for r in values(board.tile_to_resource) if r == :Grain]) == RESOURCE_TO_COUNT[:Grain]
    @assert length([r for r in values(board.tile_to_resource) if r == :Brick]) == RESOURCE_TO_COUNT[:Brick]
    @assert length([r for r in values(board.tile_to_resource) if r == :Pasture]) == RESOURCE_TO_COUNT[:Pasture]
    @assert length([r for r in values(board.tile_to_resource) if r == :Desert]) == RESOURCE_TO_COUNT[:Desert]
    return board
end

"""
Generate a random board conforming to the following constraints:
* RESOURCE_TO_COUNT[resource_symbol] of each

"""
function generate_random_map(fname::String)
    io = open(fname, "w")
    vcat([repeat([string(s)], 5) for s in "abc"]...)
    resource_bag = shuffle!(vcat([repeat([lowercase(string(r)[1])], c) for (r,c) in RESOURCE_TO_COUNT]...))
    dicevalue_bag = shuffle!(vcat([repeat([r], c) for (r,c) in DICEVALUE_TO_COUNT]...))

    for (l,r,d) in zip("ABCDEFGHIJKLMNOPQRS", resource_bag, dicevalue_bag)
        write(io, "$l,$d,$r\n")
    end
    
    ports = shuffle(1:9)[1:5]
    resources = ["p","s","g","w","b"]
    for (p,r) in zip(ports,resources)
        write(io, "$(string(p)),$r\n")
    end

    """
3,p
5,s
6,g
8,w
9,b
   """ 
   close(io)
   return fname
end


function serialize_action(fname::String, args...)
    #println("serializing $fname and $args")
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

function log_action(configs::Dict, fname::String, args...)
    #@debug "logging $fname in $(configs["SAVE_FILE"])"
    serialized = serialize_action(fname, args...)
    outstring = string(serialized, "\n")
    @debug "outstring = $outstring"
    if configs["SAVE_GAME_TO_FILE"]
        write(configs["SAVE_FILE_IO"], outstring)
    end
    return serialized
end

function read_action()
end

function execute_api_call(game::Game, board::Board, line::String)
    # TODO initialize this globally somewhere?  Store in board?
    team_to_player = Dict([p.player.team => p.player for p in game.players])
    @debug "line = $line"
    values = split(line, " ")
    func_key = values[2]
    api_call = API_DICTIONARY[func_key]

    other_args = [eval(Meta.parse(a)) for a in values[3:end]]
    filter!(x -> x != nothing, other_args)
    if values[1] == "board"
        @debug "API: $api_call(board, $(other_args...))"
        api_call(board, other_args...)
    elseif values[1] == "game"
        if length(other_args) > 0
            @debug "API: $api_call(game, $(other_args...))"
            api_call(game, other_args...)
        else
            @debug "API: $api_call(game)"
            api_call(game)
        end
    else
        @debug "values[1] = $(values[1])"
        player = team_to_player[eval(Meta.parse(values[1]))]
        @debug "API: $api_call(player $(values[1]), $(other_args...))" 
        api_call(player, other_args...)
    end
end
function load_gamestate!(game, board)
    file = game.configs["SAVE_FILE"]
    @debug "Loading game from file $file"
    for line in readlines(file)
        execute_api_call(game, board, line)
    end
    if game.configs["PRINT_BOARD"]
        BoardApi.print_board(board)
    end
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
function print_winner(board, winner)
    team = winner.player.team
    println("winner: $(team)")
    println("------------")
    if board.longest_road == team
        println("\tlongest road (2)")
    end
    if board.largest_army == team
        println("\tlargest army (2)")
    end
    if haskey(winner.player.devcards, :VictoryPoint) && winner.player.devcards[:VictoryPoint] > 0
        println("\tvictory point devcards ($(winner.player.devcards[:VictoryPoint]))")
    end
    buildings = [b for b in board.buildings if b.team == team]
    settlements = [b for b in buildings if b.type == :Settlement]
    cities = [b for b in buildings if b.type == :City]
    println("\tsettlements ($(length(settlements)))")
    println("\tcities (2 ⋅$(length(cities)))")
end
function do_post_game_action(game::Game, board::Board, players::Vector{T}, player::T, winner::Union{PlayerType, Nothing}) where T <: PlayerType
end
function do_post_game_action(game::Game, board::Board, players::Vector{T}, winner::Union{PlayerType, Nothing}) where T <: PlayerType
    if winner isa PlayerType
        #print_winner(board, winner)
    end
    for player in players
        do_post_game_action(game, board, players, player, winner)
    end
end

"""
    save_parameters_after_game_end(board::Board, player::PlayerType)

After the game, store or update parameters based on the end state
"""
function save_parameters_after_game_end(file::IO, board::Board, players::Vector{PlayerType}, player::PlayerType, winner_team::Symbol)
end
