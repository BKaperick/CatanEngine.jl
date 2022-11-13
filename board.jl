mutable struct Board
    tile_to_dicevalue::Dict{Symbol,Int}
    tile_to_resource::Dict{Symbol,Symbol}
    coord_to_building::Dict{Tuple,Building}
    coord_to_roads::Dict{Tuple,Set{Road}}
    empty_spaces::Vector
    buildings::Array{Building,1}
    roads::Array{Road,1}
    robber_tile::Symbol
    spaces::Vector
end

Board(tile_to_value::Dict, tile_to_resource::Dict, robber_tile::Symbol) = Board(tile_to_value, tile_to_resource, Dict(), Dict(), initialize_empty_board(DIMS), [], [], robber_tile, initialize_empty_board(DIMS))

function initialize_empty_board(dimensions)
    spaces = []
    for d in dimensions
        push!(spaces, repeat([Nothing], d))
    end
    return spaces
end

function get_empty_spaces(board)
    empty = []
    building_coords = keys(board.coord_to_building)
    for (r,row) in enumerate(board.spaces)
        for (c,value) in enumerate(row)
            if value == Nothing && ~(value in building_coords)
                push!(empty, (r,c))
            end
        end
    end
    return empty
end
function get_neighbors(coord)
    neighbors = []
    r,c = coord
    if 1 < c
        push!(neighbors, (r,c-1))
    end
    if c < DIMS[r]
        push!(neighbors, (r,c+1))
    end
    if isodd(c)
        if r < length(DIMS)-1
            if DIMS[r]  < DIMS[r+1]
                push!(neighbors, (r+1,c+1))
            elseif DIMS[r] == DIMS[r+1]
                push!(neighbors, (r+1,c))
            end
        elseif r > 1
            if DIMS[r-1]  > DIMS[r]  
                push!(neighbors, (r-1, c+1))
            elseif DIMS[r-1] == DIMS[r]  
                push!(neighbors, (r-1,c))
            end
        end
    elseif r > 1 && DIMS[r-1]  < DIMS[r]
        push!(neighbors, (r-1, c-1))
    end
    return Set(neighbors)
end

function print_right_side(b,x,y)
    b[y][x] = "o"
    b[y+1][x-1] = "/"
    b[y-1][x-1] = "\\"
end
function right_angle(b,x,y)
    horizontal(b,x-3,y)
    b[y+2][x+2] = "o"
    b[y+1][x+1] = "\\"
end
function hexagon(board, tile, b,x,y)
    # Draw base shape
    left_angle(b,x,y)
    right_angle(b,x+3,y)
    upper_left_angle(b,x,y+4)
    upper_right_angle(b,x+3,y+4)

    # Add tile info
    b[y+2][x+1] = string(string(board.tile_to_resource[tile])[1])
    number = string(board.tile_to_dicevalue[tile])
    if length(number) == 2
        b[y+2][x+2] = string(number[1])
        b[y+2][x+3] = string(number[2])

    else
        b[y+2][x+2] = number
    end

    # Add coordinate info
    coords = cyclic_sort(collect(TILE_TO_COORDS[tile]))
    for (v,c) in zip(vertices(x,y),coords)
        if haskey(board.coord_to_building, c)
            building_str = print_building(board.coord_to_building[c])
            println("Tile $tile: adding $building_str at $(c[1]),$(c[2])")
            b[v[2]][v[1]] = building_str
        end
    end
    
    # Add edge info
    vertices_list = vertices(x,y)
    println(coords)
    for (i,(e,c)) in enumerate(zip(edges(x,y),coords))
        if haskey(board.coord_to_roads, c)
            roads = board.coord_to_roads[c]
            for road in roads
                c2 = road.coord1 == c ? road.coord2 : road.coord1
                if i < length(vertices_list)
                    println("Tile $tile: found road $(print_road(road)) at $(c[1]),$(c[2]) ($c2 -- $(coords[i+1]))")
                    if c2 == coords[i+1] # TODO: not the correct condition
                        road_str = print_road(road)
                        println("Tile $tile: adding road $road_str at $(e[1]),$(e[2])")
                        b[e[2]][e[1]] = road_str
                    end
                end
            end
        end
    end
end
#  vertices:
#    5--4
#   /    \
#  6      3
#   \    /
#    1--2
# edges:
#    o-6o
#   5    3
#  o      o
#   4    2
#    o1-o
#
#
test = [(1,1),(1,2),(1,3),(2,2),(2,3),(2,4)]
function cyclic_sort(coords)
    minx = minimum([c[1] for c in coords])
    bottom = sort([c for c in coords if c[1] == minx])
    top = sort([c for c in coords if c[1] != minx], by= x -> -x[2])
    append!(bottom,top)
    return bottom
end
function vertices_to_edge(x1,y1,x2,y2)
return (Int((x1 + x2) / 2),Int((y1 + y2) / 2))
end
function vertices(x,y)
    # Ordering is important so that it's compatible with the sort of TILE_TO_COORDS[tile]
    return [(x,y+4),(x+3,y+4),(x+5,y+2),(x+3,y),(x,y),(x-2,y+2)]
end
function edges(x,y)
    # Ordering is important so that it's compatible with the sort of TILE_TO_COORDS[tile]
    return [
    (x+1,y+4),
    (x+4,y+3),
    (x+4,y+1),
    (x+2,y),
    (x-1,y+1),
    (x-1,y+3)
    ]
end

function horizontal(b,x,y)
    b[y][x] = "o"
    b[y][x+3] = "o"
    b[y][x+1] = "-"
    b[y][x+2] = "-"
end
function upper_left_angle(b,x,y)
    horizontal(b,x,y)
    b[y-1][x-1] = "\\"
    b[y-2][x-2] = "o"
end
function upper_right_angle(b,x,y)
    horizontal(b,x-3,y)
    b[y-1][x+1] = "/"
    b[y-2][x+2] = "o"
end

function left_angle(b,x,y)
    horizontal(b,x,y)
    b[y+2][x-2] = "o"
    b[y+1][x-1] = "/"
end
function double_left_angle(b,x,y)
    left_angle(b,x,y)
    b[y-1][x-1] = "\\"
end
function double_right_angle(b,x,y)
    right_angle(b,x,y)
    b[y-1][x+1] = "/"
end

function print_board(board::Board)
    X = 48
    Y = 34
    b = repeat([repeat([" "], X)], Y)
    for (i,r) in enumerate(b)
        b[i] = copy(r)
    end 
    
    hexagon(board,:S,b,23,1)
    hexagon(board,:R,b,18,3)
    hexagon(board,:Q,b,13,5)
    
    hexagon(board,:P,b,28,3)
    hexagon(board,:O,b,23,5)
    hexagon(board,:N,b,18,7)
    hexagon(board,:M,b,13,9)
    
    hexagon(board,:L,b,33,5)
    hexagon(board,:K,b,28,7)
    hexagon(board,:J,b,23,9)
    hexagon(board,:I,b,18,11)
    hexagon(board,:H,b,13,13)
    
    hexagon(board,:G,b,33,9)
    hexagon(board,:F,b,28,11)
    hexagon(board,:E,b,23,13)
    hexagon(board,:D,b,18,15)
    
    hexagon(board,:C,b,33,13) # (2,4),(2,5),(1,5),(1,4),(1,3),(2,3)
    hexagon(board,:B,b,28,15) # (2,4),(2,5),(1,5),(1,4),(1,3),(2,3)
    hexagon(board,:A,b,23,17) # (2,3),(2,4),(1,3),(1,2),(1,1),(2,2)

    for (i,r) in enumerate(b)
        println(join(r))
    end
    return b
end

@assert get_neighbors((3,10)) == Set([(3,9),(3,11),(2,9)])
@assert get_neighbors((6,3)) == Set([(6,2),(6,4),(5,4)])
@assert get_neighbors((1,7)) == Set([(1,6),(2,8)])
@assert get_neighbors((1,7)) == Set([(1,6),(2,8)])
