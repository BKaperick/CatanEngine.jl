include("main.jl")
include("apis/player_api.jl")

SAVEFILEIO = open(SAVEFILE, "a")

team_to_mutation = Dict([
                       :Blue => Dict(),
                       :Green => Dict(),
                       :Cyan => Dict(),
                       :Yellow => Dict()
                      ])

function assign_new_mutations!(team_to_mutation, unorderd_winners)
    winners = [k for (k,v) in sort(collect(unorderd_winners), by=x -> x.second, rev=true) if k != nothing]

    # ordered_winners[1] - don't mutate, he's winning
    # ordered_winners[2] - mutate, he's close to winning
    team_to_mutation[winners[2]] = get_new_mutation(team_to_mutation[winners[2]])
    # ordered_winners[3] - mutate, he's close to winning
    team_to_mutation[winners[3]] = get_new_mutation(team_to_mutation[winners[3]])
    # ordered_winners[4] - mutate winner's dict, see if we can beat it
    team_to_mutation[winners[4]] = get_new_mutation(deepcopy(team_to_mutation[winners[1]]))
end

function print_mutation(mutation::Dict)
    return join(["$c => $v" for (c,v) in mutation if v != 0], ", ")
end

generate_players() = Vector{MutatedEmpathRobotPlayer}([MutatedEmpathRobotPlayer(team, mutation) for (team, mutation) in team_to_mutation])

# Suppress all normal logs
logger = ConsoleLogger(stderr, Logging.Warn)
global_logger(logger)
SAVE_GAME_TO_FILE = false

# Number of games to play per map
N = 5
# Number of maps to generate
M = 4
# Number of epochs (1 epoch is M*N games) to run
P = 10


map_file = "$(DATA_DIR)/_temp_map_file.csv"
winners = Dict()
for k=1:P
    for (w,v) in winners
        winners[w] = 0
    end
    for (player,mt) in team_to_mutation
        println("$(player): $(print_mutation(mt))")
    end
    for j=1:M
        map = generate_random_map(map_file)
        for i=1:N
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
    if k < P
        assign_new_mutations!(team_to_mutation, winners)
    end
end
println(winners)

for (player,mt) in team_to_mutation
    println("$(player): $(print_mutation(mt))")
end
