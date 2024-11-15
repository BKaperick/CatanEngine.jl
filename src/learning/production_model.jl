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
