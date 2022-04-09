mutable struct Board
    tile_to_dicevalue::Dict{Symbol,Int}
    tile_to_resource::Dict{Symbol,Symbol}
    empty_spaces::Vector
    buildings::Array{Building,1}
    roads::Array{Road,1}
    robber_tile::Symbol
end

Board(tile_to_value::Dict, tile_to_resource::Dict, robber_tile::Symbol) = Board(tile_to_value, tile_to_resource, initialize_empty_board(DIMS), [], [], robber_tile)

function initialize_empty_board(dimensions)
    spaces = []
    for d in dimensions
        push!(spaces, repeat([Nothing], d))
    end
    return spaces
end

function get_empty_spaces(board)
    empty = []
    for (r,row) in enumerate(board.empty_spaces)
        for (c,value) in enumerate(row)
            if value == Nothing
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
function hexagon(b,x,y)
    left_angle(b,x,y)
    right_angle(b,x+3,y)
    upper_left_angle(b,x,y+4)
    upper_right_angle(b,x+3,y+4)
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
#2 space, 6 space
#  o--o      o--o
# /    \    /    \
#o      o--o      o
# \    /    \    /
#  o--o      o--o
# 
#   o--o
#  /
# o
#
function print_board(board::Board)
    R = 45
    b = repeat([repeat([" "], R)], R)
    for (i,r) in enumerate(b)
        b[i] = copy(r)
    end 
    
    hexagon(b,23,1)
    hexagon(b,18,3)
    hexagon(b,13,5)
    
    hexagon(b,28,3)
    hexagon(b,23,5)
    hexagon(b,18,7)
    hexagon(b,13,9)
    
    hexagon(b,33,5)
    hexagon(b,28,7)
    hexagon(b,23,9)
    hexagon(b,18,11)
    hexagon(b,13,13)
    
    hexagon(b,33,9)
    hexagon(b,28,11)
    hexagon(b,23,13)
    hexagon(b,18,15)
    
    hexagon(b,33,13)
    hexagon(b,28,15)
    hexagon(b,23,17)

    for (i,r) in enumerate(b)
        #r[1] = string(i%10)
        println(join(r))
    end
    return b
end

function broken_print_board(board::Board)
    link = "o--o"
    gap(x) = repeat(" ", x)
    R = maximum(DIMS)
    interior = false
    for r in DIMS
        if interior
            print("o")
            print(gap(6))
        else
            print(gap(2))
        end
        #print(repeat(" ", Int(offset)))
        for c in 1:2:(r-1)
            print(link)
            print(gap(6))
        end
        if interior
            print(gap(6))
            print("o")
        end
        println("")
        print(gap(1))
        if (interior)
            println(repeat("\\    /    ", Int(round(r / 2))))
        else
            println(repeat("/    \\    ", Int(round(r / 2))))
        end
        interior = !interior
    end
end

@assert get_neighbors((3,10)) == Set([(3,9),(3,11),(2,9)])
@assert get_neighbors((6,3)) == Set([(6,2),(6,4),(5,4)])
@assert get_neighbors((1,7)) == Set([(1,6),(2,8)])
@assert get_neighbors((1,7)) == Set([(1,6),(2,8)])

board = read_map("sample.csv")
b = print_board(board)
