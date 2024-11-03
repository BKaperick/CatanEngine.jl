using Test
#using Dates
#using Logging
#using Catan
#include("../src/constants.jl")
include("../src/main.jl")


SAVEFILE = "data/_test_save_$(Dates.format(now(), "HHMMSS")).txt"
SAVEFILEIO = open(SAVEFILE, "a")
SAVE_GAME_TO_FILE = true
SAMPLE_MAP = "../data/sample.csv"
println(SAVEFILE)

# Reset the one-off test log
io = open("data/oneoff_test_log.txt", "w")
write(io,"")
close(io)

logger_io = open("data/oneoff_test_log.txt","w+")
logger = SimpleLogger(logger_io, Logging.Debug)
global_logger(logger)

global counter = 1

function reset_savefile(file_name)
    global SAVEFILE = file_name
    global SAVEFILEIO = open(SAVEFILE, "a")
    return SAVEFILE, SAVEFILEIO
end
function reset_savefile_with_timestamp(name)
    global SAVEFILE = "data/_$(name)_$(Dates.format(now(), "HHMMSS"))_$counter.txt"
    global counter += 1
    global SAVEFILEIO = open(SAVEFILE, "a")
    return SAVEFILE, SAVEFILEIO
end

function test_actions()
    @test length(keys(PLAYER_ACTIONS)) == 6
end
function test_set_starting_player()
    reset_savefile_with_timestamp("test_set_starting_player")
    team_and_playertype = [
                          (:blue, DefaultRobotPlayer),
                          (:cyan, DefaultRobotPlayer),
                          (:green, DefaultRobotPlayer),
                          (:red, DefaultRobotPlayer)
            ]
    players = Vector{PlayerType}([player(team) for (team,player) in team_and_playertype])
    game = Game(players)

    set_starting_player(game, 2)

    @test game.turn_order_set == true
    @test game.players[1].player.team == :cyan
    @test game.players[2].player.team == :green
    @test game.players[3].player.team == :red
    @test game.players[4].player.team == :blue
    
    flush(SAVEFILEIO)
    board = read_map(SAMPLE_MAP)
    @info "testing logfile $SAVEFILE"
    new_game = Game(players)
    new_game, board = load_gamestate(new_game, board, SAVEFILE)
    
    flush(logger_io)

    @test new_game.turn_order_set == true
    @test new_game.players[2].player.team == :green
    @test new_game.players[3].player.team == :red
    @test new_game.players[4].player.team == :blue
    @test new_game.players[1].player.team == :cyan

    #players: green, red, 
end

function setup_robot_game(savefile = nothing)
    # Configure players and table configuration
    team_and_playertype = [
                          (:blue, DefaultRobotPlayer),
                          (:cyan, DefaultRobotPlayer),
                          (:green, DefaultRobotPlayer),
                          (:red, DefaultRobotPlayer)
            ]
    players = Vector{PlayerType}([player(team) for (team,player) in team_and_playertype])
    game = Game(players)
    if (savefile == nothing)
        reset_savefile_with_timestamp("test_robot_game_savefile")
    else
        reset_savefile(savefile)
    end
    initialize_game(game, SAMPLE_MAP)
    return game
end

@test get_coord_from_human_tile_description("ab") == (1,3)
@test get_coord_from_human_tile_description("bc") == (1,5)
@test get_coord_from_human_tile_description("nqr") == (5,4)
@test get_coord_from_human_tile_description("nqr") == (5,4)
@test get_coord_from_human_tile_description("qqm") == (6,1)
@test get_coord_from_human_tile_description("qqr") == (6,2)
@test get_coord_from_human_tile_description("gcc") == (1,7)
@test get_coord_from_human_tile_description("ada") == (1,1)
@test get_coord_from_human_tile_description("bbb") == (1,4)
@test get_coord_from_human_tile_description("ggg") == (2,9)
@test get_coord_from_human_tile_description("llg") == (3,11)
@test get_coord_from_human_tile_description("klp") == (4,9)
@test get_road_coords_from_human_tile_description("nq") == [(5,3),(5,4)]
@test get_road_coords_from_human_tile_description("jk") == [(3,7),(4,7)]
@test get_road_coords_from_human_tile_description("bf") == [(2,5),(2,6)]
@test get_road_coords_from_human_tile_description("qqr") == [(6,2),(6,3)]
@test get_road_coords_from_human_tile_description("qqm") == [(6,1),(5,2)]
@test get_road_coords_from_human_tile_description("qmq") == [(6,1),(5,2)]
@test get_road_coords_from_human_tile_description("mqq") == [(6,1),(5,2)]
@test get_road_coords_from_human_tile_description("ssp") == [(6,7),(5,8)]
@test get_road_coords_from_human_tile_description("ssr") == [(6,6),(6,5)]
@test get_road_coords_from_human_tile_description("ppl") == [(5,9),(4,10)]
@test get_road_coords_from_human_tile_description("hhd") == [(3,1),(3,2)]
@test get_road_coords_from_human_tile_description("qqq") == [(6,2),(6,1)]
@test get_road_coords_from_human_tile_description("hhh") == [(3,1),(4,1)]
@test get_road_coords_from_human_tile_description("sss") == [(6,7),(6,6)]
@test get_road_coords_from_human_tile_description("lll") == [(3,11),(4,11)]
@test get_road_coords_from_human_tile_description("ccc") == [(1,7),(1,6)]
@test get_road_coords_from_human_tile_description("aaa") == [(1,2),(1,1)]

@assert get_neighbors((3,10)) == Set([(3,9),(3,11),(2,9)])
@assert get_neighbors((6,3)) == Set([(6,2),(6,4),(5,4)])
@assert get_neighbors((1,7)) == Set([(1,6),(2,8)])
@assert get_neighbors((1,7)) == Set([(1,6),(2,8)])

function test_misc()
    random_sample_resources(Dict([:Brick => 0]), 1) == nothing
end

function test_log()
    reset_savefile_with_timestamp("test_log")
    team_and_playertype = [
                          (:blue, DefaultRobotPlayer),
                          (:cyan, DefaultRobotPlayer),
                          (:green, DefaultRobotPlayer),
                          (:red, DefaultRobotPlayer)
            ]
    players = Vector{PlayerType}([player(team) for (team,player) in team_and_playertype])
    game = setup_robot_game()
    flush(SAVEFILEIO)
    board = read_map(SAMPLE_MAP)
    @info "testing savefile $SAVEFILE"
    new_game = Game(players)
    new_game, new_board = load_gamestate(new_game, board, SAVEFILE)
    @test game.devcards == new_game.devcards
    @test game.already_played_this_turn == new_game.already_played_this_turn
    @test game.turn_num == new_game.turn_num
    @test game.turn_order_set == new_game.turn_order_set
    @test game.first_turn_forward_finished == new_game.first_turn_forward_finished
    for (i,playertype) in enumerate(game.players)
        player = playertype.player
        new_player = new_game.players[i].player
        @test player.team == new_player.team
        @test player.resources == new_player.resources
        @test player.vp_count == new_player.vp_count
        @test player.dev_cards == new_player.dev_cards
        @test player.dev_cards_used == new_player.dev_cards_used
        @test player.ports == new_player.ports
        @test player.played_dev_card_this_turn == new_player.played_dev_card_this_turn
        @test player.bought_dev_card_this_turn == new_player.bought_dev_card_this_turn
        @test player.has_largest_army == new_player.has_largest_army
        @test new_board.longest_road == board.longest_road
    end
    rm(SAVEFILE)
end

function test_do_turn()
    board = read_map(SAMPLE_MAP)
    player1 = DefaultRobotPlayer(:Test1)
    player2 = DefaultRobotPlayer(:Test2)
    players = Vector{PlayerType}([player1, player2])
    game = Game(players)
    start_turn(game)
    @test game.turn_num == 1
    do_turn(game, board, player1)
end

function test_robber()
    board = read_map(SAMPLE_MAP)
    player1 = DefaultRobotPlayer(:Test1)
    player2 = DefaultRobotPlayer(:Test2)
    players = Vector{PlayerType}([player1, player2])
    build_settlement(board, :Test1, (1,1))
    build_settlement(board, :Test2, (1,3))

    victims = get_potential_theft_victims(board, players, player1, :A)
    @test length(victims) == 0
    
    victims = get_potential_theft_victims(board, players, player1, :S)
    @test length(victims) == 0

    give_resource(player2.player, :Grain)
    
    victims = get_potential_theft_victims(board, players, player1, :A)
    @test length(victims) == 1
    
    take_resource(player2.player, :Grain)
    
    victims = get_potential_theft_victims(board, players, player1, :A)
    @test length(victims) == 0
end

function test_max_construction()
    board = read_map(SAMPLE_MAP)
    player1 = DefaultRobotPlayer(:Test1)
    for i in 1:(MAX_SETTLEMENT-1)
        build_settlement(board, :Test1, get_admissible_settlement_locations(board, player1.player, true)[1])
    end
    @test length(get_admissible_settlement_locations(board, player1.player, true)) > 0
    build_settlement(board, :Test1, get_admissible_settlement_locations(board, player1.player, true)[1])
    @test length(get_admissible_settlement_locations(board, player1.player, true)) == 0
    @test count_settlements(board, player1.player.team) == MAX_SETTLEMENT
    
    for i in 1:(MAX_CITY-1)
        build_city(board, :Test1, get_admissible_city_locations(board, player1.player)[1])
    end
    @test length(get_admissible_city_locations(board, player1.player)) > 0
    build_city(board, :Test1, get_admissible_city_locations(board, player1.player)[1])
    @test length(get_admissible_city_locations(board, player1.player)) == 0
    @test count_cities(board, player1.player.team) == MAX_CITY
    
    for i in 1:(MAX_ROAD-1)
        coords = get_admissible_road_locations(board, player1.player)[1]
        build_road(board, :Test1, coords...)
    end
    @test length(get_admissible_road_locations(board, player1.player)) > 0
    coords = get_admissible_road_locations(board, player1.player)[1]
    build_road(board, :Test1, coords...)
    @test length(get_admissible_road_locations(board, player1.player)) == 0
    @test count_roads(board, player1.player.team) == MAX_ROAD
end

# API Tests
function test_devcards()
    board = read_map(SAMPLE_MAP)
    player1 = DefaultRobotPlayer(:Test1)
    player2 = DefaultRobotPlayer(:Test2)
    players = Vector{PlayerType}([player1, player2])

    give_resource(player1.player, :Grain)
    give_resource(player1.player, :Stone)
    give_resource(player1.player, :Pasture)
    give_resource(player1.player, :Brick)
    give_resource(player1.player, :Wood)
    
    do_monopoly_action(board, players, player2)
    @test count_resources(player1.player) == 4
    
    players_public = [PlayerPublicView(p) for p in players]
    do_year_of_plenty_action(board, players_public, player1)
    @test count_resources(player1.player) == 6

    build_settlement(board, player1.player.team, (2,5))
    players_public = [PlayerPublicView(p) for p in players]
    do_road_building_action(board, players_public, player1)
    @test count_roads(board, player1.player.team) == 2
    
    players_public = [PlayerPublicView(p) for p in players]
    do_road_building_action(board, players_public, player1)
    @test count_roads(board, player1.player.team) == 4
    
    @test get_total_vp_count(board, player1.player) == 1
    @test get_total_vp_count(board, player2.player) == 0
end

function test_largest_army()
    board = read_map(SAMPLE_MAP)
    player1 = DefaultRobotPlayer(:Test1)
    player2 = DefaultRobotPlayer(:Test2)
    players = Vector{PlayerType}([player1, player2])
    
    add_devcard(player1.player, :Knight)
    add_devcard(player1.player, :Knight)
    add_devcard(player1.player, :Knight)
    
    add_devcard(player2.player, :Knight)
    add_devcard(player2.player, :Knight)
    add_devcard(player2.player, :Knight)
    add_devcard(player2.player, :Knight)
    
    # < 3 knights played, so no largest army assigned
    play_devcard(player1.player, :Knight)
    play_devcard(player1.player, :Knight)
    assign_largest_army(players)
    @test get_total_vp_count(board, player1.player) == 0
    @test get_total_vp_count(board, player1.player) == 0
    
    # Player1 has 3 knights, so he gets 2 points
    play_devcard(player1.player, :Knight)
    assign_largest_army(players)
    @test get_total_vp_count(board, player1.player) == 2
    
    # Player1 has largest army, and Player2 plays 3 knights, so Player 1 keeps LA
    play_devcard(player2.player, :Knight)
    play_devcard(player2.player, :Knight)
    play_devcard(player2.player, :Knight)
    assign_largest_army(players)
    @test get_total_vp_count(board, player1.player) == 2
    @test get_total_vp_count(board, player2.player) == 0
    
    # Player2 plays a 4th knight, successfully stealing the largest army from Player1
    play_devcard(player2.player, :Knight)
    assign_largest_army(players)
    @test get_total_vp_count(board, player1.player) == 0
    @test get_total_vp_count(board, player2.player) == 2
end

function test_longest_road()
    board = read_map(SAMPLE_MAP)
    player_blue = DefaultRobotPlayer(:Blue)
    player_green = DefaultRobotPlayer(:Green)
    players = Vector{PlayerType}([player_blue, player_green])


    # 31-32-33-34-35-36-37-38-39-3!-3@
    # (9)|  D  |  E  |  F  |  G  |
    #    21-22-23-24-25-26-27-28-29
    
    build_settlement(board, :Green, (2,4))
    build_settlement(board, :Blue, (2,3))

    build_road(board, :Blue, (2,3), (2,4))
    build_road(board, :Blue, (2,2), (2,3))
    build_road(board, :Blue, (2,1), (2,2))
    build_road(board, :Blue, (2,1), (3,2))

    @test board.longest_road == nothing
    
    
    # Length 5 road, but it's intersected by :Green settlement
    build_road(board, :Blue, (2,5), (2,4))
    @test board.longest_road == nothing

    # Now player one builds a 5-length road without intersection
    build_road(board, :Blue, (3,3), (3,2))
    @test board.longest_road == :Blue

    build_settlement(board, :Green, (3,10))
    build_road(board, :Green, (3,10), (3,11))
    build_road(board, :Green, (3,10), (3,9))
    build_road(board, :Green, (3,8), (3,9))
    build_road(board, :Green, (3,10), (2,9))
    build_road(board, :Green, (2,9), (2,8))
    build_road(board, :Green, (2,8), (2,7))
    
    # Player green built 6 roads connected, but branched, so still player 1 has longest road
    @test board.longest_road == :Blue
    
    # Now player green makes a loop, allowing 6 roads continuous
    build_road(board, :Green, (3,8), (2,7))
    @test board.longest_road == :Green

    build_settlement(board, :Blue, (5,1))
    build_road(board, :Blue, (5,1), (5,2))
    build_road(board, :Blue, (5,3), (5,2))
    build_road(board, :Blue, (5,3), (5,4))
    
    # Player blue added more roads, but not contiguous, so they don't beat player green
    @test board.longest_road == :Green

    
    # Two settlements
    @test get_total_vp_count(board, player_blue.player) == 2
    # Two settlements + Longest road
    @test get_total_vp_count(board, player_green.player) == 4
end

function test_ports()
    board = read_map(SAMPLE_MAP)
    player1 = DefaultRobotPlayer(:Test1)
    player2 = DefaultRobotPlayer(:Test2)
    @test all([v == 4 for v in values(player1.player.ports)])
    @test length(keys(player1.player.ports)) == 5

    add_port(player1.player, :Grain)

    @test player1.player.ports[:Grain] == 2
    @test player1.player.ports[:Wood] == 4
    
    add_port(player1.player, :All)
    add_port(player2.player, :All)
    
    @test all([v == 3 for v in values(player2.player.ports)])
    @test player1.player.ports[:Grain] == 2
    @test player1.player.ports[:Wood] == 3

    construct_settlement(board, player1.player, (3,2))
    
    @test player1.player.ports[:Brick] == 2
end

function test_human_player()
    board = read_map(SAMPLE_MAP)
    player1 = HumanPlayer(:Test1, open("human_test_player1.txt", "r"))
    player2 = HumanPlayer(:Test2, open("human_test_player2.txt", "r"))
    players = Vector{PlayerType}([player1, player2])
    game = Game(players)
    reset_savefile_with_timestamp("test_human_game")
    initialize_game(game, SAMPLE_MAP)
end

function test_board_api()

    @test length(get_neighbors((3,8))) == 3
    @test length(get_neighbors((3,11))) == 2
    @test length(get_neighbors((4,1))) == 2

    board = read_map(SAMPLE_MAP)
    build_settlement(board, :Test1, (1,1))
    build_road(board, :Test1, (1,1),(1,2))
    @test is_valid_settlement_placement(board, :Test1, (1,2)) == false
    build_settlement(board, :Test1, (1,2))

    build_settlement(board, :Test1, (3,9))
    @test is_valid_settlement_placement(board, :Test1, (4,9)) == false
    @test !((4,9) in get_admissible_settlement_locations(board, Player(:Test1), true))

    @test length(board.buildings) == 3
    @test length(keys(board.coord_to_building)) == 3
    @test count_settlements(board, :Test1) == 3
    @test count_settlements(board, :Test2) == 0

    build_city(board, :Test1, (1,1))
    @test length(board.buildings) == 3
    @test length(keys(board.coord_to_building)) == 3
    @test count_settlements(board, :Test1) == 2
    @test count_cities(board, :Test1) == 1
    @test count_settlements(board, :Test2) == 0
    @test count_victory_points_from_board(board, :Test1) == 4
end

function test_call_api()
    board = read_map(SAMPLE_MAP)
    player1 = DefaultRobotPlayer(:Test1)
    player2 = DefaultRobotPlayer(:Test2)
    players = Vector{PlayerType}([player1, player2])

    @test has_any_resources(player1.player) == false
    @test has_any_resources(player2.player) == false

    give_resource(player1.player, :Grain)

    @test has_any_resources(player1.player) == true

    @test roll_dice(player1) <= 12
    @test roll_dice(player2) >= 2
    
    players_public = [PlayerPublicView(p) for p in players]
    
    # Build first settlement
    loc_settlement = choose_building_location(board, players_public, player1, :Settlement, true)
    @test loc_settlement != nothing
    build_settlement(board, player1.player.team, loc_settlement)
    settlement_locs = get_settlement_locations(board, player1.player.team)
    @test length(settlement_locs) == 1
    
    # Upgrade it to a city
    players_public = [PlayerPublicView(p) for p in players]
    loc_city = choose_building_location(board, players_public, player1, :City)
    build_city(board, player1.player.team, loc_city)
    @test loc_settlement == loc_city
    
    # Build a road attached to first settlement
    players_public = [PlayerPublicView(p) for p in players]
    admissible_roads = get_admissible_road_locations(board, player1.player)
    road_coords = choose_road_location(board, players_public, player1)
    build_road(board, player1.player.team, road_coords[1], road_coords[2])
    @test length(admissible_roads) == length(get_neighbors(loc_settlement))
    @test (road_coords[1] == loc_settlement || road_coords[2] == loc_settlement)
    @test length(get_road_locations(board, player1.player.team)) == 2

    # Build second settlement
    players_public = [PlayerPublicView(p) for p in players]
    loc_settlement = choose_building_location(board, players_public, player1, :Settlement, true)
    @test loc_settlement != nothing
    build_settlement(board, player1.player.team, loc_settlement)
    settlement_locs = get_settlement_locations(board, player1.player.team)
    @test length(settlement_locs) == 1 # City is no longer counted
    
    # Build a road attached to second settlement
    admissible_roads = get_admissible_road_locations(board, player1.player, true)
    players_public = [PlayerPublicView(p) for p in players]
    road_coords = choose_road_location(board, players_public, player1, true)
    if road_coords == nothing
        print_board(board)
    end
    build_road(board, player1.player.team, road_coords[1], road_coords[2])
    @test length(admissible_roads) == length(get_neighbors(loc_settlement))
    @test (road_coords[1] == loc_settlement || road_coords[2] == loc_settlement)

# roll_dice(player::RobotPlayer)::Int
# choose_road_location(board, players, player::RobotPlayer)::Vector{Tuple{Int,Int}}
# choose_building_location(board, players, player::RobotPlayer, building_type)::Tuple{Int, Int}
# choose_cards_to_discard(player::RobotPlayer, amount)
# choose_place_robber(board, players, player::RobotPlayer)
# choose_robber_victim(board, player::RobotPlayer, potential_victims...)::PlayerType
# choose_card_to_steal(player::RobotPlayer)::Symbol
    
end

function run_tests(neverend = false)
    """
    """
    test_actions()
    test_set_starting_player()
    test_log()
    test_misc()
    test_max_construction()
    test_board_api()
    test_largest_army()
    test_ports()
    test_robber()
    test_devcards()
    test_do_turn()
    test_call_api()
    test_longest_road()
    if neverend
        while true
            println("starting game")
            setup_robot_game()
            println("replaying game from $SAVEFILE")
            setup_robot_game(SAVEFILE)
        end
    else
        setup_robot_game()
    end
end

if (length(ARGS) > 0)
    setup_robot_game(ARGS[1])
else
    run_tests(false)
end
#run_tests(false)
