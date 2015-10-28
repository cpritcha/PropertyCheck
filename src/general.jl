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

"""
Search method to find a counterexample in the event of propositions
failure.

Finds smaller counterexamples by recursively shrinking bad counterexamples
until no smaller counterexample can be found.
"""
function find_minimal_counterexample(prop, arg, strategy)
    cand_feas = false
    arg_old = deepcopy(arg)
    while true
        shrink_strategies = shrink(arg_old, strategy)
        for arg_new in shrink_strategies
            if !prop(arg_new)
                cand_feas = true
                arg_old = arg_new
                break
            end
        end
        
        if !cand_feas
            return arg_old
        end
        cand_feas = false
    end
end

"""
Generate `n` test samples using `strategy` on a proposition (`prop`).

If the proposition holds for all test samples then the test passes
"""
function forAll(prop, strategy; n::Int=100)
    for i=1:n
        arg = arbitrary(strategy)
        if !prop(arg)
            return find_minimal_counterexample(prop, arg, strategy)
        end
    end
end