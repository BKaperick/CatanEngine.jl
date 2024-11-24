include("runtests.jl")

logger = ConsoleLogger(stderr, Logging.Debug)
global_logger(logger)

if length(ARGS) > 0
    setup_and_do_robot_game(ARGS[1])
else
    setup_and_do_robot_game("./data/last_save.txt")
end
