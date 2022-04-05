mutable struct Player
    resources::Dict{Symbol,Int}
    vp_count::Int
    dev_cards::Dict{Symbol,Int}
    dev_cards_used::Dict{Symbol,Int}
end
Player() = Player(Dict(), 0, Dict(), Dict())

mutable struct Public_Info
    resource_count::Int
    dev_cards_count::Int
    dev_cards_used::Dict{Symbol,Int}
    vp_count::Int
end
mutable struct Private_Info
    resources::Dict{Symbol,Int}
    dev_cards::Dict{Symbol,Int}
    private_vp_count::Int
end

mutable struct Construction
end

mutable struct Road
    coord1::Tuple{Int,Int}
    coord2::Tuple{Int,Int}
    team
end

mutable struct Building
    coord::Tuple{Int,Int}
    type::Symbol
end

mutable struct Board
    tile_to_dicevalue::Dict{Symbol,Int}
    tile_to_resource::Dict{Symbol,Symbol}
    buildings::Array{Building,1}
    roads::Array{Road,1}
    robber_coord::Tuple
end
