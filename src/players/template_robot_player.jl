function choose_accept_trade(board::Board, player::RobotPlayer, from_player::Player, from_goods::Vector{Symbol}, to_goods::Vector{Symbol})::Bool
end
function choose_building_location(board::Board, players::Vector{PlayerType}, player::RobotPlayer, building_type::Symbol, is_first_turn::Bool = false)::Tuple
end
function choose_cards_to_discard(player::RobotPlayer, amount::Int)::Vector{Symbol}
end
function choose_monopoly_resource(board::Board, players::Vector{PlayerType}, player::RobotPlayer)::Symbol
end
function choose_place_robber(board::Board, players::Vector{PlayerType}, player::RobotPlayer)::Symbol
end
function choose_play_devcard(board::Board, players::Vector{PlayerType}, player::RobotPlayer, devcards::Dict)::Union{Symbol,Nothing}
end
function choose_next_action(game::Game, board::Board, players::Vector{PlayerType}, player::RobotPlayer, actions::Set{Symbol})
end
function choose_road_location(board::Board, players::Vector{PlayerType}, player::RobotPlayer, is_first_turn::Bool = false)::Union{Nothing,Vector{Tuple}}
end
function choose_robber_victim(board::Board, player::RobotPlayer, potential_victims...)::PlayerType
end
function choose_who_to_trade_with(board::Board, player::RobotPlayer, players::Vector{PlayerType})::Symbol
end
function choose_year_of_plenty_resources(board, players::Vector{PlayerType}, player::RobotPlayer)::Tuple{Symbol, Symbol}
end
function
end
function choose_card_to_steal(player::RobotPlayer)::Symbol
    return choose_card_to_steal(player)
end
