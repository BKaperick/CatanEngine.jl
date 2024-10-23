# Catan.jl

An engine for adding AI players to a party of the extremely popular board game [Settlers of Catan](https://www.catan.com/)

## How to run the game
To launch a new or existing game:
`$julia Catan.jl [CONFIG FILE] [MAP FILE] [SAVE FILE]`

For example,

`$julia src/Catan.jl data/config.txt data/sample.csv save.txt`

* `data/config.txt` sets the label (e.g. a color) and player class (e.g. `HumanPlayer` or `DefaultRobotPlayer`) for each player.
* `data/sample.csv` sets the board layout
* `save.txt` is a file to write the game history for saving and reloading previous games.  If the file already exists, it will be read and the game state will be initialized by executing the progress denoted in this file.

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

