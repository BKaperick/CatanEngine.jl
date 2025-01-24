using LinearAlgebra

"""
This vector defines the mutation dimensions.
For the first iteration, it is just the choice of actions to do on a given turn, but the framework can be later extended to mutate higher level objectives as well.
"""
canonical_mutation_vector = [
    # ACTIONS
    :ProposeTrade,
    :ConstructCity,
    :ConstructSettlement,
    :ConstructRoad,
    :BuyDevCard,
    :PlayDevCard
]


"""
    get_new_mutation(last_mutation::Dict{Symbol, AbstractFloat})

Randomly perturb the existing mutation returning transformed dict
"""
function get_new_mutation(last_mutation::Dict, magnitude::AbstractFloat)::Dict{Symbol, AbstractFloat}
    mutation_vector = .5 .- rand(length(canonical_mutation_vector))
    mutation_vector = magnitude * mutation_vector / norm(mutation_vector)
    
    if length(keys(last_mutation)) == 0
        last_mutation = Dict([(key, 0.0) for key in canonical_mutation_vector])
    end
    for (i,key) in enumerate(canonical_mutation_vector)
        last_mutation[key] += mutation_vector[i]
    end
    return last_mutation
end

function mutate!(team_to_mutation, player; magnitude=.2)
    team_to_mutation[player[1]] = get_new_mutation(team_to_mutation[player[1]], magnitude)
end

function mutate_other!(team_to_mutation, player_to_mutate, other_player; magnitude=.2)
    team_to_mutation[player_to_mutate[1]] = get_new_mutation(deepcopy(team_to_mutation[other_player[1]]), magnitude)
end
