function input(prompt::String)
    println(prompt)
    return readline()
end

function human_build_settlement(buildings, team)        
    coord_settlement_str = input("$team places a settlement:")
    coord_settlement = Tuple([parse(Int, x) for x in split(coord_settlement_str, ' ')])
    build_settlement(buildings, team, coord_settlement)
end
function human_build_road(roads, team)        
    coord_road_str = input("$team places a road:")
    coord_road = [parse(Int, x) for x in split(coord_road_str, ' ')]
    coord_road1 = Tuple(coord_road[1:2])
    coord_road2 = Tuple(coord_road[3:4])
    build_road(roads, team, coord_road1, coord_road2)
end
function human_roll_dice(team)
    value_str = input("$team rolls the dice")
    return parse(Int, value_str)
end
