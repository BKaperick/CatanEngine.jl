
MAIN_DATA_DIR = DATA_DIR
reset_configs("Configuration.toml", @__DIR__)
TEST_DATA_DIR = DATA_DIR
SAVEFILE = joinpath(TEST_DATA_DIR, "_test_save_$(Dates.format(now(), "HHMMSS")).txt")

SAMPLE_MAP = joinpath(MAIN_DATA_DIR, "sample.csv")
# Only difference is some changing of dice values for testing
SAMPLE_MAP_2 = joinpath(MAIN_DATA_DIR, "sample_2.csv")

global counter = 1

function reset_savefile_with_timestamp(name)
    global SAVE_GAME_TO_FILE = true
    savefile = "data/_$(name)_$(Dates.format(now(), "yyyymmdd_HHMMSS"))_$counter.txt"
    global counter += 1
    reset_savefile(savefile)
    return savefile, Catan.SAVEFILEIO
end

function setup_players()
    # Configure players and table configuration
    team_and_playertype = [
                          (:blue, DefaultRobotPlayer),
                          (:cyan, DefaultRobotPlayer),
                          (:green, DefaultRobotPlayer),
                          #(:red, DefaultRobotPlayer)
                          (:red, DefaultRobotPlayer)
    ]
    setup_players(team_and_playertype)
end

function setup_players(team_and_playertype::Vector)
    players = Vector{PlayerType}([player(team) for (team,player) in team_and_playertype])
    return players
end

function setup_and_do_robot_game(savefile::Union{Nothing, String} = nothing)
    players = setup_players()
    setup_and_do_robot_game(players, savefile)
end

function setup_and_do_robot_game(team_and_playertype::Vector, savefile::Union{Nothing, String} = nothing)
    players = setup_players(team_and_playertype)
    return setup_and_do_robot_game(players, savefile)
end

"""
    setup_and_do_robot_game(players::Vector{PlayerType}, savefile::Union{Nothing, String} = nothing)

If no savefile is passed, we use the standard format "test_robot_game_savefile_yyyyMMdd_HHmmss.txt".
If a savefile is passed, we use it to save the game state.  If the file is nonempty, the game will replay
up until the end of the save file and then continue to write ongoing game states to the file.
"""
function setup_and_do_robot_game(players::Vector{PlayerType}, savefile::Union{Nothing, String} = nothing)
    game = Game(players)
    if (savefile == nothing)
        savefile, io = reset_savefile_with_timestamp("test_robot_game_savefile")
    else
        reset_test_savefile(savefile)
    end
    board, winner = GameRunner.initialize_and_do_game!(game, SAMPLE_MAP, savefile)
    return board, game
end

function test_automated_game(neverend, players)
    if neverend
        while true
            # Play the game once
            try
                setup_and_do_robot_game(players)
            catch e
                Base.Filesystem.cp(SAVEFILE, "./data/last_save.txt", force=true)
            end

            # Then immediately try to replay the game from its save file
            println("replaying game from $SAVEFILE")
            try
                setup_and_do_robot_game(players, SAVEFILE)
            catch e
                Base.Filesystem.cp(SAVEFILE, "./data/last_save.txt", force=true)
            end

            # Now move the latest save file to a special `last_save` file for easy retrieval
        end
    else
        setup_and_do_robot_game()
    end
end

function test_player_implementation(T::Type) #where T <: PlayerType
    private_players = [
               T(:Blue),
               DefaultRobotPlayer(:Cyan),
               DefaultRobotPlayer(:Yellow),
               DefaultRobotPlayer(:Red)
              ]

    player = private_players[1]
    players = PlayerPublicView.(private_players)
    game = Game(private_players)
    board = read_map(SAMPLE_MAP)
    from_player = players[2]
    #actions = Catan.ALL_ACTIONS
    actions = Set([PreAction(:BuyDevCard)])

    from_goods = [:Wood]
    to_goods = [:Grain]

    PlayerApi.give_resource!(player.player, :Grain)
    PlayerApi.give_resource!(player.player, :Grain)
    settlement_candidates = BoardApi.get_admissible_settlement_locations(board, player.player.team, true)
    devcards = Dict([:Knight => 2])
    player.player.devcards = devcards

    choose_accept_trade(board, player, from_player, from_goods, to_goods)
    coord = choose_building_location(board, players, player, settlement_candidates, :Settlement)
    BoardApi.build_settlement!(board, player.player.team, coord)
    road_candidates = BoardApi.get_admissible_road_locations(board, player.player.team, false)
    choose_building_location(board, players, player, [coord], :City)
    choose_one_resource_to_discard(board, player)
    choose_monopoly_resource(board, players, player)
    choose_next_action(board, players, player, actions)
    choose_place_robber(board, players, player, BoardApi.get_admissible_robber_tiles(board))
    choose_road_location(board, players, player, road_candidates)
    choose_robber_victim(board, player, players[2], players[3])
    choose_who_to_trade_with(board, player, players)
    choose_resource_to_draw(board, players, player)
    #get_legal_action_functions(board, players, player, actions)
end
