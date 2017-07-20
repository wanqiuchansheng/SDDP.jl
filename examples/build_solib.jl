PROBLEMSET = [
    Dict(
        :name        => "stock",
        :description => "The stock-example from github.com/JuliaOpt/StochDynamicProgramming.jl/tree/f68b9da541c2f811ce24fc76f6065803a0715c2f/examples/stock-example.jl",
        :author      => "Oscar Dowson",
        :lowerbound  => "-1.471",
        :file        => "StochDynamicProgramming.jl\\stock-example.jl"
    ),
    Dict(
        :name        => "multistock",
        :description => "The multistock-example from github.com/JuliaOpt/StochDynamicProgramming.jl/tree/f68b9da541c2f811ce24fc76f6065803a0715c2f/examples/multistock-example.jl",
        :author      => "Oscar Dowson",
        :lowerbound  => "-4.341",
        :file        => "StochDynamicProgramming.jl\\multistock-example.jl"
    ),
    Dict(
        :name        => "assetmanagement",
        :description => "The Asset Management problem taken from R. Birge, F. Louveaux,
        Introduction to Stochastic Programming, Springer Series in Operations Research
        and Financial Engineering, Springer New York, New York, NY, 2011.",
        :author      => "Oscar Dowson",
        :lowerbound  => "1.514",
        :file        => "asset_management.jl"
    ),
    Dict(
        :name        => "hydro1",
        :description => "A small deterministic hydro valley model",
        :author      => "Oscar Dowson",
        :lowerbound  => "835",
        :file        => "hydro_valley_deterministic.jl"
    ),
    Dict(
        :name        => "hydro2",
        :description => "A small hydro valley model with price uncertainty",
        :author      => "Oscar Dowson",
        :lowerbound  => "851.8",
        :file        => "hydro_valley_markov.jl"
    ),
    Dict(
        :name        => "hydro3",
        :description => "A small hydro valley model with inflow uncertainty",
        :author      => "Oscar Dowson",
        :lowerbound  => "838.33",
        :file        => "hydro_valley_stagewise.jl"
    ),
    Dict(
        :name        => "hydro4",
        :description => "A small hydro valley model with price and inflow uncertainty",
        :author      => "Oscar Dowson",
        :lowerbound  => "855",
        :file        => "hydro_valley_stagewise_markov.jl"
    ),
    Dict(
        :name        => "newsvendor",
        :description => "A small newsvendor model with demand and price uncertainty",
        :author      => "Oscar Dowson",
        :lowerbound  => "97.9",
        :file        => "newsvendor.jl"
    ),
    Dict(
        :name        => "prob5.2_2",
        :description => " Problem from https://github.com/blegat/StochasticDualDynamicProgramming.jl/blob/fe5ef82db6befd7c8f11c023a639098ecb85737d/test/prob5.2_2stages.jl",
        :author      => "Oscar Dowson",
        :lowerbound  => "340315.52",
        :file        => "StochasticDualDynamicProgramming.jl\\prob5.2_2stages.jl"
    ),
    Dict(
        :name        => "prob5.2_3",
        :description => " Problem from https://github.com/blegat/StochasticDualDynamicProgramming.jl/blob/fe5ef82db6befd7c8f11c023a639098ecb85737d/test/prob5.2_3stages.jl",
        :author      => "Oscar Dowson",
        :lowerbound  => "406712.49",
        :file        => "StochasticDualDynamicProgramming.jl\\prob5.2_3stages.jl"
    ),
    Dict(
        :name        => "fast_quickstart",
        :description => "QuickStart example from FAST
        https://github.com/leopoldcambier/FAST/tree/daea3d80a5ebb2c52f78670e34db56d53ca2e778/demo",
        :author      => "Oscar Dowson",
        :lowerbound  => "-2",
        :file        => "FAST\\quickstart.jl"
    ),
    Dict(
        :name        => "fast_prodmanagement",
        :description => "Problem from FAST:
        https://github.com/leopoldcambier/FAST/blob/daea3d80a5ebb2c52f78670e34db56d53ca2e778/examples/production management multiple stages/",
        :author      => "Oscar Dowson",
        :lowerbound  => "-23.96",
        :file        => "FAST\\production_management_multiple_stages.jl"
    ),
    Dict(
        :name        => "fast_quickstart",
        :description => "Hydro-thermal problem from FAST:
        https://github.com/leopoldcambier/FAST/tree/daea3d80a5ebb2c52f78670e34db56d53ca2e778/examples/hydro%20thermal",
        :author      => "Oscar Dowson",
        :lowerbound  => "10",
        :file        => "FAST\\hydro_thermal.jl"
    )
]

for problem in PROBLEMSET
    include(joinpath(@__DIR__, problem[:file]))
    SDDP.writecso("$(problem[:name]).lp.cso", m, writelp=true, author=problem[:author],
     description=problem[:description], lowerbound=problem[:lowerbound])

     SDDP.writecso("$(problem[:name]).mps.cso", m, writelp=false, author=problem[:author],
      description=problem[:description], lowerbound=problem[:lowerbound])
end
