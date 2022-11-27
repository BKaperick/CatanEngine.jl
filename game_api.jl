import Random

include("constants.jl")
include("structs.jl")

function start_turn(game::Game)
    log_action("game st")
    _start_turn(game)
end
function _start_turn(game::Game)
    println("adding turns !!! $(game.turn_num)")
    game.turn_num += 1
    for p in game.players
        p.player.played_dev_card_this_turn = false
        p.player.bought_dev_card_this_turn = nothing
    end
end
function finish_player_turn(game::Game, team)
    log_action("game fp :$team")
    _finish_player_turn(game, team)
end
function _finish_player_turn(game, team)
    push!(game.already_played_this_turn, team)
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

function set_starting_player(game, index)
    log_action("game ss", index)
    _set_starting_player(game, index)
end
function _set_starting_player(game::Game, index)
    game.players = circshift(game.players, length(game.players) - index + 1)
    game.turn_order_set = true
end
    
