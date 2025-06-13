cd ../CatanEngine.jl
git checkout v0.1.0
cd ../RunScripts
julia -e "include(\"run.jl\"); benchmark_one_game(\"configs/benchmark_run.toml\", \"v0.0.1\")"
cd ../CatanEngine.jl
git checkout master
cd ../RunScripts
julia -e "include(\"run.jl\"); benchmark_one_game(\"configs/benchmark_run.toml\", \"v.0.1.0\")"

cp run.jl ../CatanEngine.jl/benchmarks/
cp configs/benchmark_run.toml ../CatanEngine.jl/benchmarks/
cp release_benchmark.sh ../CatanEngine.jl/benchmarks/
