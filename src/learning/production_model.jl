using Random
using CSV
using MLJ
using DataFrames
import DataFramesMeta as DFM
using DelimitedFiles

function load_tree_model()
    @load RandomForestClassifier pkg=BetaML
end

"""
    try_load_model_from_csv(tree, model_file_name, features_file_name)

If the serialized file exists, then load it.  If not, train a new model and 
serialize it before returning it to caller.
"""
function try_load_model_from_csv(tree, model_file_name, features_file_name)::Machine
    @info "Looking for model stored in $model_file_name"
    if isfile(model_file_name)
        @info "Found model stored in $model_file_name"
        return load_model_from_csv(model_file_name)
    end
    @info "Not found, let's try to train a new model from features in $features_file_name"
    return serialize_model_from_csv_features(tree, features_file_name)
end
function load_model_from_csv(model_file_name)::Machine
    return machine(model_file_name)
end

function train_model_from_csv(tree, csv_name="$(@__DIR__)../../features.csv")

    # Load data
    data, header = readdlm(csv_name, ',', header=true)
    df = DataFrame(data, vec(header))
    coerce!(df, :WonGame => Multiclass{2})
    df = DFM.@transform(df, :WonGame)
    df, df_test = partition(df, 0.7, rng=123)
    
    # Fit model machine to data
    y, X = unpack(df, ==(:WonGame));
    mach = machine(tree, X, y)
    Base.invokelatest(fit!, mach)

    return mach
end

function serialize_model_from_csv_features(tree, csv_name)
    mach = train_model_from_csv(tree, csv_name)
    MLJ.save("$(DATA_DIR)/model.jls", mach)
    return mach
end
