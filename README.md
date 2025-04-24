# CatanEngine.jl

A full Julia engine for playing the extremely popular board game [Settlers of Catan](https://www.catan.com/) with a mixture of human and custom scripted players.

 For examples of scripted players and how to apply more advanced ML/RL algorithms, check out the sister repo [CatanLearning.jl](https://github.com/BKaperick/CatanLearning.jl/).

## How to run the game
To launch a new or existing game:
Set up a basic configuration file, such as
```toml filename="Configuration.toml"
# Changing any configs you want (defaults in ./DefaultConfiguration.toml)
PRINT_BOARD = true

# Setting up the types of players.  
# One human (blue) against three scripted players of type `DefaultRobotPlayer`
[PlayerSettings]
[PlayerSettings.blue]
TYPE = "HumanPlayer"
[PlayerSettings.cyan]
TYPE = "DefaultRobotPlayer"
[PlayerSettings.green]
TYPE = "DefaultRobotPlayer"
[PlayerSettings.yellow]
TYPE = "DefaultRobotPlayer"
```

```julia
using Catan
configs = Catan.parse_configs("Configuration.toml")
board, winner = Catan.run(configs)
```

## Developer Notes
### Board representation
```
        (7)      (6) 
       61-62-63-64-65-66-67
       |  Q  |  R  |  S  | (5)
    51-52-53-54-55-56-57-58-59
(8) |  M  |  N  |  O  |  P  |
 41-42-43-44-45-46-47-48-49-4!-4@
 |  H  |  I  |  J  |  K  |  L  |(4)
 31-32-33-34-35-36-37-38-39-3!-3@
 (9)|  D  |  E  |  F  |  G  |
    21-22-23-24-25-26-27-28-29
       |  A  |  B  |  C  |(3)
       11-12-13-14-15-16-17
        (1)      (2) 
``` 

Note: the numbers (x) are the ports

### Map file

The map file (`data/sample.csv` in the above example) is a 3-column csv file with values `Tile,Dice,Resource`
where:
* `Tile` is a single capital letter A-S denoting the hexagon tile corresponding to the above board sketch.
    **Warning** These are purely internal IDs and do not correspond to the letters on the physical Catan tokens.
* `Dice` is a single integer 2-12 denoting the dice token placed on the hexagon (use 7 for the desert)
* `Resource` is a single letter denoting the resource: w[ood],s[tone],g[rain],b[rick],p[asture]

### Debugging

For convenience, setting `PRINT_BOARD = true` in the configuration file will print a color representation of the map state after each turn:

![image](https://github.com/user-attachments/assets/17c5b8b6-1592-4c7d-9b84-6666e4334b7f)


### Defining a new player

#### Initialize the player type
Define a new player called `NewRobotPlayer` requires the definition in [./src/players/structs.jl](https://github.com/BKaperick/Catan.jl/blob/master/src/players/structs.jl) inheriting from `RobotPlayer`:

```julia
mutable struct NewRobotPlayer <: RobotPlayer
    player::Player

    # Here, Insert any other fields to store intermediary data or parameters between turns
end
```

and it needs to have the constructor
```julia
NewRobotPlayer(team::Symbol, configs::Dict) = NewRobotPlayer(Player(team, configs))
```
and you need to add a register the player via
```julia
add_player_to_register("NewRobotPlayer", (t,c) -> NewRobotPlayer(t,c))
```

#### Define the player behavior
Add a file in the directory [./src/players](https://github.com/BKaperick/Catan.jl/blob/master/src/players) and implement any of the methods in the header of [./src/players/robot_player.jl](https://github.com/BKaperick/Catan.jl/blob/master/src/players/robot_player.jl) for which you want customized behavior.

For example, to give your `NewRobotPlayer` a custom algorithm to accept trades, implement the following function definition:

```julia
function choose_accept_trade(board::Board, player::NewRobotPlayer, from_player::PlayerPublicView, from_goods::Vector{Symbol}, to_goods::Vector{Symbol})::Bool
    # Define a custom algorithm for how the NewRobotPlayer will decide to accept a proposed trade or not.
end
```
