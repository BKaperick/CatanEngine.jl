To launch the standard test suite, run

`$julia --project=.. ./runtests.jl`

and to facilitate the debugging of rare non-deterministic errors, you can additionally pass `--neverend`, i.e.

`$julia --project=.. ./runtests.jl --neverend`

which will run the standard test suite, and then will continually run
1. Run a 4-player game with `DefaultRobotPlayer` players
2. Re-run the game from the generated log file in `./test/data/`.
