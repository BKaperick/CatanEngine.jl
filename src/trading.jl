using ..Catan: Board, PlayerType, Player, PlayerPublicView,
               choose_accept_trade, choose_who_to_trade_with
using ..Catan.PlayerApi

function propose_trade_goods(board::Board, players::Vector{PlayerType}, from_player::PlayerType, amount::Int, resource_symbols...)
    from_goods = collect(resource_symbols[1:amount])
    to_goods = collect(resource_symbols[amount+1:end])
    return propose_trade_goods(board, players, from_player, from_goods, to_goods)
end
function propose_trade_goods(board::Board, players::Vector{PlayerType}, from_player::PlayerType, from_goods, to_goods)
    to_goods_dict = Dict{Symbol,Int}()
    for g in to_goods
        if haskey(to_goods_dict,g)
            to_goods_dict[g] += 1
        else
            to_goods_dict[g] = 1
        end
    end
    accepted = Vector{Player}()
    accepted_public = Vector{PlayerPublicView}()
    from_player_public = PlayerPublicView(from_player.player)
    for player in players
        # Don't propose trade to yourself
        if player.player.team == from_player.player.team
            continue
        end
        if choose_accept_trade(board, player, from_player_public, from_goods, to_goods)
            @info "$(player.player.team) accepts the trade proposal"
            # We do this after the "choose" step to not leak information from player's hand
            if PlayerApi.has_enough_resources(player.player, to_goods_dict) 
                push!(accepted, player.player)
                push!(accepted_public, PlayerPublicView(player.player))
            end
        end
    end
    if length(accepted) == 0
        @info "Noone accepted"
        return
    end
    to_player_team = choose_who_to_trade_with(board, from_player, accepted_public)
    to_player = [p for p in accepted if p.team == to_player_team][1]
    trade_goods(from_player.player, to_player, [from_goods...], [to_goods...])
end


function trade_goods(players, from_player::Player, to_player_team::Symbol, amount::Int, resource_symbols...)
    to_player = [p for p in players if p.player.team == to_player_team]
    from_goods = resource_symbols[1:amount]
    to_goods = resource_symbols[amount+1:end]
    return trade_goods(from_player, to_player, from_goods, to_goods)
end

function flatten(d::Dict)
    vcat([repeat(r,c) for (r,c) in collect(d)]...)
end

function trade_goods(from_player::Player, to_player::Player, from_goods::Dict{Symbol, Int}, to_goods::Dict{Symbol, Int})
    from_goods_flat = flatten(from_goods)
    to_goods_flat = flatten(to_goods)
    trade_goods(from_player, to_player, from_goods, to_goods)
end

function trade_goods(from_player, to_player, from_goods::Vector{Symbol}, to_goods::Vector{Symbol})
    trade_goods_from_player(from_player, from_goods, to_goods)
    trade_goods_to_player(to_player, from_goods, to_goods)
end
function trade_goods(from_player::PlayerPublicView, to_player::Player, from_goods::Vector{Symbol}, to_goods::Vector{Symbol})
    trade_goods()
end

function trade_goods_from_player(from_player::Player, from_goods::Vector{Symbol}, to_goods::Vector{Symbol})
    for resource in from_goods
        PlayerApi.take_resource!(from_player, resource)
    end
    for resource in to_goods
        PlayerApi.give_resource!(from_player, resource)
    end
end

function trade_goods_to_player(to_player::Player, from_goods::Vector{Symbol}, to_goods::Vector{Symbol})
    for resource in from_goods
        PlayerApi.give_resource!(to_player, resource)
    end
    for resource in to_goods
        PlayerApi.take_resource!(to_player, resource)
    end
end

function trade_goods_to_player(to_player::Player, from_goods::Dict{Symbol, Int}, to_goods::Dict{Symbol, Int})
    from_goods_flat = flatten(from_goods)
    to_goods_flat = flatten(to_goods)
    trade_goods_to_player(to_player, from_goods_flat, to_goods_flat)
end

"""
    `trade_goods_from_player(from_player::PlayerPublicView, from_goods::Vector{Symbol}, to_goods::Vector{Symbol})`

This implementation is useful in when a player is evaluating whether they should accept a trade.  To see the 
"""
function trade_goods_from_player(from_player::PlayerPublicView, from_goods::Vector{Symbol}, to_goods::Vector{Symbol})
    from_player.resource_count - length(from_goods) + length(to_goods)
end

function trade_goods_from_player(from_player::Player, from_goods::Dict{Symbol, Int}, to_goods::Dict{Symbol, Int})
    from_goods_flat = flatten(from_goods)
    to_goods_flat = flatten(to_goods)
    trade_goods_from_player(from_player, from_goods_flat, to_goods_flat)
end
function trade_goods_from_player(from_player::PlayerPublicView, from_goods::Dict{Symbol, Int}, to_goods::Dict{Symbol, Int})
    from_goods_flat = flatten(from_goods)
    to_goods_flat = flatten(to_goods)
    trade_goods_from_player(from_player, from_goods_flat, to_goods_flat)
end
