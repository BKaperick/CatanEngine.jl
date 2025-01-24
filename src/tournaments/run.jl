include("../main.jl")
include("../apis/player_api.jl")
include("structs.jl")
include("helpers.jl")
include("mutation_rule_library.jl")


team_to_mutation = Dict([
                       :Blue => Dict(),
                       :Green => Dict(),
                       :Cyan => Dict(),
                       :Yellow => Dict()
                      ])

# Suppress all normal logs
logger = ConsoleLogger(stderr, Logging.Warn)
global_logger(logger)
SAVE_GAME_TO_FILE = false
#SAVEFILEIO = open(SAVEFILE, "a")

map_file = "$(DATA_DIR)/_temp_map_file.csv"
winners = Dict()

# Number of games to play per map
# Number of maps to generate
# Number of epochs (1 epoch is M*N games) to run
#tourney = Tournament(5,4,10, :Sequential)
tourney = Tournament(5,4,10, :FiftyPercentWinnerStays)
#tourney = Tournament(5,4,10, :SixtyPercentWinnerStays)


for k=1:tourney.epochs
    for (w,v) in winners
        winners[w] = 0
    end
    for (player,mt) in team_to_mutation
        println("$(player): $(print_mutation(mt))")
    end
    for j=1:tourney.maps_per_epoch
        map = generate_random_map(map_file)
        for i=1:tourney.games_per_map
            game = Game(generate_players())
            _,winner = initialize_and_do_game!(game, map_file)

            w = winner
            if winner != nothing
                w = winner.player.team
            end
            if haskey(winners, w)
                winners[w] += 1
            else
                winners[w] = 1
            end
            if winner != nothing
                println("Game $i: $(winner.player.team)")
            end
        end
    end
    # Don't assign new mutations on the last one so we can see the results
    if k < tourney.epochs
        ordered_winners = order_winners(winners)
        apply_mutation_rule![tourney.mutation_rule](team_to_mutation, ordered_winners)
    end
end
println(winners)

for (player,mt) in team_to_mutation
    println("$(player): $(print_mutation(mt))")
end
