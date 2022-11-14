import Random

include("constants.jl")
include("structs.jl")

function draw_devcard(game::Game)
    log_action("game dd")
    _draw_devcard(game)
end
function _draw_devcard(game::Game)
    sample(game.devcards,1)[1]
end

function set_starting_player(game, index)
    log_action("game ss", index)
    _set_starting_player(game, index)
end
function _set_starting_player(game::Game, index)
    game.players = circshift(game.players, length(game.players) - index + 1)
end
