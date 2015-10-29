abstract AbstractShrinker
immutable NoShrinker <: AbstractShrinker end

"""
Type for encoding a method of generating examples.

All strategies should implement `shrink`, `arbitrary` and `returntype`
methods
"""
abstract AbstractStrategy

"""
Takes an example (`x`) and a strategy and returns an iterable of subexamples
"""
shrink(x, strategy::AbstractStrategy) = error("shrink not implemented for $(typeof(strategy))")
"""
Generates a random example using `startegy`
"""
arbitrary(strategy::AbstractStrategy) = error("arbitrary not implemented for $(typeof(strategy))")
"""
Return type of the `arbitrary` function
"""
returntype(strategy::Type{AbstractStrategy}) = error("returntype not implemented for type $(typeof(strategy))")

immutable CounterexampleError{T} <: Exception
    n_tests::Int
    n_shrinks::Int
    counterexample::T
end

function Base.showerror(io::IO, ex::CounterexampleError)
    print(io, """
    Found counterexample after $(ex.n_tests) tests, $(ex.n_shrinks) shrinks:
        
    counterexample: $(ex.counterexample)
    
    """)
end

"""
Search method to find a counterexample in the event of propositions
failure.

Finds smaller counterexamples by recursively shrinking bad counterexamples
until no smaller counterexample can be found.
"""
function find_minimal_counterexample(prop, args::Tuple, strategy::AbstractStrategy)
    cand_feas = false
    args_old = deepcopy(args)
    n_shrinks = 0
    while true
        shrink_strategies = shrink(args_old, strategy)
        for args_new in shrink_strategies
            if !prop(args_new...)
                cand_feas = true
                args_old = args_new
                break
            end
        end
        
        if !cand_feas
            return n_shrinks, args_old
        end
        cand_feas = false
        n_shrinks += 1
    end
end

"""
Generate `n` test samples using `strategy` on a proposition (`prop`).

If the proposition holds for all test samples then the test passes
"""
function forAll(prop, strategies::Tuple; 
                n::Int=100)
    strategy = tuples(strategies...)
    for i=1:n
        args = arbitrary(strategy)
        if !prop(args...)
            n_shrinks, example = find_minimal_counterexample(prop, args, strategy)
            throw(CounterexampleError(i, n_shrinks, example))
        end
    end
    true
end