mutable struct Player
    team::Symbol
    resources::Dict{Symbol,Int}
    vp_count::Int
    dev_cards::Dict{Symbol,Int}
    dev_cards_used::Dict{Symbol,Int}
end
Player(team::Symbol) = Player(team, Dict(), 0, Dict(), Dict())

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

mutable struct Construction
end

mutable struct Road
    coord1::Tuple{Int,Int}
    coord2::Tuple{Int,Int}
    player::Player
end

mutable struct Building
    coord::Tuple{Int,Int}
    type::Symbol
    player::Player
end

