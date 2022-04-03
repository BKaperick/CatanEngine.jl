function human_build_settlement(buildings, team)        
    coord_settlement_str = input("$team places a settlement:\n")
    coord_settlement = Tuple([parse(Int, x) for x in split(coord_str, ' ')])
    build_settlement(buildings, team, coord_settlement)
end
function human_build_road(roads, team)        
    coord_road_str = input("$team places a road:\n")
    coord_road = [parse(Int, x) for x in split(coord_str, ' ')]
    coord_road1 = Tuple(coord_road[1:2])
    coord_road2 = Tuple(coord_road[3:4])
    build_road(roads, team, coord_road1, coord_road2)
end
