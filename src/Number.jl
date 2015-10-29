# ----- Number -----
typealias AbstractUniform Union{DiscreteUniform, Uniform}

immutable NumberStrategy{D <: AbstractUniform, T} <: AbstractStrategy
    dist::D
    specialvalues::Vector{T}
    p::Bernoulli
    shrinker::NoShrinker
end
Base.minimum(strategy::NumberStrategy) = dist.params(strategy.dist)[1]
shrinker(strategy::NumberStrategy) = strategy.shrinker
returntype{D, T}(::Type{NumberStrategy{D, T}}) = T

# ----- Float -----
function _specialvalues{T <: AbstractFloat}(::Type{T}, min::T, max::T)
    specialvalues = [convert(T, NaN)]
    append!(specialvalues, [min, max])
    if (min < zero(T)) && (max > zero(T))
        push!(specialvalues, zero(T))
    end
    if (min < one(T)) && (max > one(T))
        push!(specialvalues, one(T))
    end
    if (min < -one(T)) && (max > -one(T))
        push!(specialvalues, -one(T))
    end
    return specialvalues
end

"""
Generate arbitrary float values between a desired range
"""
function floats{T <: AbstractFloat}(
    min::T, max::T;
    specialvalues::Vector{T}=_specialvalues(T, min, max), 
    p::Bernoulli=Bernoulli(0.1),
    shrinker=NoShrinker())
    
    NumberStrategy(Uniform(min, max), specialvalues, p, shrinker)
end

# ----- Int -----
function _specialvalues{T <: Signed}(::Type{T}, min::T, max::T)
    specialvalues = [min, max]
    if (min < zero(T)) && (max > zero(T))
        push!(specialvalues, zero(T))
    end
    if (min < one(T)) && (max > one(T))
        push!(specialvalues, one(T))
    end
    if (min < -one(T)) && (max > -one(T))
        push!(specialvalues, -one(T))
    end
    return specialvalues
end
"""
Generate arbitrary signed values between a desired range
"""
function signeds{T <: Signed}(
    min::T, max::T;
    specialvalues::Vector{T}=_specialvalues(T, min, max),
    p::Bernoulli=Bernoulli(0.1),
    shrinker=NoShrinker())

    NumberStrategy(DiscreteUniform(min, max), specialvalues, p, shrinker)
end

function _specialvalues{T <: Unsigned}(::Type{T}, min::T, max::T)
    specialvalues = [min, max]
    if (min < one(T)) && (max > one(T))
        push!(specialvalues, one(T))
    end
    return specialvalues
end
"""
Generate arbitrary unsigned values between a desired range
"""
function unsigneds{T <: Unsigned}(
    min::T, max::T;
    specialvalues::Vector{T}=_specialvalues(T, min, max),
    p::Bernoulli=Bernoulli(0.1),
    shrinker=NoShrinker())

    NumberStrategy(DiscreteUniform(min, max), specialvalues, p, shrinker)
end

function arbitrary{D, T}(strategy::NumberStrategy{D, T})
    if Bool(rand(strategy.p))
        if length(strategy.specialvalues) > 0
            return convert(T, rand(strategy.specialvalues))
        end
    end
    return convert(T, rand(strategy.dist))
end
shrink{T <: Number}(x::T, strategy::NumberStrategy) = Task(() -> nothing)