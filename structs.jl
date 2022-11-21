abstract type PlayerType end
mutable struct Player
    team::Symbol
    resources::Dict{Symbol,Int}
    vp_count::Int
    dev_cards::Dict{Symbol,Int}
    dev_cards_used::Dict{Symbol,Int}
    ports::Dict{Symbol, Int}
    played_dev_card_this_turn::Bool
    bought_dev_card_this_turn#::Union{Symbol,Nothing}
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
    return Player(team, Dict(), 0, Dict(), Dict(), default_ports, false, Nothing)
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
    devcards::Vector{Symbol}
    players::Vector{PlayerType}
    turn_num::Int
end
Game(players) = Game(INITIAL_DEVCARD_DECK, players, 0)

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

