
get_tile_from_human_tile_description(desc) = Symbol(uppercase(desc))
function get_coords_from_human_tile_description(desc...)
    coords = []
    for d in desc
        push!(coords, get_coord_from_human_tile_description(desc)...)
    end
    return coords
end

function _intersect_tiles_string_coords(desc)
    desc = uppercase(desc)
    coords = [TILE_TO_COORDS[Symbol(d)] for d in desc]
    return intersect(coords...)
end

function get_coord_from_human_tile_description(desc)
    println("parsing $desc")
    if length(desc) == 1
        return get_tile_from_human_tile_description(desc)
    elseif length(desc) > 3
        return get_coords_from_human_tile_description(split(desc, " "))
    end
    
    # Single coordinate
    if length(desc) == 3
        return pop!(_intersect_tiles_string_coords(desc))
    end

    if length(desc) == 2
        inter = _intersect_tiles_string_coords(desc)
        return [pop!(inter), pop!(inter)]
    end
end

function human_move_robber(team)        
    player = TEAM_TO_PLAYER[team]
    coord_settlement_str = input("$team places a settlement:")
    coord_settlement = Tuple([parse(Int, x) for x in split(coord_settlement_str, ' ')])
    build_settlement(buildings, player, coord_settlement)
end

function human_build_road(board, player)        
    coord_road_str = input("$(player.team) places a road:")
    coord_road = [parse(Int, x) for x in split(coord_road_str, ' ')]
    coord_road1 = Tuple(coord_road[1:2])
    coord_road2 = Tuple(coord_road[3:4])
    build_road(board, player, coord_road1, coord_road2)
end
function human_roll_dice(team)
    value_str = input("$team rolls the dice")
    return parse(Int, value_str)
end
function human_move_robber(board::Board, team)
    coord_robber_str = input("$team moves robber:")
    coord_robber = [parse(Int, x) for x in split(coord_road_str, ' ')]
    board.robber_coord = coord
end
function human_do_robber_move(board, team)
    human_move_robber(board, team)
    for (t,p) in TEAM_TO_PLAYER
        r_count = Public_Info(p).resource_count
        if r_count > 7
            to_lose = random_sample_resources(p.resources, Int(floor(r_count / 2)))
            for r in to_lose
                p.resources[r] -= 1
            end
        end
        if TEAM_TO_TYPE[t] == :Robo
            r = random_sample_resources(p.resources, 1)
            println("$team steals 1 $r from $t")
            p.resources[r] -= 1
        end
    end  
end

human_build_settlement(board, team) = human_build_settlement(board, TEAM_TO_PLAYER[team])
human_build_road(board, team) = human_build_road(board, TEAM_TO_PLAYER[team])

@assert get_coord_from_human_tile_description("nqr") == (5,4)
@assert get_coord_from_human_tile_description("nqr") == (5,4)
