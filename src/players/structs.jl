using Random
import Base: deepcopy

abstract type PlayerType end
mutable struct Player
    # Private fields (can't be directly accessed by other players)
    resources::Dict{Symbol,Int}
    devcards::Dict{Symbol,Int}
    
    # Public fields (can be used by other players to inform their moves)
    team::Symbol
    devcards_used::Dict{Symbol,Int}
    ports::Dict{Symbol, Int}
    played_devcard_this_turn::Bool
    bought_devcard_this_turn::Union{Nothing,Symbol}
end

function Player(team::Symbol)
    default_ports = Dict([
    :Wood => 4
    :Stone => 4
    :Grain => 4
    :Brick => 4
    :Pasture => 4
    ])
    return Player(Dict(), Dict(), team, Dict(), default_ports, false, nothing)
end

"""
    PlayerPublicView

Combines the public fields of `Player`, with some additional fields representing the info available
publicly about the private fields.  E.g. everyone knows how many dev cards each player has, but not which ones.
"""
mutable struct PlayerPublicView
    # This is the same as the public fields in `Player`
    team::Symbol
    devcards_used::Dict{Symbol,Int}
    ports::Dict{Symbol, Int}
    played_devcard_this_turn::Bool
    bought_devcard_this_turn::Union{Nothing,Symbol}
    
    # Aggregated fields pertaining to the publicly-known info about the private fields
    resource_count::Int
    devcards_count::Int
end

PlayerPublicView(player::PlayerPublicView) = player;
PlayerPublicView(player::PlayerType) = PlayerPublicView(player.player)
PlayerPublicView(player::Player) = PlayerPublicView(
    player.team,
    player.devcards_used,
    player.ports,
    player.played_devcard_this_turn,
    player.bought_devcard_this_turn,

    # Resource count
    sum(values(player.resources)), 
    # Dev cards count
    sum(values(player.devcards))
   )


mutable struct HumanPlayer <: PlayerType
    player::Player
    io::IO
end
abstract type RobotPlayer <: PlayerType
end

mutable struct DefaultRobotPlayer <: RobotPlayer
    player::Player
end

mutable struct TestRobotPlayer <: RobotPlayer
    player::Player
    accept_trade_willingness
    propose_trade_willingness
    resource_to_proba_weight::Dict{Symbol, Int}
end

RobotPlayer(team::Symbol, mutation::Dict{Symbol, AbstractFloat}) = RobotPlayer(team)
PlayerType(team::Symbol, mutation::Dict{Symbol, AbstractFloat}) = PlayerType(team)

HumanPlayer(team::Symbol, io::IO) = HumanPlayer(Player(team), io)
HumanPlayer(team::Symbol) = HumanPlayer(team, stdin)

DefaultRobotPlayer(team::Symbol) = DefaultRobotPlayer(Player(team))
TestRobotPlayer(team::Symbol) = TestRobotPlayer(Player(team))
TestRobotPlayer(player::Player) = TestRobotPlayer(player, 5, 5, Dict(:Wood => 1, :Grain => 1, :Pasture => 1, :Brick => 1, :Stone => 1))


function Base.deepcopy(player::DefaultRobotPlayer)
    return DefaultRobotPlayer(deepcopy(player.player))
end

function Base.deepcopy(player::Player)
    return Player(
        deepcopy(player.resources),
        deepcopy(player.devcards),
        player.team,
        deepcopy(player.devcards_used),
        deepcopy(player.ports),
        player.played_devcard_this_turn,
        player.bought_devcard_this_turn
    )
end

player(player::DefaultRobotPlayer) = p -> p.player
player(player::TestRobotPlayer) = p -> p.player
player(player::HumanPlayer) = p -> p.player

