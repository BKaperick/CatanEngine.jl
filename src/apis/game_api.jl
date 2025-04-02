module GameApi
using ..Catan: Game, roll_dice, log_action, COSTS
using StatsBase
import Random
include("../random_helper.jl")

function start_turn(game::Game)::Nothing
    log_action("game st")
    _start_turn(game)
end
function _start_turn(game::Game)
    game.turn_num += 1
    for p in game.players
        p.player.played_devcard_this_turn = false
        p.player.bought_devcard_this_turn = nothing
    end
end
function get_players_to_play(game::Game)
    [p for p in game.players if !(p.player.team in game.already_played_this_turn)]
end

function do_set_turn_order(game)
    if !game.turn_order_set
        out_players = []
        values = []
        for player in game.players
            push!(values, roll_dice(player))
        end

        set_starting_player(game, argmax(values))
    end
end

function finish_player_turn(game::Game, team)
    log_action("game fp :$team")
    _finish_player_turn(game, team)
end
function _finish_player_turn(game, team)
    push!(game.already_played_this_turn, team)
end

function set_dice_true(game::Game)
    log_action("game dt")
    _reset_dice_true(game)
end
function set_dice_false(game::Game)
    log_action("game df")
    _reset_dice_false(game)
end
_reset_dice_true(game::Game) = _reset_dice(game, true)
_reset_dice_false(game::Game) = _reset_dice(game, false)
function _reset_dice(game::Game, choice::Bool)
    game.rolled_dice_already = choice
end
function finish_turn(game::Game)
    log_action("game ft")
    _finish_turn(game)
end
function _finish_turn(game)
    game.already_played_this_turn = Set()
end
function can_draw_devcard(game::Game)
    return has_any_elements(game.devcards)
end
function draw_devcard(game::Game)
    card = random_sample_resources(game.devcards, 1)[1]
    log_action("game dd :$card")
    _draw_devcard(game, card)
end
function _draw_devcard(game::Game, card::Symbol)
    game.devcards[card] -= 1
    return card
end

function can_draw_resource(game::Game, resource::Symbol)
    return game.resources[resource] > 0
end
function draw_resource!(game::Game, resource::Symbol)
    log_action("game dr :$resource")
    _draw_resource!(game, resource)
end
function _draw_resource!(game::Game, resource::Symbol)
    game.resources[resource] -= 1
    return resource 
end
function give_resource!(game::Game, resource::Symbol)
    log_action("game pr :$resource")
    _give_resource!(game, resource)
end
function _give_resource!(game::Game, resource::Symbol)
    if game.resources[resource] == 25
        @info "game $(game.unique_id) has too much $resource"
        #@warn "game $(game.unique_id) has too much $resource"
    end
    game.resources[resource] += 1
    return resource 
end

function set_starting_player(game, index)
    log_action("game ss", index)
    _set_starting_player(game, index)
end
function _set_starting_player(game::Game, index)
    @debug "Before: $([p.player.team for p in game.players])"
    game.players = circshift(game.players, length(game.players) - index + 1)
    @debug "After: $([p.player.team for p in game.players])"
    game.turn_order_set = true
end

"""
    `pay_construction!(game::Game, symbol::Symbol)`

When a player constructs something, we give the resources back to the game
"""
function pay_construction!(game::Game, symbol::Symbol)
    resources = COSTS[symbol]
    for (r,c) in resources
        for i=1:c
            give_resource!(game, r)
        end
    end
end
end
