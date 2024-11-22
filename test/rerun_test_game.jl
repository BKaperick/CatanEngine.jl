include("runtests.jl")

logger = ConsoleLogger(stderr, Logging.Debug)
global_logger(logger)
setup_and_do_robot_game(ARGS[1])
