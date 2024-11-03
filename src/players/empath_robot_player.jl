EmpathRobotPlayer(team::Symbol) = EmpathRobotPlayer(Player(team), .5, .5, Dict())

function get_probability_of_victory_estimate(board::Board, players::Vector{PlayerPublicView}, player::PlayerPublicView)::Float
end

function get_probability_of_victory_estimate(board::Board, players::Vector{PlayerPublicView}, player::PlayerPublicView)::Float
end

"""
Board position features:

[
    # 
    # For construction
    #
    settlement count
    city count
    road count
    max road length

    sum(wood dice_weight)
    sum(stone dice_weight)
    sum(sheep dice_weight)
    sum(brick dice_weight)
    sum(wheat dice_weight)
    port wood 1 or 0
    port stone 1 or 0
    port sheep 1 or 0
    port brick 1 or 0
    port wheat 1 or 0

    # 
    # For resources in hand
    # 
    wood count
    stone count
    grain count
    brick count
    pasture count
    
    # 
    # Dev cards
    #
    Knight count
    Monopoly count
    YearOfPlenty count
    RoadBuilding count
    VictoryPoint count
    
    Knight already-played count
    Monopoly already-played count
    YearOfPlenty already-played count
    RoadBuilding already-played count
    VictoryPoint already-played count

    
]


"""
function save_parameters_after_game_end(game::Game, board::Board, players::Vector{PlayerType}, player::PlayerType)
    settlement count
    city count
    road count
    max road length
    features =  Dict([
        :SettlementCount => 0.0,
        :CityCount => 0.0,
        :RoadCount => 0.0,
        :MaxRoadLength => 0.0,
        :SumWoodDiceWeight => 0.0,
        :SumBrickDiceWeight => 0.0,
        :SumPastureDiceWeight => 0.0,
        :SumStoneDiceWeight => 0.0,
        :SumGrainDiceWeight => 0.0
        :PortWood => 0.0,
        :PortBrick => 0.0,
        :PortPasture => 0.0,
        :PortStone => 0.0,
        :PortGrain => 0.0
        :CountWood => 0.0,
        :CountBrick => 0.0,
        :CountPasture => 0.0,
        :CountStone => 0.0,
        :CountGrain => 0.0
        :CountKnight => 0.0,
        :CountMonopoly => 0.0,
        :CountYearOfPlenty => 0.0,
        :CountRoadBuilding => 0.0,
        :CountVictoryPoint => 0.0
    ])
    # Get all settlements

end
