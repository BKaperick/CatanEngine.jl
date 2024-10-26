abstract type PlayerType end
mutable struct Player
    # Private fields (can't be directly accessed by other players)
    resources::Dict{Symbol,Int}
    vp_count::Int
    dev_cards::Dict{Symbol,Int}
    
    # Public fields (can be used by other players to inform their moves)
    team::Symbol
    dev_cards_used::Dict{Symbol,Int}
    ports::Dict{Symbol, Int}
    played_dev_card_this_turn::Bool
    bought_dev_card_this_turn::Union{Nothing,Symbol}
    has_largest_army::Bool
    has_longest_road::Bool
end

function Player(team::Symbol)
    default_ports = Dict([
    :Wood => 4
    :Stone => 4
    :Grain => 4
    :Brick => 4
    :Pasture => 4
    ])
    return Player(Dict(), 0, Dict(), team, Dict(), default_ports, false, nothing, false, false)
end

"""
    PlayerPublicView

Combines the public fields of `Player`, with some additional fields representing the info available
publicly about the private fields.  E.g. everyone knows how many dev cards each player has, but not which ones.
"""
mutable struct PlayerPublicView
    # This is the same as the public fields in `Player`
    team::Symbol
    dev_cards_used::Dict{Symbol,Int}
    ports::Dict{Symbol, Int}
    played_dev_card_this_turn::Bool
    bought_dev_card_this_turn::Union{Nothing,Symbol}
    has_largest_army::Bool
    has_longest_road::Bool
    
    # Aggregated fields pertaining to the publicly-known info about the private fields
    resource_count::Int
    dev_cards_count::Int
    visible_vp_count::Int
end

PlayerPublicView(player::Player) = PlayerPublicView(
    player.team,
    player.dev_cards_used,
    player.ports,
    player.played_dev_card_this_turn,
    player.bought_dev_card_this_turn,
    player.has_largest_army,
    player.has_largest_road,

    # Resource count
    sum(values(player.resources)), 
    # Dev cards count
    sum(values(player.dev_cards)),
    
    # Total victory points minus the ones that are hidden from view (only case is a dev card awarding one)
    sum([item.second for item in player.dev_cards if item.first == :VictoryPoint])
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

HumanPlayer(team::Symbol, io::IO) = HumanPlayer(Player(team), io)
HumanPlayer(team::Symbol) = HumanPlayer(team, stdin)

DefaultRobotPlayer(team::Symbol) = DefaultRobotPlayer(Player(team))
TestRobotPlayer(team::Symbol) = TestRobotPlayer(Player(team))
TestRobotPlayer(player::Player) = TestRobotPlayer(player, 5, 5, Dict(:Wood => 1, :Grain => 1, :Pasture => 1, :Brick => 1, :Stone => 1))

