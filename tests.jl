using Test
include("structs.jl")
include("constants.jl")
include("human.jl")

@test get_coord_from_human_tile_description("nqr") == (5,4)
@test get_coord_from_human_tile_description("nqr") == (5,4)
@test get_coord_from_human_tile_description("qqm") == (6,1)
@test get_coord_from_human_tile_description("qqr") == (6,2)
@test get_coord_from_human_tile_description("gcc") == (1,7)
@test get_coord_from_human_tile_description("ada") == (1,1)
@test get_road_coords_from_human_tile_description("nq") == [(5,3),(5,4)]
@test get_road_coords_from_human_tile_description("jk") == [(3,7),(4,7)]
@test get_road_coords_from_human_tile_description("bf") == [(2,5),(2,6)]
@test get_road_coords_from_human_tile_description("qqr") == [(6,2),(6,3)]
@test get_road_coords_from_human_tile_description("qqm") == [(6,1),(5,2)]
@test get_road_coords_from_human_tile_description("qmq") == [(6,1),(5,2)]
@test get_road_coords_from_human_tile_description("mqq") == [(6,1),(5,2)]
@test get_road_coords_from_human_tile_description("ssp") == [(6,7),(5,8)]
@test get_road_coords_from_human_tile_description("ssr") == [(6,6),(6,5)]
@test get_road_coords_from_human_tile_description("ppl") == [(5,9),(4,10)]
@test get_road_coords_from_human_tile_description("hhd") == [(3,1),(3,2)]
