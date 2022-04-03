include("human.jl")
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

function get_public_info(player::Player)::Public_Info
    return Public_Info(
                       sum(values(player.resources)), 
                       sum(values(player.dev_cards)), 
                       player.vp_count)
end
function get_private_info(player::Player)::Private_Info
    return Private_Info(player.resources, player.dev_cards, player.vp_count)
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
end
Board(tile_to_value::Dict{Symbol,Int}, tile_to_resource::Dict{Symbol,Symbol}) = Board(tile_to_value, tile_to_resource, [], [])

TEAMS = [
         :Blue,
         :Orange,
         :Green,
         :Robo
        ]
TEAM_TO_PLAYER = Dict(
         :Blue => Player(),
         :Orange => Player(),
         :Green => Player(),
         :Robo => Player()
                     )
#function Int turn(Private_Info current_player, List{Public_Info} other_players):
#end

#     *-*-*-*-*-*-*
#     |   |   |   |
#   *-*-*-*-*-*-*-*-*
#   |   |   |   |   |
# *-*-*-*-*-*-*-*-*-*-*
# |   |   |   |   |   |
# *-*-*-*-*-*-*-*-*-*-*
#   |   |   |   |   |
#   *-*-*-*-*-*-*-*-*
#     |   |   |   |
#     *-*-*-*-*-*-*
#
# Coordinate in (row, column)

#       61-62-63-64-65-66-67
#       |  Q  |  R  |  S  |
#    51-52-53-54-55-56-57-58-59
#    |  M  |  N  |  O  |  P  |
# 41-42-43-44-45-46-47-48-49-4!-4@
# |  H  |  I  |  J  |  K  |  L  |
# 31-32-33-34-35-36-37-38-39-3!-3@
#    |  D  |  E  |  F  |  G  |
#    21-22-23-24-25-26-27-28-29
#       |  A  |  B  |  C  |
#       11-12-13-14-15-16-17

TILE_TO_COORDS = Dict(
                      :A => Set([(1,1),(1,2),(1,3),(2,2),(2,3),(2,4)]),
                      :B => Set([(1,3),(1,4),(1,5),(2,4),(2,5),(2,6)]),
                      :C => Set([(1,5),(1,6),(1,7),(2,6),(2,7),(2,8)]),
                      
                      :D => Set([(2,1),(2,2),(2,3),(3,2),(3,3),(3,4)]),
                      :E => Set([(2,3),(2,4),(2,5),(3,4),(3,5),(3,6)]),
                      :F => Set([(2,5),(2,6),(2,7),(3,6),(3,7),(3,8)]),
                      :G => Set([(2,7),(2,8),(2,9),(3,8),(3,9),(3,10)]),
                      
                      :H => Set([(3,1),(3,2),(3,3),(4,1),(4,2),(4,3)]),
                      :I => Set([(3,3),(3,4),(3,5),(4,3),(4,4),(4,5)]),
                      :J => Set([(3,5),(3,6),(3,7),(4,5),(4,6),(4,7)]),
                      :K => Set([(3,7),(3,8),(3,9),(4,7),(4,8),(4,9)]),
                      :L => Set([(3,9),(3,10),(3,11),(4,9),(4,10),(4,11)]),
                      
                      :M => Set([(5,1),(5,2),(5,3),(4,2),(4,3),(4,4)]),
                      :N => Set([(5,3),(5,4),(5,5),(4,4),(4,5),(4,6)]),
                      :O => Set([(5,5),(5,6),(5,7),(4,6),(4,7),(4,8)]),
                      :P => Set([(5,7),(5,8),(5,9),(4,8),(4,9),(4,10)]),
                      
                      :Q => Set([(6,1),(6,2),(6,3),(5,2),(5,3),(5,4)]),
                      :R => Set([(6,3),(6,4),(6,5),(5,4),(5,5),(5,6)]),
                      :S => Set([(6,5),(6,6),(6,7),(5,6),(5,7),(5,8)]),
                     )
COORD_TO_TILES = Dict()

function read_map(csvfile)::Board
    board = Board(Dict(), Dict(), [], [])
    # Resource is a value W[ood],S[tone],G[rain],B[rick],P[asture]
    resourcestr_to_symbol = Dict(
                                  "W" => :Wood,
                                  "S" => :Stone,
                                  "G" => :Grain,
                                  "B" => :Brick,
                                  "P" => :Pasture,
                                  "D" => :Desert
                                )
    file_str = read(csvfile, String)
    board_state = [strip(line) for line in split(file_str,'\n') if !isempty(strip(line)) && strip(line)[1] != '#']
    for line in board_state
        tile_str,dice_str,resource_str = split(line,',')
        tile = Symbol(tile_str)
        resource = resourcestr_to_symbol[uppercase(resource_str)]
        dice = parse(Int, dice_str)

        board.tile_to_dicevalue[tile] = dice
        board.tile_to_resource[tile] = resource
    end
    return board
end
                       
for elem in TILE_TO_COORDS
    print("elem: ", elem, "\n")
    tile = elem[1]
    coords = elem[2]
    for c in coords
        if haskey(COORD_TO_TILES,c)
            push!(COORD_TO_TILES[c], tile)
        else
            COORD_TO_TILES[c] = Set([tile])
        end
    end
end

function harvest_resource(team::Symbol, resource::Symbol, quantity::Int)
    for i in 1:quantity
        harvest_resource(TEAM_TO_PLAYER[team], resource)
    end
end

function build_settlement(buildings, team::Symbol, coord::Tuple{Int, Int})
    settlement = Building(coord, :Settlement)
    push!(buildings, settlement)
    player = TEAM_TO_PLAYER[team]
    player.vp_count += 1
    return settlement
end

function build_city(buildings, team::Symbol, coord::Tuple{Int, Int})
    city = Building(coord, :City)
    push!(buildings, city)
    player = TEAM_TO_PLAYER[team]
    player.vp_count += 2
    return city
end
function build_road(roads, team::Symbol, coord1::Tuple{Int, Int}, coord2::Tuple{Int, Int})
    road = Road(coord1, coord2, team)
    push!(roads, road)
    player = TEAM_TO_PLAYER[team]
    award_longest_road(roads)
    return road
end

function award_longest_road(roads::Array{Road, 1})
    # TODO
end

function harvest_resource(building::Building, resource::Symbol)
    if building.type == :Settlement
        harvest_resource(building.team, resource, 1)
    elseif building.type == :City
        harvest_resource(building.team, resource, 2)
    end
end

function building_gets_resource(building, dice_value)::Symbol
    tile = COORD_TO_TILES[building.coord]
    if TILE_TO_DICEVAL[tile] == dice_value
        return TILE_TO_RESOURCE[tile]
    end
    return Nothing
end

buildings = Array{Building,1}()
function roll_dice(buildings, value)

    # In all cases except 7, we allocate resources
    if value != 7
        for building in buildings
            resource = building_gets_resource(building, value)
            harvest_resource(building, resource)
        end
    end
end

function do_turn(buildings, team)
    value = human_roll_dice(team)
    roll_dice(buildings, value)
    if team == :Robo
    end
end
function someone_has_won()::Bool
    for kvp in TEAM_TO_PLAYER
        if kvp[2].vp_count >= 10
            return kvp[1]
        end
    end
    return Nothing
end
function initialize_game(csvfile::String)
    board = read_map(csvfile)
    do_game(board)
end


function do_first_turn(board)
    for team in TEAMS
        if team != :Robo
            human_build_settlement(board.buildings, team)
            human_build_road(board.roads, team)
        end
    end
    for team in reverse(TEAMS)
        if team != :Robo
            settlement = human_build_settlement(board.buildings, team)
            for tile in COORD_TO_TILES[settlement.coord]
                resource = board.tile_to_resource[tile]
                TEAM_TO_PLAYER[team].resources[resourse] += 1
            end
            human_build_road(board.roads, team)
        end
    end
end

        

function do_game(board::Board)
    do_first_turn(board.buildings, board.roads)
    while someone_has_won() == Nothing
        for team in TEAMS
            do_turn(board.buildings, team)
        end
    end
end
