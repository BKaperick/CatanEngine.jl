
build_city(board, team, coord) = build_building(board, team, coord, :City)
build_road(board, team::Symbol, coord1::Tuple{Int, Int}, coord2::Tuple{Int, Int}) = build_road(board, TEAM_TO_PLAYER[team], coord1, coord2)
build_settlement(board, team, coord) = build_building(board, team, coord, :Settlement)
harvest_resource(team::Symbol, resource::Symbol, quantity::Int) = harvest_resource(TEAM_TO_PLAYER[team], resource, quantity)
