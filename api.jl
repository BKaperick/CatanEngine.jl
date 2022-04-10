
function harvest_resource(team::Symbol, resource::Symbol, quantity::Int)
    harvest_resource(TEAM_TO_PLAYER[team], resource, quantity)
end
