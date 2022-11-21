using Test
include("constants.jl")
include("human.jl")
include("main.jl")

LOGFILEIO = open(LOGFILE, "a")

function setup_robot_game()
    # Configure players and table configuration
    team_and_playertype = [
                          (:Robo1, RobotPlayer),
                          (:Sobo2, RobotPlayer),
                          (:Tobo3, RobotPlayer),
                          (:Uobo4, RobotPlayer)
            ]
    players = [player(team) for (team,player) in team_and_playertype]
    game = Game(players)
    initialize_game(game, "sample.csv")
end


@test get_coord_from_human_tile_description("nqr") == (5,4)
@test get_coord_from_human_tile_description("nqr") == (5,4)
@test get_coord_from_human_tile_description("qqm") == (6,1)
@test get_coord_from_human_tile_description("qqr") == (6,2)
@test get_coord_from_human_tile_description("gcc") == (1,7)
@test get_coord_from_human_tile_description("ada") == (1,1)
@test get_coord_from_human_tile_description("bbb") == (1,4)
@test get_coord_from_human_tile_description("ggg") == (2,9)
@test get_coord_from_human_tile_description("llg") == (3,11)
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

function test_do_turn()
    board = read_map("sample.csv")
    player1 = RobotPlayer(:Test1)
    player2 = RobotPlayer(:Test2)
    players = [player1, player2]
    game = Game(players)
    start_turn(game)
    @test game.turn_num == 1
    do_turn(game, board, player1)
end

# API Tests
function test_devcards()
    board = read_map("sample.csv")
    player1 = RobotPlayer(:Test1)
    player2 = RobotPlayer(:Test2)
    players = [player1, player2]

    give_resource(player1.player, :Grain)
    give_resource(player1.player, :Stone)
    give_resource(player1.player, :Pasture)
    give_resource(player1.player, :Brick)
    give_resource(player1.player, :Wood)
    
    do_monopoly_action(board, players, player2)
    @test count_resources(player1.player) == 4
    
    do_year_of_plenty_action(board, players, player1)
    @test count_resources(player1.player) == 6

    build_settlement(board, player1.player.team, (2,5))
    do_road_building_action(board, players, player1)
    @test count_roads(board, player1.player.team) == 2
    do_road_building_action(board, players, player1)
    @test count_roads(board, player1.player.team) == 4
    
end

function test_ports()
    board = read_map("sample.csv")
    player1 = RobotPlayer(:Test1)
    player2 = RobotPlayer(:Test2)
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

function test_call_api()
    board = read_map("sample.csv")
    player1 = RobotPlayer(:Test1)
    player2 = RobotPlayer(:Test2)
    players = [player1, player2]

    @test has_any_resources(player1.player) == false
    @test has_any_resources(player2.player) == false

    give_resource(player1.player, :Grain)

    @test has_any_resources(player1.player) == true

    @test roll_dice(player1) <= 12
    @test roll_dice(player2) >= 2
    
    # Build first settlement
    loc_settlement = choose_building_location(board, players, player1, :Settlement, true)
    @test loc_settlement != Nothing
    build_settlement(board, player1.player.team, loc_settlement)
    settlement_locs = get_settlement_locations(board, player1.player.team)
    @test length(settlement_locs) == 1
    
    # Upgrade it to a city
    loc_city = choose_building_location(board, players, player1, :City)
    build_city(board, player1.player.team, loc_city)
    @test loc_settlement == loc_city
    
    # Build a road attached to first settlement
    admissible_roads = get_admissible_road_locations(board, player1.player)
    road_coords = choose_road_location(board, players, player1)
    build_road(board, player1.player.team, road_coords[1], road_coords[2])
    @test length(admissible_roads) == length(get_neighbors(loc_settlement))
    @test (road_coords[1] == loc_settlement || road_coords[2] == loc_settlement)
    @test length(get_road_locations(board, player1.player.team)) == 2

    # Build second settlement
    loc_settlement = choose_building_location(board, players, player1, :Settlement, true)
    @test loc_settlement != Nothing
    build_settlement(board, player1.player.team, loc_settlement)
    settlement_locs = get_settlement_locations(board, player1.player.team)
    @test length(settlement_locs) == 1 # City is no longer counted
    
    # Build a road attached to second settlement
    admissible_roads = get_admissible_road_locations(board, player1.player, true)
    road_coords = choose_road_location(board, players, player1, true)
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

function run_tests()
    test_ports()
    test_devcards()
    test_do_turn()
    test_call_api()
    setup_robot_game()
end
