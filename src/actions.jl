ALL_ACTIONS = Set([
:ConstructSettlement,
:ConstructCity,
:ConstructRoad,
:ProposeTrade,
:BuyDevCard,
:PlayDevCard,
:PlaceRobber
])

"""
PLAYER_ACTIONS = Dict([
    :ConstructSettlement    => act_construct_settlement,
    :ConstructCity          => act_construct_city,
    :ConstructRoad          => act_construct_road,
    :ProposeTrade           => act_propose_trade_goods,
    :PlayDevCard            => act_play_devcard,

    # Probabilistic actions
    :BuyDevCard             => act_buy_devcard,
    :PlaceRobber            => do_robber_move_theft 
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

function construct_road(game, board, player::Player, coord1, coord2, first_turn = false)
    if ~first_turn
        PlayerApi.pay_construction(player, :Road)
        GameApi.pay_construction!(game, :Road)
    end
    BoardApi.build_road!(board, player.team, coord1, coord2)
end

function construct_city(game, board, player::Player, coord, first_turn = false)
    if ~first_turn
        PlayerApi.pay_construction(player, :City)
        GameApi.pay_construction!(game, :City)
    end
    BoardApi.build_city!(board, player.team, coord)
end
function construct_settlement(game, board, player::Player, coord, first_turn = false)
    if ~first_turn
        PlayerApi.pay_construction(player, :Settlement)
        GameApi.pay_construction!(game, :Settlement)
    end
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

function draw_devcard(game::Game, player::Player)
    card = GameApi.draw_devcard(game)
    PlayerApi.buy_devcard(player, card)
    GameApi.pay_construction!(game, :DevelopmentCard)
end

function do_play_devcard(game, board::Board, players, player, card::Union{Nothing,Symbol})
    if card != nothing
        do_devcard_action(game, board, players, player, card)
        PlayerApi.play_devcard!(player.player, card)
        decide_and_assign_largest_army!(board, players)
        # Note: longest road is assigned within the build road call
    end
end

function do_devcard_action(game, board, players::Vector{PlayerType}, player::PlayerType, card::Symbol)
    @info "$(player.player.team) does devcard $card action"
    players_public = PlayerPublicView.(players)
    if card == :Knight
        do_knight_action(board, players, player)
    elseif card == :Monopoly
        do_monopoly_action(board, players, player)
    elseif card == :YearOfPlenty
        do_year_of_plenty_action(game, board, players_public, player)
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

function do_year_of_plenty_action(game, board, players::Vector{PlayerPublicView}, player::PlayerType)
    r1 = choose_resource_to_draw(board, players, player)
    PlayerApi.give_resource!(player.player, r1)
    GameApi.draw_resource!(game, r1)
    r2 = choose_resource_to_draw(board, players, player)
    PlayerApi.give_resource!(player.player, r2)
    GameApi.draw_resource!(game, r2)
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

function do_robber_move(game, board, players::Vector{PlayerType}, player)
    for p in players
        do_robber_move_discard(game, board, player)
    end
    do_robber_move_theft(board, players, player)
end

function do_robber_move_discard(game, board, player::PlayerType)
    r_count = PlayerApi.count_cards(player.player)
    if r_count > 7
        for i = 1:Int(floor(r_count / 2))
            resource = choose_one_resource_to_discard(board, player)
            PlayerApi.discard_cards!(player.player, resource)
            GameApi.give_resource!(game, resource)
        end
    end
end

function do_robber_move_theft(board, players::Vector{PlayerType}, player::PlayerType)
    players_public = PlayerPublicView.(players)
    new_robber_tile = choose_place_robber(board, players_public, player)
    @info "$(player.player.team) moves robber to $new_robber_tile"
    players_public = PlayerPublicView.(players)
    admissible_victims_public = get_admissible_theft_victims(board, players_public, player.player, new_robber_tile)
    admissible_victims = [p for p in players if p.player.team in admissible_victims_public]
    
    do_robber_move_theft(board, admissible_victims, player, new_robber_tile)
end

function do_robber_move_theft(board, admissible_victims::Vector{PlayerType}, 
        player::PlayerType, new_robber_tile::Symbol)
    stolen_good = nothing
    victim = nothing
    if length(admissible_victims) > 0
        admissible_victims_public = PlayerPublicView.(admissible_victims)
        from_player_view = choose_robber_victim(board, player, admissible_victims_public...)
        victim = [p for p in admissible_victims if p.player.team == from_player_view.team][1]
        stolen_good = steal_random_resource(victim, player)
    end
    victim_public = victim != nothing ? PlayerPublicView(victim) : victim
    do_robber_move_theft(board, admissible_victims, player, victim_public, new_robber_tile, stolen_good)
end

function do_robber_move_theft(board, players::Vector{PlayerType}, player::PlayerType, victim_public::Union{PlayerPublicView, Nothing}, new_robber_tile::Symbol, stolen_good::Union{Symbol,Nothing})
    BoardApi.move_robber!(board, new_robber_tile)
    victim = victim_public != nothing ? [p.player for p in players if p.player.team == victim_public.team][1] : nothing
    if victim != nothing && stolen_good != nothing
        PlayerApi.take_resource!(victim, stolen_good)
        PlayerApi.give_resource!(player.player, stolen_good)
    end
end

function get_admissible_theft_victims(board::Board, players::Vector{PlayerPublicView}, thief::Player, new_tile)::Vector{PlayerPublicView}
    admissible_victims = []
    for c in [cc for cc in TILE_TO_COORDS[new_tile] if haskey(board.coord_to_building, cc)]
        team = board.coord_to_building[c].team
        victim = [p for p in players if p.team == team][1]
        if PlayerApi.has_any_resources(victim) && (team != thief.team)
            push!(admissible_victims, victim)
        end
    end
    return admissible_victims
end

function options_construct_city(board::Board, player::Player, candidates::Vector{Tuple{Int,Int}})
    for candidate in candidates
    end
end
function with_options(action::Function, candidates::Vector)
    actions = []
    for c in candidates
        return [action(c) for c in candidates]
    end
    return actions
end

function get_legal_actions(game, board, player)::Set{Symbol}
    actions = Set{Symbol}()
    if PlayerApi.has_enough_resources(player, COSTS[:City]) && length(BoardApi.get_admissible_city_locations(board, player.team)) > 0
        push!(actions, :ConstructCity)
    end
    if PlayerApi.has_enough_resources(player, COSTS[:Settlement]) && length(BoardApi.get_admissible_settlement_locations(board, player.team)) > 0
        push!(actions, :ConstructSettlement)
    end
    if PlayerApi.has_enough_resources(player, COSTS[:Road]) && length(BoardApi.get_admissible_road_locations(board, player.team)) > 0
        push!(actions, :ConstructRoad)
    end
    if PlayerApi.has_enough_resources(player, COSTS[:DevelopmentCard]) && GameApi.can_draw_devcard(game)
        push!(actions, :BuyDevCard)
    end
    if PlayerApi.can_play_devcard(player)
        push!(actions, :PlayDevCard)
    end
    if PlayerApi.has_any_resources(player)
        push!(actions, :ProposeTrade)
    end
    return actions
end
