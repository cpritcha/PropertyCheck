immutable CollectionShrinker <: AbstractShrinker end

collection{K,V}(::Type{Dict{K,V}}, itr=Pair{K,V}[]) = Dict(itr)
collection{E}(::Type{Vector{E}}, itr=E[]) = collect(itr)
collection{E}(::Type{Set{E}}, itr=E[]) = Set(itr)

function Base.UTF8String(itr)
    buf = IOBuffer()
    for el in itr
        write(buf, el)
    end
    s = takebuf_string(buf)
    return s
end

collection(::Type{UTF8String}, itr="") = UTF8String(itr)

typealias AbstractLengthStrategy{D <: AbstractUniform} Union{JustStrategy, NumberStrategy{D, Int}}

# ----- Vectors -----
immutable VectorStrategy{E, L <: AbstractLengthStrategy, S} <: AbstractStrategy
    element_strategy::E
    length_strategy::L
    shrinker::S
end

Base.minimum(strategy::VectorStrategy) = minimum(strategy.length_strategy)
returntype{E, L, S}(::Type{VectorStrategy{E, L, S}}) = Vector{returntype(E)}

function vectors(element_strategy::AbstractStrategy, 
    length_strategy::AbstractStrategy = signeds(0, 10);
    shrinker=CollectionShrinker())
    
    VectorStrategy(
        element_strategy, 
        length_strategy,
        shrinker)
end

function arbitrary(strategy::VectorStrategy)
    n = arbitrary(strategy.length_strategy)
    [arbitrary(strategy.element_strategy) for i=1:n]
end

# ----- Dicts -----
immutable DictStrategy{K, V, L <: AbstractLengthStrategy, S} <: AbstractStrategy
    key_strategy::K
    value_strategy::V
    length_strategy::L
    shrinker::S
end

Base.minimum(strategy::VectorStrategy) = minimum(strategy.length_strategy)
returntype{K, V, L, S}(::Type{DictStrategy{K, V, L, S}}) = Dict{returntype(K), returntype(V)}

function dicts(
    key_strategy::AbstractStrategy,
    value_strategy::AbstractStrategy,
    length_strategy::AbstractStrategy;
    shrinker=CollectionShrinker())
    
    DictStrategy(key_strategy, value_strategy, length_strategy, shrinker)
end

function arbitrary{K, V, L, S}(strategy::DictStrategy{K, V, L, S})
    key_strategy = strategy.key_strategy
    value_strategy = strategy.value_strategy
    length_strategy = strategy.length_strategy

    n = arbitrary(length_strategy)
    dict = collection(returntype(typeof(strategy)))
    sizehint!(dict, n)
    
    i = 1
    n_duplicates = 0
    max_duplicates = max(div(n, 2), 10)
    while (i <= n)
        k = arbitrary(key_strategy)
        if !haskey(dict, k)
            v = arbitrary(value_strategy)
            dict[k] = v
            i += 1
        else
            n_duplicates += 1
        end
        
        if n_duplicates > max_duplicates
            error("Not enough unique keys. $max_duplicates found")
        end
    end
    return dict
end

# ----- Sets -----
immutable SetStrategy{E, L <: AbstractLengthStrategy, S} <: AbstractStrategy
    element_strategy::E
    length_strategy::L
    shrinker::S
end

function sets(
    element_strategy::AbstractStrategy,
    length_strategy::AbstractStrategy;
    shrinker = CollectionShrinker())
    
    SetStrategy(element_strategy, length_strategy, shrinker)
end

Base.minimum(strategy::VectorStrategy) = minimum(strategy.length_strategy)
returntype{E, L, S}(::Type{SetStrategy{E, L, S}}) = Set{returntype(E)}

function arbitrary{E, L, S}(strategy::SetStrategy{E, L, S})
    element_strategy = strategy.element_strategy
    length_strategy = strategy.length_strategy

    n = arbitrary(length_strategy)
    set = collection(returntype(typeof(strategy)))
    sizehint!(set, n)
    
    i = 1
    n_duplicates = 0
    max_duplicates = max(div(n, 2), 10)
    while i <= n
        v = arbitrary(element_strategy)
        if !(v in set)
            push!(set, v)
            i += 1
        else
            n_duplicates += 1
        end
        if n_duplicates > max_duplicates
            error("Not enough unique values. $max_duplicates found")
        end
    end
    return set
end

# ----- Strings -----
immutable UTF8StringStrategy{L <: AbstractLengthStrategy, S <: AbstractShrinker} <: AbstractStrategy
    dist::DiscreteUniform
    length_strategy::L
    specialvalues::Vector{Char}
    p::Bernoulli
    shrinker::S
end

_specialvalues(::Type{Char}) = Char['\0', ' ', '\n' , '\t']
function utf8strings(
    min::Int=0, max::Int=65535, 
    length_strategy::AbstractLengthStrategy=signeds(0, 10);
    specialvalues = _specialvalues(Char),
    p=Bernoulli(0.1),
    shrinker=CollectionShrinker())
    
    UTF8StringStrategy(DiscreteUniform(min, max), length_strategy, specialvalues, p, shrinker)
end

Base.minimum(strategy::UTF8StringStrategy) = minimum(strategy.length_strategy)
returntype{L, S}(::Type{UTF8StringStrategy{L, S}}) = UTF8String

function arbitrary(strategy::UTF8StringStrategy)
    n = arbitrary(strategy.length_strategy)
    buf = IOBuffer()
    for i=1:n
        if Bool(rand(strategy.p))
            write(buf, rand(strategy.specialvalues))
        else
            write(buf, Char(rand(strategy.dist)))
        end
    end
    s = takebuf_string(buf)
    return s
end

# ----- Tuples -----
immutable TupleShrinker <: AbstractShrinker end

immutable TupleStrategy{TE} <: AbstractStrategy
    element_strategies::TE
end

function tuples(element_strategies::AbstractStrategy...)
    TupleStrategy(element_strategies)
end

function arbitrary{TE}(strategy::TupleStrategy{TE})
    map(arbitrary, strategy.element_strategies)
end

shrink(x, strategy::TupleStrategy) = Task(() -> nothing)

# ----- Types -----
immutable TypeStrategy{TE} <: AbstractStrategy
    constructor
    element_strategies::TE
end

function record(constructor, element_strategies)
    TypeStrategy(constructor, element_strategies)
end

function arbitrary{TE}(strategy::TypeStrategy{TE})
    strategy.constructor(map(arbitrary, strategy.element_strategies)...)
end

# ----- General -----
typealias VectorBisectionStrategy{E, L}     VectorStrategy{E, L, CollectionShrinker}
typealias DictBisectionStrategy{K, V, L}    DictStrategy{K, V, L, CollectionShrinker}
typealias SetBisectionStrategy{E, L}        SetStrategy{E, L, CollectionShrinker}
typealias UTF8StringBisectionStrategy{L}    UTF8StringStrategy{L, CollectionShrinker}

typealias AbstractBisectionStrategy Union{
    VectorBisectionStrategy, 
    DictBisectionStrategy, 
    SetBisectionStrategy,
    UTF8StringBisectionStrategy}

shrink(x, strategy::AbstractBisectionStrategy) = Task() do
    min_collection_size = minimum(strategy)
    T = returntype(typeof(strategy))
    n = length(x)
    if n > min_collection_size
        new_size = max(div(n, 2), min_collection_size)
        can_bisect = div(n, 2) >= min_collection_size
        
        itr = take(x, new_size)
        produce(collection(T, itr))
        
        if can_bisect
            itr = drop(x, new_size)
            produce(collection(T, itr))
        else
            itr = drop(x, n - new_size)
            produce(collection(T, itr))
        end
    end
end