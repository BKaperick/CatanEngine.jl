generate_players() = Vector{MutatedEmpathRobotPlayer}([MutatedEmpathRobotPlayer(team, mutation) for (team, mutation) in team_to_mutation])

function print_mutation(mutation::Dict)
    return join(["$c => $v" for (c,v) in mutation if v != 0], ", ")
end

function order_winners(unordered_winners)
    return [(k,v) for (k,v) in sort(collect(unordered_winners), by=x -> x.second, rev=true) if k != nothing]
end
