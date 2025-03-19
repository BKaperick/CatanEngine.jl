
API_DICTIONARY = Dict(
                      # Game commands
                      "dt" => GameApi._reset_dice_true,
                      "df" => GameApi._reset_dice_false,
                      "dd" => GameApi._draw_devcard,
                      "dr" => GameApi._draw_resource,
                      "ss" => GameApi._set_starting_player,
                      "st" => GameApi._start_turn,
                      "fp" => GameApi._finish_player_turn,
                      "ft" => GameApi._finish_turn,

                      # Board commands
                      "bc" => BoardApi._build_city!,
                      "bs" => BoardApi._build_settlement!,
                      "br" => BoardApi._build_road!,
                      "mr" => BoardApi._move_robber!,
                      "la" => BoardApi._assign_largest_army!,

                      # Players commands

                      # Player commands
                      "gr" => PlayerApi._give_resource!,
                      "tr" => PlayerApi._take_resource!,
                      "dc" => PlayerApi._discard_cards!,
                      "pd" => PlayerApi._play_devcard!,
                      "ad" => PlayerApi._add_devcard!,
                      "ap" => PlayerApi._add_port!
                     )




# Coordinate in (row, column)

#       61-62-63-64-65-66-67
#       |  Q  |  R  |  S  |
#    51-52-53-54-55-56-57-58-59
#    |  M  |  N  |  O  |  P  |
# 41-42-43-44-45-46-47-48-49-4!-4@
# |  H  |  I  |  J  |  K  |  L  |
# 31-32-33-34-35-36-37-38-39-3!-3@
#    |  D  |  E  |  F  |  G  |
#    21-22-23-24-25-26-27-28-29
#       |  A  |  B  |  C  |
#       11-12-13-14-15-16-17

function run(args)
    if length(args) >= 1
        CONFIGFILE = args[1]
        PLAYERS = read_players_from_config(CONFIGFILE)
    end
    return run(args, PLAYERS)
end
function run(args, PLAYERS)
    game = nothing
    if length(args) >= 1
        game = Game(PLAYERS)
    end
    if length(args) >= 2
        MAPFILE = args[2]
    else
        MAPFILE = generate_random_map("_temp_map_file.csv")
    end
    if length(args) >= 3
        SAVEFILE = args[3]
        reset_savefile(SAVEFILE)

        if SAVE_GAME_TO_FILE
            global SAVEFILEIO = open(SAVEFILE, "a")
        end
    else
        reset_savefile("./data/savefile.txt")
        io = open(SAVEFILE, "w")
        write(io,"")
        close(io)
        if SAVE_GAME_TO_FILE
            global SAVEFILEIO = open(SAVEFILE, "a")
        end
    end
    #initialize_game(game, "data/sample.csv", SAVEFILE)
    GameRunner.initialize_and_do_game!(game, MAPFILE, SAVEFILE)
end

function run(players::Vector{PlayerType})
    game = Game(players)
    MAPFILE = generate_random_map("_temp_map_file.csv")
    reset_savefile("./data/savefile.txt")
    #SAVEFILE = "./data/savefile.txt"
    #if SAVE_GAME_TO_FILE
    #    global SAVEFILEIO = open(SAVEFILE, "a")
    #end
    GameRunner.initialize_and_do_game!(game, MAPFILE, SAVEFILE)
end

function run(game::Game, map_file::String)
    reset_savefile("./data/savefile.txt")
    GameRunner.initialize_and_do_game!(game, MAPFILE, SAVEFILE)
end


function decide_and_assign_largest_army!(board, players)
    la_team = decide_largest_army(board, players)
    BoardApi.assign_largest_army!(board, la_team)
end

function decide_largest_army(board::Board, players::Vector{PlayerType})::Union{Nothing, Symbol}
    # Gather all players who've played at least three Knights
    max_ct = 3
    player_and_count = Vector{Tuple{PlayerType, Int}}()
    for p in players
        if haskey(p.player.devcards_used, :Knight)
            ct = p.player.devcards_used[:Knight]
            if ct >= 3
                push!(player_and_count, (p, ct))
            end
            if ct > max_ct
                max_ct = ct
            end
        end
    end

    # If noone has crossed threshold, then exit
    if length(player_and_count) == 0
        return
    end
    
    # Gather those with the max number of knights, as well as the current LargestArmy holder
    admissible = [(p,c) for (p,c) in player_and_count if c == max_ct]
    old_winner = (board.largest_army == nothing) ? nothing : [p.player for p in players if p.player.team == board.largest_army][1]
    
    # Most often there is only one admissible person
    # So we transfer directly to them and exit
    if length(admissible) == 1 
        winner = admissible[1][1].player
        return winner.team
    
    # Don't need to do anything else, as the current holder keeps it, and never should happen that
    # there are multiple, since this assign gets called often enough
    elseif length(admissible) > 1 && old_winner == nothing
        @assert false
    end
end

function harvest_one_resource(game, players, player_and_types::Vector{Tuple{Player, Symbol}}, resource::Symbol)
    total_remaining = game.resources[resource]
    player_and_counts = [(player, t == :Settlement ? 1 : 2) for (player, t) in player_and_types]
    total_needed = sum([x[2] for x in player_and_counts])
    if total_needed == 0
        return
    end
    if total_needed <= total_remaining
        for (player,count) in player_and_counts
            #@info "$(player.team) harvests $count $resource"
            for i=1:count
                PlayerApi.give_resource!(player, resource)
                GameApi.draw_resource(game, resource)
            end
        end
    else
        # If multiple people harvest, but there aren't enough resources,
        # noone gets any.
        # If only one person needs it, then we give them the rest
        num_teams = length(Set([x[1].team for x in player_and_counts]))
        if num_teams == 1
            player = player_and_counts[1][1]
            @info "$(player.team) harvests $total_needed $resource"
            for i=1:total_remaining
                PlayerApi.give_resource!(player, resource)
                GameApi.draw_resource(game, resource)
            end
        end
    end
end

function harvest_resources(game, board, players, dice_value)
    # Dict of resource -> (player -> count)
    resource_to_harvest_targets = Dict([(r, Vector{Tuple{Player, Symbol}}()) for r in collect(keys(RESOURCE_TO_COUNT))]) 
    for tile in board.dicevalue_to_tiles[dice_value]
        resource = board.tile_to_resource[tile]
        # Don't harvest Desert, and don't harvest the robber resource
        if tile == board.robber_tile || resource == :Desert
            continue
        end
        for coord in TILE_TO_COORDS[tile]
            if coord in keys(board.coord_to_building)
                building = board.coord_to_building[coord]
                player = [p.player for p in players if p.player.team == building.team][1]
                push!(resource_to_harvest_targets[resource], (player, building.type))
            end
        end
    end
    for r in collect(keys(resource_to_harvest_targets))
        harvest_one_resource(game, players, resource_to_harvest_targets[r], r)
    end
end
function decide_and_roll_dice!(game, board, player::PlayerType)
    if !game.rolled_dice_already
        value = roll_dice(player)
        handle_dice_roll(game, board, game.players, player, value)
    end
end

function handle_dice_roll(game, board::Board, players::Vector{PlayerType}, player::PlayerType, value)
    # In all cases except 7, we allocate resources
    if value != 7
        harvest_resources(game, board, players, value)
    else
        do_robber_move(board, players, player)
    end
    GameApi.set_dice_true(game)
end

function choose_validate_build_settlement!(board::Board, players::Vector{PlayerPublicView}, player::PlayerType, is_first_turn = false)
    candidates = BoardApi.get_admissible_settlement_locations(board, player.player.team, is_first_turn)
    coord = choose_building_location(board, players, player, candidates, :Settlement)
    if coord != nothing
        BoardApi.build_settlement!(board, player.player.team, coord)
    end
end

function choose_validate_build_city!(board::Board, players::Vector{PlayerPublicView}, player::PlayerType)
    candidates = BoardApi.get_admissible_city_locations(board, player.player.team)
    coord = choose_building_location(board, players, player, candidates, :City)
    if coord != nothing
        BoardApi.build_city!(board, player.player.team, coord)
    end
end

function choose_validate_build_road!(board::Board, players::Vector{PlayerPublicView}, player::PlayerType, is_first_turn = false)
    candidates = BoardApi.get_admissible_road_locations(board, player.player.team, is_first_turn)
    coord = choose_road_location(board, players, player, candidates)
    if coord != nothing
        BoardApi.build_road!(board, player.player.team, coord[1], coord[2])
    end
end

function do_first_turn_building!(board, players::Vector{PlayerType}, player::PlayerType)
    players_public = PlayerPublicView.(players)
    settlement = choose_validate_build_settlement!(board, players_public, player, true)
    choose_validate_build_road!(board, players_public, player, true)
    return settlement
end



"""
    initialize_player(board::Board, player::PlayerType)

This function is useful to do any one-time computations of the player as soon 
as the board is generated.
"""
function initialize_player(board::Board, player::PlayerType)
    initialize_player(board, player.player)
end
function initialize_player(board::Board, player::Player)
end
