export AbstractGenerator, ChaosGenerator

# All AbstractGenerators should also have `args` and `iterations`
abstract type AbstractGenerator end;

struct ChaosGenerator{A, I}
    args::A
    iterations::I
end

run(gen::AbstractGenerator, tid)  = simple_rand(quick_seed(ttid))

function chaos_game(tid, bounds, random_function, f_set, dims, n)
    pt = randon_function(seed(tid), bounds, dims...)
    
    # now do Chaos Game for n iterations
end

gen = ChaosGenerator(ChaosGame, (bounds, random_function, f_set...), 1000)
