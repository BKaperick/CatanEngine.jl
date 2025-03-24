
TEST_DATA_DIR = "data/"
MAIN_DATA_DIR = "../data/"

SAMPLE_MAP = "$(MAIN_DATA_DIR)sample.csv"
# Only difference is some changing of dice values for testing
SAMPLE_MAP_2 = "$(MAIN_DATA_DIR)sample_2.csv"

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
    actions = Catan.ALL_ACTIONS

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
    choose_cards_to_discard(player, 1)
    choose_monopoly_resource(board, players, player)
    choose_next_action(board, players, player, actions)
    choose_place_robber(board, players, player)
    choose_play_devcard(board, players, player, devcards)
    choose_road_location(board, players, player, road_candidates)
    choose_robber_victim(board, player, players[2], players[3])
    choose_who_to_trade_with(board, player, players)
    choose_year_of_plenty_resources(board, players, player)
    get_legal_action_functions(board, players, player, actions)
end
