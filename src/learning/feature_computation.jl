using Random
using CSV
using MLJ
using DataFrames
import DataFramesMeta as DFM
using DelimitedFiles


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

# Helper functions start with `get_`, and feature computers take (board, player) and start with `compute_`.

@feature :SettlementCount
compute_count_settlement = (board, player) -> get_building_count(board, :Settlement, player.team)
compute_count_city = (board, player) -> get_building_count(board, :City, player.team)
compute_count_road = (board, player) -> get_road_count(board, player.team)
compute_max_road_length = (board, player) -> get_max_road_length(board, player.team)

compute_sum_wood_dice_weight = (board, player) -> get_sum_resource_dice_weight(board, player.team, :Wood)
compute_sum_brick_dice_weight = (board, player) -> get_sum_resource_dice_weight(board, player.team, :Brick)
compute_sum_pasture_dice_weight = (board, player) -> get_sum_resource_dice_weight(board, player.team, :Pasture)
compute_sum_stone_dice_weight = (board, player) -> get_sum_resource_dice_weight(board, player.team, :Stone)
compute_sum_grain_dice_weight = (board, player) -> get_sum_resource_dice_weight(board, player.team, :Grain)

compute_count_port_wood = (board, player) -> get_resource_port_count(board, player.team, :Wood)
compute_count_port_brick = (board, player) -> get_resource_port_count(board, player.team, :Brick)
compute_count_port_pasture = (board, player) -> get_resource_port_count(board, player.team, :Pasture)
compute_count_port_stone = (board, player) -> get_resource_port_count(board, player.team, :Stone)
compute_count_port_grain = (board, player) -> get_resource_port_count(board, player.team, :Grain)

compute_count_hand_wood = (board, player) -> get_resource_hand_count(player, :Wood)
compute_count_hand_brick = (board, player) -> get_resource_hand_count(player, :Brick)
compute_count_hand_pasture = (board, player) -> get_resource_hand_count(player, :Pasture)
compute_count_hand_stone = (board, player) -> get_resource_hand_count(player, :Stone)
compute_count_hand_grain = (board, player) -> get_resource_hand_count(player, :Grain)

compute_count_dev_cards_owned_knight = (board, player) -> get_dev_cards_owned_count(player, :Knight)
compute_count_dev_cards_owned_monopoly = (board, player) -> get_dev_cards_owned_count(player, :Monopoly)
compute_count_dev_cards_owned_year_of_plenty = (board, player) -> get_dev_cards_owned_count(player, :YearOfPlenty)
compute_count_dev_cards_owned_road_building = (board, player) -> get_dev_cards_owned_count(player, :RoadBuilding)
compute_count_dev_cards_owned_victory_point = (board, player) -> get_dev_cards_owned_count(player, :VictoryPoint)

compute_count_victory_points = (board, player) -> player.vp_count

function compute_features(board, player)
    return [
        :CountSettlement => compute_count_settlement(board, player),
        :CountCity => compute_count_city(board, player),
        :CountRoad => compute_count_road(board, player),

        :SumWoodDiceWeight => compute_sum_wood_dice_weight(board, player),
        :SumBrickDiceWeight => compute_sum_brick_dice_weight(board, player),
        :SumPastureDiceWeight => compute_sum_pasture_dice_weight(board, player),
        :SumStoneDiceWeight => compute_sum_stone_dice_weight(board, player),
        :SumGrainDiceWeight => compute_sum_grain_dice_weight(board, player),
        :CountPortWood => compute_count_port_wood(board, player),
        :CountPortBrick => compute_count_port_brick(board, player),
        :CountPortPasture => compute_count_port_pasture(board, player),
        :CountPortStone => compute_count_port_stone(board, player),
        :CountPortGrain => compute_count_port_grain(board, player),

        :CountHandWood => compute_count_hand_wood(board, player),
        :CountHandBrick => compute_count_hand_brick(board, player),
        :CountHandPasture => compute_count_hand_pasture(board, player),
        :CountHandStone => compute_count_hand_stone(board, player),
        :CountHandGrain => compute_count_hand_grain(board, player),
        :CountDevCardsKnight => compute_count_dev_cards_owned_knight(board, player),
        :CountDevCardsMonopoly => compute_count_dev_cards_owned_monopoly(board, player),
        :CountDevCardsYearOfPlenty => compute_count_dev_cards_owned_year_of_plenty(board, player),
        :CountDevCardsRoadBuilding => compute_count_dev_cards_owned_road_building(board, player),
        :CountDevCardsVictoryPoint => compute_count_dev_cards_owned_victory_point(board, player),
        :CountVictoryPoints => compute_count_victory_points(board, player)
       ]
end

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

"""
    get_sum_resource_dice_weight(board, player.team, resource)

The sum of dice weight (
"""
function get_sum_resource_dice_weight(board, team, resource)::Int
    total_weight = 0
    for (c,b) in board.coord_to_building
        if b.team == team
            for tile in COORD_TO_TILES[c]
                if board.tile_to_resource[tile] == resource
                    weight = DICEVALUE_TO_PROBA_WEIGHT[board.tile_to_dicevalue[tile]]
                    if b.type == :City
                        weight *= 2
                    end

                    total_weight += weight
                end
            end
        end
    end
    return total_weight
end
function get_resource_hand_count(player, resource)::Int
    return haskey(player.resources, resource) ? player.resources[resource] : 0
end

function get_resource_port_count(board, team, resource)::Int
    count = 0
    for (c,p) in board.coord_to_port
        if p == resource && haskey(board.coord_to_building, c) && board.coord_to_building[c].team == team
            count += 1
        end
    end
    return count
end

function get_dev_cards_owned_count(player, dev_card)::Int
    count = 0
    for (card,cnt) in player.dev_cards
        if card == dev_card
            count += cnt
        end
    end
    for (card,cnt) in player.dev_cards_used
        if card == dev_card
            count += cnt
        end
    end
    return count
end

function predict_model(machine::Machine, board::Board, player::PlayerType)
    features = [x for x in compute_features(board, player.player)]
    header = get_csv_friendly.(first.(features))
    feature_vals = last.(features)
    pred = _predict_model_feature_vec(machine, feature_vals, header)

    # Returns the win probability (proba weight on category for label `1.0` indicating win)
    return pdf(pred[1], 1.0)
end

function _predict_model_feature_vec(machine::Machine, feature_vals::Vector{T}, header::Vector{String}) where T <: Number
    data = reshape(feature_vals, 1, length(feature_vals))
    #header = names(machine.data[1])
    df = DataFrame(data, vec(header), makeunique=true)
    return Base.invokelatest(MLJ.predict, machine, df)
end
