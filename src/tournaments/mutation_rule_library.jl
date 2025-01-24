include("helpers.jl")

apply_mutation_rule! = Dict([
    :Sequential => (tm, w) -> sequential_assign_new_mutations!(tm, w),
    :FiftyPercentWinnerStays => (tm, w) -> percent_winner_stays_assign_new_mutations!(tm, w, 50),
    :SixtyPercentWinnerStays => (tm, w) -> percent_winner_stays_assign_new_mutations!(tm, w, 60)
                                 ])

function sequential_assign_new_mutations!(team_to_mutation, winners)
    # ordered_winners[1] - don't mutate, he's winning
    # ordered_winners[2] - mutate, he's close to winning
    mutate!(team_to_mutation, winners[2])
    # ordered_winners[3] - mutate, he's close to winning
    mutate!(team_to_mutation, winners[3])
    # ordered_winners[4] - mutate winner's dict, see if we can beat it
    mutate_other!(team_to_mutation, winners[4], winners[1])
end


"""
    `percent_winner_stays_assign_new_mutations!(team_to_mutation, winners, percent)`

If one player manages to win `percent_threshold` percent of games from this epoch (excluding draws), then he doesn't mutate.  All other players mutate.
"""
function percent_winner_stays_assign_new_mutations!(team_to_mutation, winners, percent_threshold)
    total_games = sum([v for (k,v) in winners])
    win_percents = [100*v / total_games for (k,v) in winners]
    if win_percents[1] < percent_threshold
        mutate!(team_to_mutation, winners[1])
    end
    mutate!(team_to_mutation, winners[2])
    mutate!(team_to_mutation, winners[3])
    mutate!(team_to_mutation, winners[4])
end
