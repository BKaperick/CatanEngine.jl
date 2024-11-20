using Random
using CSV
using MLJ
using DataFrames
import DataFramesMeta as DFM
using DelimitedFiles
using MLJScikitLearnInterface
#df = DataFrame(CSV.File(ARGS[1]))
#df = DataFrame("../../features.csv")
using Logging

logger = ConsoleLogger(stderr, Logging.Debug)
#logger = ConsoleLogger(stderr, Logging.Info)
#logger = ConsoleLogger(stderr, Logging.LogLevel(5000))
global_logger(logger)

features_csv = "$(@__DIR__)/../../features.csv"

data, header = readdlm(features_csv, ',', header=true)
df = DataFrame(data, vec(header))

coerce!(df, :WonGame => Multiclass{2})
df = DFM.@transform(df, :WonGame)
df, df_test = partition(df, 0.7, rng=123)

y, X = unpack(df, ==(:WonGame));
y_test, X_test = unpack(df_test, ==(:WonGame));

# (name = DecisionTreeClassifier, package_name = DecisionTree, ... )
Tree = @load RandomForestClassifier pkg=BetaML
#Tree = @load DecisionTreeClassifier pkg=BetaML
#Tree = @load SVMClassifier pkg=MLJScikitLearnInterface
#tree = Tree()
tree = Tree(
max_depth = 5,
min_gain = 0.0,
min_records = 2,
max_features = 0

           )

"""
tree = Tree(
max_depth = 5,
min_gain = 0.0,
min_records = 2,
max_features = 0,
splitting_criterion = BetaML.Utils.gini)
tuned_tree = TunedModel(
    tree,
    tuning = Grid(),
    range=range(tree, :max_depth, lower=1, upper=2),
    measure = accuracy,
    resampling=Holdout(fraction_train=0.7),
)
"""
function fit_machine(tree, X, y)
    mach = machine(tree, X, y)
    fit!(mach)
    return mach
end

function analyze_acc(mach, X, y)
    println(typeof(mach), typeof(X))
    p = predict(mach, X)
    yhat = mode.(p)
    acc = accuracy(yhat, y)
    return acc
end

mach = fit_machine(tree, X[1:100,1:end], y[1:100])
acc = analyze_acc(mach, X, y)
test_acc = analyze_acc(mach, X_test, y_test)

#"""
#tuned_mach = fit_machine(tuned_tree, X, y)
#tuned_acc = analyze_acc(tuned_mach, X, y)
#tuned_test_acc = analyze_acc(tuned_mach, X_test, y_test)
#println("Best model: $(fitted_params(tuned_mach).best_model)")
#"""

println("acc / test_acc: $acc / $test_acc")
#println("tuned acc / tuned test_acc: $tuned_acc / $tuned_test_acc")

