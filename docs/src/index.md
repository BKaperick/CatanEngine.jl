# Catan.jl - a Settlers of Catan game engine

A full Julia engine for playing the extremely popular board game [Settlers of Catan](https://www.catan.com/) with a mixture of human and custom scripted players.  For examples of scripted players and how to apply more advanced ML/RL algorithms, check out the sister repo [CatanLearning.jl](https://github.com/BKaperick/CatanLearning.jl/).

## How to run the game
To launch a new game, set up a configuration file with the desired player types, and any gameplay configuration.

For example,
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

If this file is saved as `Configuration.toml`, then we can run one game with the following script:
```julia
using Catan
configs = Catan.parse_configs("Configuration.toml")
board, winner = Catan.run(configs)
```
