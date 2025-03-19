"""
PLAYER_ACTIONS = Dict([
    :ConstructSettlement    => act_construct_settlement,
    :ConstructCity          => act_construct_city,
    :ConstructRoad          => act_construct_road,
    :ProposeTrade           => act_propose_trade_goods,
    :BuyDevCard             => act_buy_devcard,
    :PlayDevCard            => act_play_devcard
   ])


ACTIONS_DICTIONARY = Dict(
    :ConstructCity => construct_city,
    :ConstructRoad => construct_road,
    :ConstructSettlement => construct_settlement
   )
"""

#
# CONSTRUCTION ACTIONS
#

function construct_road(board, player::Player, coord1, coord2)
    PlayerApi.pay_construction(player, :Road)
    BoardApi.build_road!(board, player.team, coord1, coord2)
end

function construct_city(board, player::Player, coord)
    PlayerApi.pay_construction(player, :City)
    BoardApi.build_city!(board, player.team, coord)
end
function construct_settlement(board, player::Player, coord)
    PlayerApi.pay_construction(player, :Settlement)
    check_add_port(board, player, coord)
    BoardApi.build_settlement!(board, player.team, coord)
end

function check_add_port(board::Board, player::Player, coord)
    if haskey(board.coord_to_port, coord)
        PlayerApi.add_port!(player, board.coord_to_port[coord])
    end
end

#
# DEVCARD ACTIONS
#

function buy_devcard(game::Game, player::Player)
    card = GameApi.draw_devcard(game)
    PlayerApi.pay_construction(player, :DevelopmentCard)
    PlayerApi.add_devcard!(player, card)
end

function do_play_devcard(board::Board, players, player, card::Union{Nothing,Symbol})
    if card != nothing
        do_devcard_action(board, players, player, card)
        PlayerApi.play_devcard!(player.player, card)
        decide_and_assign_largest_army!(board, players)
    end
end

function do_devcard_action(board, players::Vector{PlayerType}, player::PlayerType, card::Symbol)
    players_public = PlayerPublicView.(players)
    if card == :Knight
        do_knight_action(board, players, player)
    elseif card == :Monopoly
        do_monopoly_action(board, players, player)
    elseif card == :YearOfPlenty
        do_year_of_plenty_action(board, players_public, player)
    elseif card == :RoadBuilding
        do_road_building_action(board, players_public, player)
    else
        @assert false
    end
end

function do_road_building_action(board, players::Vector{PlayerPublicView}, player::PlayerType)
    choose_validate_build_road!(board, players, player, false)
    choose_validate_build_road!(board, players, player, false)
end

function do_year_of_plenty_action(board, players::Vector{PlayerPublicView}, player::PlayerType)
    r1, r2 = choose_year_of_plenty_resources(board, players, player)
    PlayerApi.give_resource!(player.player, r1)
    PlayerApi.give_resource!(player.player, r2)
end

function do_monopoly_action(board, players::Vector{PlayerType}, player)
    players_public = PlayerPublicView.(players)
    res = choose_monopoly_resource(board, players_public, player)
    for victim in players
        @info "$(victim.player.team) gives $(PlayerApi.count_resource(victim.player, res)) $res to $(player.player.team)"
        for i in 1:PlayerApi.count_resource(victim.player, res)
            PlayerApi.take_resource!(victim.player, res)
            PlayerApi.give_resource!(player.player, res)
        end
    end
end

function do_knight_action(board, players::Vector{PlayerType}, player)
    do_robber_move_theft(board, players, player)
end

function do_robber_move(board, players::Vector{PlayerType}, player)
    for p in players
        do_robber_move_discard(board, player)
    end
    do_robber_move_theft(board, players, player)
end

function do_robber_move_discard(board, player::PlayerType)
    r_count = PlayerApi.count_cards(player.player)
    if r_count > 7
        resources_to_discard = choose_cards_to_discard(player, Int(floor(r_count / 2)))
        PlayerApi.discard_cards!(player.player, resources_to_discard...)
    end
end

function do_robber_move_theft(board, players, player::PlayerType)
    players_public = PlayerPublicView.(players)
    new_tile = BoardApi.move_robber!(board, choose_place_robber(board, players_public, player))
    @info "$(player.player.team) moves robber to $new_tile"
    admissible_victims = get_admissible_theft_victims(board, players, player, new_tile)
    if length(admissible_victims) > 0
        from_player = choose_robber_victim(board, player, admissible_victims...)
        stolen_good = steal_random_resource(from_player, player)
        PlayerApi.take_resource!(from_player.player, stolen_good)
        PlayerApi.give_resource!(player.player, stolen_good)
    end
end

function get_admissible_theft_victims(board::Board, players::Vector{PlayerType}, thief::PlayerType, new_tile)
    admissible_victims = []
    for c in [cc for cc in TILE_TO_COORDS[new_tile] if haskey(board.coord_to_building, cc)]
        team = board.coord_to_building[c].team
        @info [p.player.team for p in players]
        @info team
        victim = [p for p in players if p.player.team == team][1]
        if PlayerApi.has_any_resources(victim.player) && (team != thief.player.team)
            @debug "vr: $(victim.player.resources)"
            push!(admissible_victims, victim)
        end
    end
    return admissible_victims
end

function get_legal_action_functions(board::Board, players::Vector{PlayerPublicView}, player::Player, actions::Set{Symbol})
    action_functions = []
    
    if :ConstructCity in actions
        candidates = BoardApi.get_admissible_city_locations(board, player.team)
        for coord in candidates
            push!(action_functions, (g, b, p) -> construct_city(b, p.player, coord))
        end
    end
    if :ConstructSettlement in actions
        candidates = BoardApi.get_admissible_settlement_locations(board, player.team)
        for coord in candidates
            push!(action_functions, (g, b, p) -> construct_settlement(b, p.player, coord))
        end
    end
    if :ConstructRoad in actions
        candidates = BoardApi.get_admissible_road_locations(board, player.team)
        for coord in candidates
            push!(action_functions, (g, b, p) -> construct_road(b, p.player, coord[1], coord[2]))
        end
    end

    if :BuyDevCard in actions
        push!(action_functions, (g, b, p) -> buy_devcard(g, p.player))
    end

    if :PlayDevCard in actions
        devcards = PlayerApi.get_admissible_devcards(player)
        for (card,cnt) in devcard
            # TODO how do we stop them playing devcards first turn they get them?  Is this correctly handled in get_admissible call?
            if card != :VictoryPoint
                push!(action_functions, (g, b, p) -> do_play_devcard(b, g.players, p, card))
            end
        end
    end

    if :ProposeTrade in actions
        sampled = random_sample_resources(player.resources, 1)
        rand_resource_from = [sampled...]
        rand_resource_to = [get_random_resource()]
        while rand_resource_to[1] == rand_resource_from[1]
            rand_resource_to = [get_random_resource()]
        end
        push!(action_functions, (g, b, p) -> propose_trade_goods(b, g.players, p, rand_resource_from, rand_resource_to))
    end

    return action_functions
end
