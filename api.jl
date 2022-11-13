function input(prompt::String)
    println(prompt)
    return readline()
end

macro log(x)
    log_action(LOGFILE, x)
end

function create_board(csvfile::String)
    log_action("_create_board", csvfile)
    _create_board(csvfile)
end
function _create_board(csvfile::String)
    global BOARD = read_map(csvfile)
end

print_board() = print_board(BOARD)

function build_city(team, coord)
    log_action("_build_city", team, coord)
    _build_city(board, team, coord)
end
_build_city(team, coord) = build_building(BOARD, TEAM_TO_PLAYER[team], coord, :City)

function build_settlement(team, coord)
    log_action("_build_settlement", team, coord)
    _build_settlement(team, coord)
end
_build_settlement(team, coord) = build_building(BOARD, TEAM_TO_PLAYER[team], coord, :Settlement)

function build_road(team::Symbol, coord1::Tuple{Int, Int}, coord2::Tuple{Int, Int})
    log_action("_build_road", team, coord1, coord2)
    _build_road(team, coord1, coord2)
end
_build_road(team::Symbol, coord1::Tuple{Int, Int}, coord2::Tuple{Int, Int}) = build_road(BOARD, TEAM_TO_PLAYER[team], coord1, coord2)

function harvest_resource(team::Symbol, resource::Symbol, quantity::Int)
    log_action("_harvest_resource", team, resource, quantity)
    _harvest_resource(team, resource, quantity)
end
_harvest_resource(team::Symbol, resource::Symbol, quantity::Int) = harvest_resource(BOARD, TEAM_TO_PLAYER[team], resource, quantity)
