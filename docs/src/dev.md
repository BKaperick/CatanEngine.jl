# Miscellaneous Developer Notes
## Board representation
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

## Map file

The map file (`data/sample.csv` in the above example) is a 3-column csv file with values `Tile,Dice,Resource`
where:
* `Tile` is a single capital letter A-S denoting the hexagon tile corresponding to the above board sketch.
    **Warning** These are purely internal IDs and do not correspond to the letters on the physical Catan tokens.
* `Dice` is a single integer 2-12 denoting the dice token placed on the hexagon (use 7 for the desert)
* `Resource` is a single letter denoting the resource: w[ood],s[tone],g[rain],b[rick],p[asture]

## Debugging

For convenience, setting `PRINT_BOARD = true` in the configuration file will print a color representation of the map state after each turn:

![image](https://github.com/user-attachments/assets/17c5b8b6-1592-4c7d-9b84-6666e4334b7f)

