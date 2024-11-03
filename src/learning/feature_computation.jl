"""
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
"""

macro feature(name)
end

# Helper functions start with `get_`, and feature computers take (game, board, player) and start with `compute_`.

@feature :SettlementCount
function compute_settlement_count(game, board, player) => get_building_count(board, :Settlement, player.team)
function compute_city_count(game, board, player) => get_building_count(board, :City, player.team)
function compute_road_count(game, board, player) => get_road_count(board, player.team)
function compute_max_road_length(game, board, player) => get_road_count(board, player.team)

function get_building_count(board, building_type, team)
    out = 0
    for building in board.buildings
        if building.team == team && building.type == building_type
            out += 1
        end
    end
    return out
end

function get_road_count(board, team)
    out = 0
    for building in board.roads
        if building.team == team
            out += 1
        end
    end
    return out
end
