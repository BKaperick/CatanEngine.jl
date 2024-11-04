TestRobotPlayer(team::Symbol) = TestRobotPlayer(Player(team), .5, .5, Dict())

function initialize_player(board::Board, player::TestRobotPlayer)
    player.resource_to_proba_weight = _get_total_resource_probabilities(board)
end


function _get_optimal_building_placement(board, players, player, is_first_turn, admissible)
    max_dice = 0
    best_coord = []
    for a in admissible
        dice = sum([DICEVALUE_TO_PROBA_WEIGHT[board.tile_to_dicevalue[t]] for t in COORD_TO_TILES[a]])
        if dice >= max_dice
            max_dice = dice
            if dice == max_dice
                push!(best_coord, a)
            else
                best_coord = [a]
            end
        end
    end
    if length(best_coord) > 1
        max_weight = 0
        heaviest_coord = nothing
        for c in best_coord
            resources = [board.tile_to_resource[t] for t in COORD_TO_TILES[c]]
            weight = sum([player.resource_to_proba_weight[r] for r in resources])
            if weight > max_weight
                heaviest_coord = c
            end
        end
        return heaviest_coord
    end
    return best_coord[1]
end

function _get_total_resource_probabilities(board)
    resource_to_proba_weight = Dict()
    for (t,v) in board.tile_to_dicevalue
        r = board.tile_to_resource[t]
        if haskey(resource_to_proba_weight, r)
            resource_to_proba_weight[r] += DICEVALUE_TO_PROBA_WEIGHT[v]
        else
            resource_to_proba_weight[r] = DICEVALUE_TO_PROBA_WEIGHT[v]
        end
    end
    return resource_to_proba_weight
end

function choose_accept_trade(board::Board, player::TestRobotPlayer, from_player::PlayerPublicView, from_goods::Vector{Symbol}, to_goods::Vector{Symbol})::Bool
    return rand() > player.accept_trade_willingness + (get_public_vp_count(board, from_player) / 20)
end

function choose_building_location(board::Board, players::Vector{PlayerPublicView}, player::TestRobotPlayer, building_type::Symbol, is_first_turn::Bool = false)::Tuple
    admissible = []
    if building_type == :Settlement
        admissible = get_admissible_settlement_locations(board, player.player, is_first_turn)
    else
        admissible = get_admissible_city_locations(board, player.player)
    end
    return _get_optimal_building_placement(board, players, player, is_first_turn, admissible)
end

function choose_next_action(board::Board, players::Vector{PlayerPublicView}, player::TestRobotPlayer, actions::Set{Symbol})
    if :ConstructCity in actions
        coord = choose_building_location(board, players::Vector{PlayerPublicView}, player, :City)
        return (game, board) -> construct_city(board, player.player, coord)
    end
    if :ConstructSettlement in actions
        coord = choose_building_location(board, players::Vector{PlayerPublicView}, player, :Settlement)
        return (game, board) -> construct_settlement(board, player.player, coord)
    end
    if :ConstructRoad in actions
        coord = choose_road_location(board, players::Vector{PlayerPublicView}, player, false)
        coord1 = coord[1]
        coord2 = coord[2]
        return (game, board) -> construct_road(board, player.player, coord1, coord2)
    end
    if :BuyDevCard in actions
        return (game, board) -> buy_devcard(game, player.player)
    end
    if :PlayDevCard in actions
        devcards = get_admissible_devcards(player.player)
        card = choose_play_devcard(board, game.players, player, devcards)
        if card != nothing
            return (game, board) -> do_play_devcard(board, players, player, card)
        end
    elseif :ProposeTrade in actions
        if rand() < player.propose_trade_willingness
            sampled = random_sample_resources(player.player.resources, 1)
            rand_resource_from = [sampled...]
            
            rand_resource_to = [get_random_resource()]
            while rand_resource_to[1] == rand_resource_from[1]
                rand_resource_to = [get_random_resource()]
            end
            return (game, board) -> propose_trade_goods(board, game.players, player, rand_resource_from, rand_resource_to)
        end
    end
    return nothing
end
