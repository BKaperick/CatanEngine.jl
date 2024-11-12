using Random
using CSV
using MLJ
using DataFrames
import DataFramesMeta as DFM
using DelimitedFiles

function load_tree_model()
    @load DecisionTreeClassifier pkg=BetaML
end
"""

"""
function train_model_from_csv(tree, csv_name="../../features.csv")

    # Load data
    data, header = readdlm(csv_name, ',', header=true)
    df = DataFrame(data, vec(header))
    coerce!(df, :WonGame => Multiclass{2})
    df = DFM.@transform(df, :WonGame)
    df, df_test = partition(df, 0.7, rng=123)
    
    # Fit model machine to data
    y, X = unpack(df, ==(:WonGame));
    mach = machine(tree, X, y)
    fit!(mach)

    return mach
end

function predict_model(machine, board, player)
    features = [x for x in compute_features(board, player.player)]
    feature_vals = [x[2] for x in features]
    data = reshape(feature_vals, 1, length(feature_vals))
    header = [get_csv_friendly(f[1]) for f in features]
    println(data)
    println(header)
    df = DataFrame(data, vec(header))
    return predict(machine, df)
    #return MLJ.predict(machine, df)
end
