using Test
using Dates
using Logging
#using Catan
#include("../src/Catan.jl")
#include("../src/main.jl")
using Catan
using Catan: 
get_coord_from_human_tile_description,
get_road_coords_from_human_tile_description,
read_map,
load_gamestate!,
reset_savefile,
random_sample_resources,
decide_and_assign_largest_army!,
get_admissible_theft_victims,
choose_road_location,
choose_validate_build_settlement!,
choose_validate_build_city!,
choose_validate_build_road!,
do_monopoly_action,
harvest_resources,
roll_dice,
#get_legal_action_functions,
PLAYER_ACTIONS,
MAX_SETTLEMENT,
MAX_CITY,
MAX_ROAD,
TEST_DATA_DIR,
MAIN_DATA_DIR,
setup_players,
setup_and_do_robot_game,
test_automated_game,
reset_savefile_with_timestamp,
SAVEFILE

reset_savefile(SAVEFILE)

Catan.SAVE_GAME_TO_FILE = true
println(SAVEFILE)

SAMPLE_MAP = "$(MAIN_DATA_DIR)sample.csv"
# Only difference is some changing of dice values for testing
SAMPLE_MAP_2 = "$(MAIN_DATA_DIR)sample_2.csv"

# Reset the one-off test log
io = open("$(TEST_DATA_DIR)oneoff_test_log.txt", "w")
write(io,"")
close(io)

logger_io = open("$(TEST_DATA_DIR)oneoff_test_log.txt","w+")
logger = SimpleLogger(logger_io, Logging.Debug)
global_logger(logger)


function test_actions()
    @test length(keys(PLAYER_ACTIONS)) == 6
end

function test_deepcopy()
    team_and_playertype = [
                          (:blue, DefaultRobotPlayer),
                          (:cyan, DefaultRobotPlayer),
                          (:green, DefaultRobotPlayer),
                          (:red, DefaultRobotPlayer)
            ]

    players = setup_players(team_and_playertype)
    game = Game(players)
    game2 = deepcopy(game)
    game.players[1].player.team = :newcolor
    @test game2.players[1].player.team == :blue
    game.players[1].player.resources[:Wood] = 50
    @test !haskey(game2.players[1].player.resources, :Wood)
end

function test_set_starting_player()
    sf, sfio = reset_savefile_with_timestamp("test_set_starting_player")
    reset_savefile(sf, sfio)
    team_and_playertype = [
                          (:blue, DefaultRobotPlayer),
                          (:cyan, DefaultRobotPlayer),
                          (:green, DefaultRobotPlayer),
                          (:red, DefaultRobotPlayer)
            ]
    players = setup_players(team_and_playertype)
    game = Game(players)

    GameApi.set_starting_player(game, 2)

    @test game.turn_order_set == true
    @test game.players[1].player.team == :cyan
    @test game.players[2].player.team == :green
    @test game.players[3].player.team == :red
    @test game.players[4].player.team == :blue
    
    flush(Catan.SAVEFILEIO)
    board = read_map(SAMPLE_MAP)
    @info "testing logfile $SAVEFILE"
    new_game = Game(players)
    load_gamestate!(new_game, board, SAVEFILE)
    
    flush(logger_io)

    @test new_game.turn_order_set == true
    @test new_game.players[2].player.team == :green
    @test new_game.players[3].player.team == :red
    @test new_game.players[4].player.team == :blue
    @test new_game.players[1].player.team == :cyan

    #players: green, red, 
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

@assert BoardApi.get_neighbors((3,10)) == Set([(3,9),(3,11),(2,9)])
@assert BoardApi.get_neighbors((6,3)) == Set([(6,2),(6,4),(5,4)])
@assert BoardApi.get_neighbors((1,7)) == Set([(1,6),(2,8)])
@assert BoardApi.get_neighbors((1,7)) == Set([(1,6),(2,8)])

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
    board, game = setup_and_do_robot_game(team_and_playertype)
    flush(Catan.SAVEFILEIO)
    
    @info "testing savefile $SAVEFILE"
    
    # initialize fresh objects
    new_players = setup_players(team_and_playertype)
    new_game = Game(new_players)
    new_board = read_map(SAMPLE_MAP)

    load_gamestate!(new_game, new_board, SAVEFILE)
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
        @test player.devcards == new_player.devcards
        @test player.devcards_used == new_player.devcards_used
        @test player.ports == new_player.ports
        @test player.played_devcard_this_turn == new_player.played_devcard_this_turn
        @test player.bought_devcard_this_turn == new_player.bought_devcard_this_turn
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
    GameApi.start_turn(game)
    @test game.turn_num == 1
    GameRunner.do_turn(game, board, player1)
end

function test_robber()
    board = read_map(SAMPLE_MAP)
    player1 = DefaultRobotPlayer(:Test1)
    player2 = DefaultRobotPlayer(:Test2)
    players = Vector{PlayerType}([player1, player2])
    BoardApi.build_settlement!(board, :Test1, (1,1))
    BoardApi.build_settlement!(board, :Test2, (1,3))
    

    victims = get_admissible_theft_victims(board, PlayerPublicView.(players), player1, :A)
    @test length(victims) == 0
    
    victims = get_admissible_theft_victims(board, PlayerPublicView.(players), player1, :S)
    @test length(victims) == 0

    PlayerApi.give_resource!(player2.player, :Grain)
    
    victims = get_admissible_theft_victims(board, PlayerPublicView.(players), player1, :A)
    @test length(victims) == 1
    
    PlayerApi.take_resource!(player2.player, :Grain)
    
    victims = get_admissible_theft_victims(board, PlayerPublicView.(players), player1, :A)
    @test length(victims) == 0
end

function test_max_construction()
    board = read_map(SAMPLE_MAP)
    player1 = DefaultRobotPlayer(:Test1)
    for i in 1:(MAX_SETTLEMENT-1)
        BoardApi.build_settlement!(board, :Test1, BoardApi.get_admissible_settlement_locations(board, player1.player.team, true)[1])
    end
    @test length(BoardApi.get_admissible_settlement_locations(board, player1.player.team, true)) > 0
    BoardApi.build_settlement!(board, :Test1, BoardApi.get_admissible_settlement_locations(board, player1.player.team, true)[1])
    @test length(BoardApi.get_admissible_settlement_locations(board, player1.player.team, true)) == 0
    @test BoardApi.count_settlements(board, player1.player.team) == MAX_SETTLEMENT
    
    for i in 1:(MAX_CITY-1)
        BoardApi.build_city!(board, :Test1, BoardApi.get_admissible_city_locations(board, player1.player.team)[1])
    end
    @test length(BoardApi.get_admissible_city_locations(board, player1.player.team)) > 0
    BoardApi.build_city!(board, :Test1, BoardApi.get_admissible_city_locations(board, player1.player.team)[1])
    @test length(BoardApi.get_admissible_city_locations(board, player1.player.team)) == 0
    @test BoardApi.count_cities(board, player1.player.team) == MAX_CITY
    
    for i in 1:(MAX_ROAD-1)
        coords = BoardApi.get_admissible_road_locations(board, player1.player.team)[1]
        BoardApi.build_road!(board, :Test1, coords...)
    end
    @test length(BoardApi.get_admissible_road_locations(board, player1.player.team)) > 0
    coords = BoardApi.get_admissible_road_locations(board, player1.player.team)[1]
    BoardApi.build_road!(board, :Test1, coords...)
    @test length(BoardApi.get_admissible_road_locations(board, player1.player.team)) == 0
    @test BoardApi.count_roads(board, player1.player.team) == MAX_ROAD
end

# API Tests
function test_devcards()
    board = read_map(SAMPLE_MAP)
    player1 = DefaultRobotPlayer(:Test1)
    player2 = DefaultRobotPlayer(:Test2)
    players = Vector{PlayerType}([player1, player2])

    PlayerApi.give_resource!(player1.player, :Grain)
    PlayerApi.give_resource!(player1.player, :Stone)
    PlayerApi.give_resource!(player1.player, :Pasture)
    PlayerApi.give_resource!(player1.player, :Brick)
    PlayerApi.give_resource!(player1.player, :Wood)
    
    do_monopoly_action(board, players, player2)
    @test PlayerApi.count_resources(player1.player) == 4
    
    players_public = PlayerPublicView.(players)
    Catan.do_year_of_plenty_action(board, players_public, player1)
    @test PlayerApi.count_resources(player1.player) == 6

    BoardApi.build_settlement!(board, player1.player.team, (2,5))
    players_public = PlayerPublicView.(players)
    Catan.do_road_building_action(board, players_public, player1)
    @test BoardApi.count_roads(board, player1.player.team) == 2
    
    players_public = PlayerPublicView.(players)
    Catan.do_road_building_action(board, players_public, player1)
    @test BoardApi.count_roads(board, player1.player.team) == 4
    
    @test GameRunner.get_total_vp_count(board, player1.player) == 1
    @test GameRunner.get_total_vp_count(board, player2.player) == 0
end

function test_largest_army()
    board = read_map(SAMPLE_MAP)
    player1 = DefaultRobotPlayer(:Test1)
    player2 = DefaultRobotPlayer(:Test2)
    players = Vector{PlayerType}([player1, player2])
    
    PlayerApi.add_devcard!(player1.player, :Knight)
    PlayerApi.add_devcard!(player1.player, :Knight)
    PlayerApi.add_devcard!(player1.player, :Knight)
    
    PlayerApi.add_devcard!(player2.player, :Knight)
    PlayerApi.add_devcard!(player2.player, :Knight)
    PlayerApi.add_devcard!(player2.player, :Knight)
    PlayerApi.add_devcard!(player2.player, :Knight)
    
    # < 3 knights played, so no largest army assigned
    PlayerApi.play_devcard!(player1.player, :Knight)
    PlayerApi.play_devcard!(player1.player, :Knight)
    decide_and_assign_largest_army!(board, players)
    @test GameRunner.get_total_vp_count(board, player1.player) == 0
    @test GameRunner.get_total_vp_count(board, player1.player) == 0
    
    # Player1 has 3 knights, so he gets 2 points
    PlayerApi.play_devcard!(player1.player, :Knight)
    decide_and_assign_largest_army!(board, players)
    @test GameRunner.get_total_vp_count(board, player1.player) == 2
    
    # Player1 has largest army, and Player2 plays 3 knights, so Player 1 keeps LA
    PlayerApi.play_devcard!(player2.player, :Knight)
    PlayerApi.play_devcard!(player2.player, :Knight)
    PlayerApi.play_devcard!(player2.player, :Knight)
    decide_and_assign_largest_army!(board, players)
    @test GameRunner.get_total_vp_count(board, player1.player) == 2
    @test GameRunner.get_total_vp_count(board, player2.player) == 0
    
    # Player2 plays a 4th knight, successfully stealing the largest army from Player1
    PlayerApi.play_devcard!(player2.player, :Knight)
    decide_and_assign_largest_army!(board, players)
    @test GameRunner.get_total_vp_count(board, player1.player) == 0
    @test GameRunner.get_total_vp_count(board, player2.player) == 2
end

function test_road_hashing()
    road1 = Road((2,3), (2,4), :Blue)
    road2 = Road((2,3), (2,4), :Blue)
    set = Set{Road}()
    push!(set, road1)
    push!(set, road2)
    push!(set, road2)
    println(set)
    @test length(set) == 1
end
function test_longest_road()
    board = read_map(SAMPLE_MAP)
    player_blue = DefaultRobotPlayer(:Blue)
    player_green = DefaultRobotPlayer(:Green)
    players = Vector{PlayerType}([player_blue, player_green])


    # 31-32-33-34-35-36-37-38-39-3!-3@
    # (9)|  D  |  E  |  F  |  G  |
    #    21-22-23-24-25-26-27-28-29
    
    BoardApi.build_settlement!(board, :Green, (2,4))
    BoardApi.build_settlement!(board, :Blue, (2,3))

    BoardApi.build_road!(board, :Blue, (2,3), (2,4))
    BoardApi.build_road!(board, :Blue, (2,2), (2,3))
    BoardApi.build_road!(board, :Blue, (2,1), (2,2))
    BoardApi.build_road!(board, :Blue, (2,1), (3,2))

    @test board.longest_road == nothing
    
    
    # Length 5 road, but it's intersected by :Green settlement
    BoardApi.build_road!(board, :Blue, (2,5), (2,4))
    @test board.longest_road == nothing

    # Now player one builds a 5-length road without intersection
    BoardApi.build_road!(board, :Blue, (3,3), (3,2))
    @test board.longest_road == :Blue

    BoardApi.build_settlement!(board, :Green, (3,10))
    BoardApi.build_road!(board, :Green, (3,10), (3,11))
    BoardApi.build_road!(board, :Green, (3,10), (3,9))
    BoardApi.build_road!(board, :Green, (3,8), (3,9))
    BoardApi.build_road!(board, :Green, (3,10), (2,9))
    BoardApi.build_road!(board, :Green, (2,9), (2,8))
    BoardApi.build_road!(board, :Green, (2,8), (2,7))
    
    # Player green built 6 roads connected, but branched, so still player 1 has longest road
    @test board.longest_road == :Blue
    
    # Now player green makes a loop, allowing 6 roads continuous
    BoardApi.build_road!(board, :Green, (3,8), (2,7))
    @test board.longest_road == :Green

    BoardApi.build_settlement!(board, :Blue, (5,1))
    BoardApi.build_road!(board, :Blue, (5,1), (5,2))
    BoardApi.build_road!(board, :Blue, (5,3), (5,2))
    BoardApi.build_road!(board, :Blue, (5,3), (5,4))
    
    # Player blue added more roads, but not contiguous, so they don't beat player green
    @test board.longest_road == :Green

    
    # Two settlements
    @test GameRunner.get_total_vp_count(board, player_blue.player) == 2
    # Two settlements + Longest road
    @test GameRunner.get_total_vp_count(board, player_green.player) == 4
end

function test_ports()
    board = read_map(SAMPLE_MAP)
    player1 = DefaultRobotPlayer(:Test1)
    player2 = DefaultRobotPlayer(:Test2)
    @test all([v == 4 for v in values(player1.player.ports)])
    @test length(keys(player1.player.ports)) == 5

    PlayerApi.add_port!(player1.player, :Grain)

    @test player1.player.ports[:Grain] == 2
    @test player1.player.ports[:Wood] == 4
    
    PlayerApi.add_port!(player1.player, :All)
    PlayerApi.add_port!(player2.player, :All)
    
    @test all([v == 3 for v in values(player2.player.ports)])
    @test player1.player.ports[:Grain] == 2
    @test player1.player.ports[:Wood] == 3

    Catan.construct_settlement(board, player1.player, (3,2))
    
    @test player1.player.ports[:Brick] == 2
end

function test_human_player()
    board = read_map(SAMPLE_MAP)
    player1 = HumanPlayer(:Test1, open("human_test_player1.txt", "r"))
    player2 = HumanPlayer(:Test2, open("human_test_player2.txt", "r"))
    players = Vector{PlayerType}([player1, player2])
    game = Game(players)
    reset_savefile_with_timestamp("test_human_game")
    GameRunner.initialize_and_do_game!(game, SAMPLE_MAP)
end

function test_game_api()
    players = setup_players() # blue, green, cyan
    game = Game(players)
    board = read_map(SAMPLE_MAP_2)

    @test game.resources[:Pasture] == 25
    @test game.resources[:Brick] == 25
    @test game.resources[:Stone] == 25


    p1 = players[1]
    p2 = players[2]
    # dice roll 9
    BoardApi.build_settlement!(board, p1.player.team, (5,8)) # 2 stone
    BoardApi.build_city!(board, p1.player.team, (5,8)) # 4 stone
    BoardApi.build_settlement!(board, p2.player.team, (4,8)) # 1 brick, 1 stone
    BoardApi.build_city!(board, p2.player.team, (4,8)) # 2 brick, 2 stone
    
    # dice roll 8
    BoardApi.build_settlement!(board, p1.player.team, (2,6)) # 1 pasture
    BoardApi.build_city!(board, p1.player.team, (2,6)) # 2 pasture
    
    for i=1:4
        # 4*(4+2) = 24
        harvest_resources(game, board, players, 9)
        # 4*(0+2) = 8
        harvest_resources(game, board, players, 8)
    end
    @test haskey(p1.player.resources, :Stone)
    @test haskey(p1.player.resources, :Pasture)
    @test haskey(p2.player.resources, :Stone)
    @test haskey(p2.player.resources, :Brick)
    
    @test p1.player.resources[:Pasture] == 8
    @test p1.player.resources[:Stone] == 16
    @test p2.player.resources[:Stone] == 8
    @test p2.player.resources[:Brick] == 8

    harvest_resources(game, board, players, 9)
    for i=1:9
        harvest_resources(game, board, players, 8)
    end
    
    @test p1.player.resources[:Pasture] == 25
    @test p1.player.resources[:Stone] == 16
    @test p2.player.resources[:Stone] == 8
    @test p2.player.resources[:Brick] == 25
    @test ~haskey(p1.player.resources, :Brick)
    @test ~haskey(p2.player.resources, :Wood)
    
    @test game.resources[:Pasture] == 0
    @test game.resources[:Stone] == 1
    @test game.resources[:Brick] == 0
end

function test_board_api()

    @test length(BoardApi.get_neighbors((3,8))) == 3
    @test length(BoardApi.get_neighbors((3,11))) == 2
    @test length(BoardApi.get_neighbors((4,1))) == 2

    board = read_map(SAMPLE_MAP)
    BoardApi.build_settlement!(board, :Test1, (1,1))
    BoardApi.build_road!(board, :Test1, (1,1),(1,2))
    @test BoardApi.is_valid_settlement_placement(board, :Test1, (1,2)) == false
    BoardApi.build_settlement!(board, :Test1, (1,2))

    BoardApi.build_settlement!(board, :Test1, (3,9))
    @test BoardApi.is_valid_settlement_placement(board, :Test1, (4,9)) == false
    @test !((4,9) in BoardApi.get_admissible_settlement_locations(board, :Test1, true))

    @test length(board.buildings) == 3
    @test length(keys(board.coord_to_building)) == 3
    @test BoardApi.count_settlements(board, :Test1) == 3
    @test BoardApi.count_settlements(board, :Test2) == 0

    BoardApi.build_city!(board, :Test1, (1,1))
    @test length(board.buildings) == 3
    @test length(keys(board.coord_to_building)) == 3
    @test BoardApi.count_settlements(board, :Test1) == 2
    @test BoardApi.count_cities(board, :Test1) == 1
    @test BoardApi.count_settlements(board, :Test2) == 0
    @test BoardApi.get_public_vp_count(board, :Test1) == 4
end

function test_call_api()
    board = read_map(SAMPLE_MAP)
    player1 = DefaultRobotPlayer(:Test1)
    player2 = DefaultRobotPlayer(:Test2)
    players = Vector{PlayerType}([player1, player2])

    @test PlayerApi.has_any_resources(player1.player) == false
    @test PlayerApi.has_any_resources(player2.player) == false

    PlayerApi.give_resource!(player1.player, :Grain)

    @test PlayerApi.has_any_resources(player1.player) == true

    @test roll_dice(player1) <= 12
    @test roll_dice(player2) >= 2
    
    players_public = [PlayerPublicView(p) for p in players]
    
    # Build first settlement
    settlement = choose_validate_build_settlement!(board, players_public, player1, true)
    loc_settlement = settlement.coord
    @test loc_settlement != nothing
    settlement_locs = BoardApi.get_settlement_locations(board, player1.player.team)
    @test length(settlement_locs) == 1
    
    # Upgrade it to a city
    players_public = [PlayerPublicView(p) for p in players]
    city = choose_validate_build_city!(board, players_public, player1)
    loc_city = city.coord
    @test loc_settlement == loc_city
    
    # Build a road attached to first settlement
    players_public = [PlayerPublicView(p) for p in players]
    
    #Equiv: choose_validate_build_road!(board, players_public, player1, true)
    admissible_roads = BoardApi.get_admissible_road_locations(board, player1.player.team, true)
    road_coords = choose_road_location(board, players_public, player1, admissible_roads)
    BoardApi.build_road!(board, player1.player.team, road_coords[1], road_coords[2])
    @test length(admissible_roads) == length(BoardApi.get_neighbors(loc_settlement))
    @test (road_coords[1] == loc_settlement || road_coords[2] == loc_settlement)
    @test length(BoardApi.get_road_locations(board, player1.player.team)) == 2

    # Build second settlement
    players_public = [PlayerPublicView(p) for p in players]
    settlement = Catan.choose_validate_build_settlement!(board, players_public, player1, true)
    loc_settlement = settlement.coord
    @test loc_settlement != nothing
    settlement_locs = BoardApi.get_settlement_locations(board, player1.player.team)
    @test length(settlement_locs) == 1 # City is no longer counted
    
    # Build a road attached to second settlement
    admissible_roads = BoardApi.get_admissible_road_locations(board, player1.player.team, true)
    players_public = [PlayerPublicView(p) for p in players]
    road_coords = choose_road_location(board, players_public, player1, admissible_roads)
    if road_coords == nothing
        print_board(board)
    end
    BoardApi.build_road!(board, player1.player.team, road_coords[1], road_coords[2])
    @test length(admissible_roads) == length(BoardApi.get_neighbors(loc_settlement))
    @test (road_coords[1] == loc_settlement || road_coords[2] == loc_settlement)

# roll_dice(player::RobotPlayer)::Int
# choose_road_location(board, players, player::RobotPlayer)::Vector{Tuple{Int,Int}}
# choose_building_location(board, players, player::RobotPlayer, building_type)::Tuple{Int, Int}
# choose_cards_to_discard(player::RobotPlayer, amount)
# choose_place_robber(board, players, player::RobotPlayer)
# choose_robber_victim(board, player::RobotPlayer, potential_victims...)::PlayerType
# choose_card_to_steal(player::RobotPlayer)::Symbol
    
end


function test_assign_largest_army()
    board = Catan.read_map(SAMPLE_MAP)
    player_blue = Catan.DefaultRobotPlayer(:Blue)
    player_green = DefaultRobotPlayer(:Green)
    players = Vector{PlayerType}([player_blue, player_green])

    @test board.largest_army == nothing

    PlayerApi._add_devcard!(player_blue.player, :Knight)
    PlayerApi._add_devcard!(player_blue.player, :Knight)
    PlayerApi._add_devcard!(player_blue.player, :Knight)
    PlayerApi._play_devcard!(player_blue.player, :Knight)
    PlayerApi._play_devcard!(player_blue.player, :Knight)
    decide_and_assign_largest_army!(board, players)

    @test board.largest_army == nothing

    PlayerApi._play_devcard!(player_blue.player, :Knight)
    decide_and_assign_largest_army!(board, players)
    
    @test board.largest_army == :Blue
    
    PlayerApi._add_devcard!(player_green.player, :Knight)
    PlayerApi._add_devcard!(player_green.player, :Knight)
    PlayerApi._add_devcard!(player_green.player, :Knight)
    PlayerApi._play_devcard!(player_green.player, :Knight)
    PlayerApi._play_devcard!(player_green.player, :Knight)
    PlayerApi._play_devcard!(player_green.player, :Knight)
    decide_and_assign_largest_army!(board, players)

    @test board.largest_army == :Blue

    PlayerApi._add_devcard!(player_green.player, :Knight)
    PlayerApi._play_devcard!(player_green.player, :Knight)
    decide_and_assign_largest_army!(board, players)
    
    @test board.largest_army == :Green
end
    
function test_robot_game(neverend)
    players = setup_players()
    test_automated_game(neverend, players)
end

function test_trading()
    board = read_map(SAMPLE_MAP)
    player1 = DefaultRobotPlayer(:Test1)
    player2 = DefaultRobotPlayer(:Test2)
    players = Vector{PlayerType}([player1, player2])
    players_public = PlayerPublicView.(players)
    PlayerApi.give_resource!(player1.player, :Grain)
    PlayerApi.give_resource!(player2.player, :Brick)
    actions = Set([:ProposeTrade])
    next_action = choose_next_action(board::Board, players_public, player1, actions)
    #@test next_action != nothing 
end

function run_tests(neverend = false)
    for file in Base.Filesystem.readdir("data")
        Base.Filesystem.rm("data/$file")
    end
    Catan.test_player_implementation(DefaultRobotPlayer)
    test_trading()
    """
    """
    test_assign_largest_army()
    test_game_api()
    test_road_hashing()
    test_deepcopy()
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
    test_robot_game(neverend)
end
if abspath(PROGRAM_FILE) == @__FILE__
    if (length(ARGS) > 0)
        if ARGS[1] == "--neverend"
            run_tests(true)
        else
            # Explicit save file passed as arg
            setup_and_do_robot_game(ARGS[1])
        end
    else
        run_tests(false)
    end
end

#statprofilehtml(from_c=true)
#Profile.print()

