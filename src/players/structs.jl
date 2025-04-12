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
    configs::Dict
end

function Player(team::Symbol, configs::Dict)
    default_ports = Dict([
    :Wood => 4
    :Stone => 4
    :Grain => 4
    :Brick => 4
    :Pasture => 4
    ])
    return Player(Dict([(r,0) for r in RESOURCES]), Dict(), team, Dict(), default_ports, false, nothing, configs)
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

#RobotPlayer(team::Symbol, mutation::Dict{Symbol, AbstractFloat}, configs::Dict) = RobotPlayer(team, configs)
PlayerType(team::Symbol, mutation::Dict{Symbol, AbstractFloat}) = PlayerType(team)

HumanPlayer(team::Symbol, io::IO, configs::Dict) = HumanPlayer(Player(team, configs), io)
HumanPlayer(team::Symbol, configs::Dict) = HumanPlayer(team, stdin, configs)

DefaultRobotPlayer(team::Symbol, configs::Dict) = DefaultRobotPlayer(Player(team, configs))
TestRobotPlayer(team::Symbol, configs::Dict) = TestRobotPlayer(Player(team, configs))


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
        player.bought_devcard_this_turn,
        player.configs
    )
end

player(player::DefaultRobotPlayer) = p -> p.player
player(player::TestRobotPlayer) = p -> p.player
player(player::HumanPlayer) = p -> p.player

struct KnownPlayers
    registered_constructors::Dict
end

function get_known_players()
    return known_players.registered_constructors
end
function add_player_to_register(name, constructor)
    known_players.registered_constructors[name] = constructor
end

global known_players = KnownPlayers(Dict())

add_player_to_register("DefaultRobotPlayer", (t,c) -> DefaultRobotPlayer(t,c))
add_player_to_register("HumanPlayer", (t,c) -> HumanPlayer(t,c))
