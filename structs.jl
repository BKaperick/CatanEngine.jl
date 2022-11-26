abstract type PlayerType end
mutable struct Player
    team::Symbol
    resources::Dict{Symbol,Int}
    vp_count::Int
    dev_cards::Dict{Symbol,Int}
    dev_cards_used::Dict{Symbol,Int}
    ports::Dict{Symbol, Int}
    played_dev_card_this_turn::Bool
    bought_dev_card_this_turn::Union{Nothing,Symbol}
    has_largest_army::Bool
    has_longest_road::Bool
end
mutable struct HumanPlayer <: PlayerType
    player::Player
end

mutable struct RobotPlayer <: PlayerType
    player::Player
end

function Player(team::Symbol)
    default_ports = Dict([
    :Wood => 4
    :Stone => 4
    :Grain => 4
    :Brick => 4
    :Pasture => 4
    ])
    return Player(team, Dict(), 0, Dict(), Dict(), default_ports, false, nothing, false, false)
end
HumanPlayer(team::Symbol) = HumanPlayer(Player(team))
RobotPlayer(team::Symbol) = RobotPlayer(Player(team))



mutable struct Public_Info
    resource_count::Int
    dev_cards_count::Int
    dev_cards_used::Dict{Symbol,Int}
    vp_count::Int
end
Public_Info(player::Player) = Public_Info(
    sum(values(player.resources)), 
    sum(values(player.dev_cards)),
    Dict(),
    player.vp_count)

mutable struct Private_Info
    resources::Dict{Symbol,Int}
    dev_cards::Dict{Symbol,Int}
    private_vp_count::Int
end
Private_Info(player::Player) = Private_Info(player.resources, player.dev_cards, player.vp_count)

mutable struct Game
    devcards::Dict{Symbol,Int}
    players::Vector{PlayerType}
    already_played_this_turn::Set{Symbol}
    turn_num::Int
    turn_order_set::Bool
    first_turn_forward_finished::Bool
end
Game(players) = Game(DEVCARD_COUNTS, players, Set(), 0, false, false)

mutable struct Construction
end

mutable struct Road
    coord1::Tuple{Int,Int}
    coord2::Tuple{Int,Int}
    team::Symbol
end

mutable struct Building
    coord::Tuple{Int,Int}
    type::Symbol
    team::Symbol
end

