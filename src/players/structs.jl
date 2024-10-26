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

