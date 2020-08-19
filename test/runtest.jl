using Test
using ParallelMapAccumulate
using Distributed

if nprocs() == 1
    addprocs(2)
elseif nworkers() > 2
    error("Too many processes")
end

@everywhere using Pkg
@everywhere pkg"activate ."
@everywhere pkg"precompile"
@everywhere using ParallelMapAccumulate


res = pmapaccumulate(x -> x^2, +, 1:10 |> collect; distributed = false) |> collect
@test res == accumulate(+, map(x -> x^2, 1:10))

res = pmapaccumulate(x -> x^2, +, 1:10) |> collect
@test res == accumulate(+, map(x -> x^2, 1:10))
