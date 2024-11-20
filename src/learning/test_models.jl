include("train_model.jl")
include("../structs.jl")
include("../players/empath_robot_player.jl")


get_row = x -> Vector(mach.data[1][x,1:end])
tp = x -> _predict_model_feature_vec(mach, get_row(x))
