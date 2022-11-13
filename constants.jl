using Dates

LOGFILE = "log_$(Dates.format(now(), "HHMMSS")).txt"
VP_AWARDS = Dict([
                  :Settlement => 1,
                  :City => 2,
                  :Road => 0
                 ])
COSTS = Dict([
              :Settlement => Dict([
                                   :Wood => 1,
                                   :Brick => 1,
                                   :Pasture => 1,
                                   :Grain => 1
                                  ]),
              :City => Dict([
                             :Grain => 2,
                             :Stone => 3
                            ]),
              :DevelopmentCard => Dict([
                                        :Pasture => 1,
                                        :Stone => 1,
                                        :Grain => 1
                                       ]),
              :Road => Dict([
                             :Brick => 1,
                             :Wood => 1
                            ])
             ])

HUMAN_RESOURCE_TO_SYMBOL = Dict([
"W" => :Wood,
"S" => :Stone,
"G" => :Grain,
"B" => :Brick,
"P" => :Pasture,
"D" => :Desert
])

RESOURCE_TO_COUNT = Dict([
    :Wood => 4
    :Stone => 3
    :Grain => 4
    :Brick => 3
    :Pasture => 4
    :Desert => 1
   ]) 
TEAMS = [
         :Blue,
         #:Orange,
         #:Green,
         :Robo
        ]
TEAM_TO_TYPE = Dict(
         :Blue => :Human,
         :Orange => :Human,
         :Green => :Human,
         :Robo => :Robot
        )
TEAM_TO_PLAYERTYPE = Dict(
         :Blue => HumanPlayer,
         :Orange => HumanPlayer,
         :Green => HumanPlayer,
         :Robo => RobotPlayer
        )
TEAM_TO_PLAYER = Dict([t => TEAM_TO_PLAYERTYPE[t](t) for t in TEAMS])
PLAYERS = collect(values(TEAM_TO_PLAYER))
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
TILES = [t for t in keys(TILE_TO_COORDS)]
COORD_TO_TILES = Dict()
for elem in TILE_TO_COORDS
    # print("elem: ", elem, "\n")
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
DIMS = [7,9,11,11,9,7]

