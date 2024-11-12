# Player API

This sub-directory contains each of the different defined players.

Some general rules to keep in mind:
1. *No* method defined in this directory can accept a `Game` as a parameter, as the `Game` contains a field for Players, which would leak hidden information to the player object.  Each player can only ever have access to the `PlayerPublicView` view of other players.
