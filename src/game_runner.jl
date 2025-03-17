module GameRunner
using ..Catan: Game, Board, PlayerType, Player, PlayerPublicView,
               read_map, load_gamestate!, initialize_player,
               do_set_turn_order, get_players_to_play, get_admissible_devcards,
               do_first_turn_building!,finish_player_turn,finish_turn,start_turn,set_dice_false,can_draw_devcard,
               choose_play_devcard,do_play_devcard,
               decide_and_roll_dice!,choose_next_action,
               do_post_game_action,
               COORD_TO_TILES, SAVE_GAME_TO_FILE, COSTS
using ..Catan.BoardApi
using ..Catan.PlayerApi

#initialize_and_do_game!(game::Game, map_file::String) = initialize_and_do_game!(game, map_file, SAVEFILE)
function initialize_and_do_game!(game::Game, map_file::String, in_progress_game_file)::Tuple{Board, Union{PlayerType, Nothing}}
    board = read_map(map_file)
    if SAVE_GAME_TO_FILE
        load_gamestate!(game, board, in_progress_game_file)
    end
    for p in game.players
        initialize_player(board, p)
    end
    winner = do_game(game, board)
    return board, winner
end

function do_game(game::Game, board::Board)::Union{PlayerType, Nothing}
    if game.turn_num == 0
        # Here we need to pass the whole game so we can modify the players list order in-place
        do_set_turn_order(game) 
        do_first_turn(game, board, game.players)
    end

    while ~someone_has_won(game, board, game.players)
        start_turn(game)

        # We can't just use game.players since we need to handle re-loading from a game paused mid-turn
        for player in get_players_to_play(game)
            do_turn(game, board, player)
        end
        finish_turn(game)

        if game.turn_num >= 5000
            break
        end
    end
    winner = get_winner(game, board, game.players)

    # Post game steps (writing features, updating models, etc)
    do_post_game_action(board, game.players, winner)
    return winner
end

function do_first_turn(game::Game, board::Board, players)
    if !game.first_turn_forward_finished
        do_first_turn_forward(game, board, players)
    end
    do_first_turn_reverse(game, board, players)
end
function do_first_turn_forward(game, board, players)
    for player in get_players_to_play(game)
        # TODO we really only need to re-calculate the player who just played,
        # but we can optimize later if needed
        players_public = PlayerPublicView.(players)
        do_first_turn_building!(board, players_public, player)
        finish_player_turn(game, player.player.team)
    end
    finish_turn(game)
end
function do_first_turn_reverse(game, board, players)
    for player in reverse(get_players_to_play(game))
        players_public = PlayerPublicView.(players)
        settlement = do_first_turn_building!(board, players_public, player)
        for tile in COORD_TO_TILES[settlement.coord]
            resource = board.tile_to_resource[tile]
            PlayerApi.give_resource!(player.player, resource)
        end
    end
end

"""
    `do_turn(game::Game, board::Board, player::PlayerType)`

Called each turn except the first turn.  See `do_first_turn` for first turn behavior.
"""
function do_turn(game::Game, board::Board, player::PlayerType)
    if PlayerApi.can_play_devcard(player.player)
        devcards = get_admissible_devcards(player)
        card = choose_play_devcard(board, PlayerPublicView.(game.players), player, devcards)
        
        do_play_devcard(board, game.players, player, card)
    end
    decide_and_roll_dice!(game, board, player)
    
    next_action = "tmp"
    while next_action != nothing
        actions = get_legal_actions(game, board, player.player)

        @debug "actions for $player: $actions"
        if length(actions) == 0
            @info "no legal actions"
            break
        end
        next_action = choose_next_action(board, PlayerPublicView.(game.players), player, actions)
        if next_action != nothing
            next_action(game, board, player)
        end
    end
    @debug "setting dice false"
    set_dice_false(game)
    @debug "finishing player turn"
    finish_player_turn(game, player.player.team)
end

function get_legal_actions(game, board, player)::Set{Symbol}
    actions = Set{Symbol}()
    if PlayerApi.has_enough_resources(player, COSTS[:City]) && length(BoardApi.get_admissible_city_locations(board, player.team)) > 0
        push!(actions, :ConstructCity)
    end
    if PlayerApi.has_enough_resources(player, COSTS[:Settlement]) && length(BoardApi.get_admissible_settlement_locations(board, player.team)) > 0
        push!(actions, :ConstructSettlement)
    end
    if PlayerApi.has_enough_resources(player, COSTS[:Road]) && length(BoardApi.get_admissible_road_locations(board, player.team)) > 0
        push!(actions, :ConstructRoad)
    end
    if PlayerApi.has_enough_resources(player, COSTS[:DevelopmentCard]) && can_draw_devcard(game)
        push!(actions, :BuyDevCard)
    end
    if PlayerApi.can_play_devcard(player)
        push!(actions, :PlayDevCard)
    end
    if PlayerApi.has_any_resources(player)
        push!(actions, :ProposeTrade)
    end
    return actions
end

function someone_has_won(game, board, players::Vector{PlayerType})::Bool
    return get_winner(game, board, players) != nothing
end

function get_winner(game, board, players::Vector{PlayerType})::Union{Nothing,PlayerType}
    winner = nothing
    for player in players
        player_points = get_total_vp_count(board, player.player)
        if player_points >= 10
            @info "WINNER $player_points ($player)"
            if PRINT_BOARD
                print_board(board)
            end
            print_player_stats(game, board, player.player)
            winner = player
        end
    end
    return winner
end

function print_player_stats(game, board, player::Player)
    public_points = BoardApi.get_public_vp_count(board, player.team)
    total_points = get_total_vp_count(board, player)
    @info "$(player.team) has $total_points points on turn $(game.turn_num) ($public_points points were public)"
    BoardApi.print_board_stats(board, player.team)
    if board.largest_army == player.team
        @info "Largest Army ($(player.devcards_used[:Knight]) knights)"
    end
    if board.longest_road == player.team
        @info "Longest road"
    end
    if PlayerApi.get_vp_count_from_devcards(player) > 0
        @info "$(PlayerApi.get_vp_count_from_devcards(player)) points from dev cards"
    end
    @info player
end

function get_total_vp_count(board, player::Player)
    return BoardApi.get_public_vp_count(board, player.team) + PlayerApi.get_vp_count_from_devcards(player)
end
end
