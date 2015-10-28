immutable JustStrategy{T} <: AbstractStrategy
    x::T
end

just(x) = JustStrategy(x)

Base.minimum(x::JustStrategy) = x.x
arbitrary(strategy::JustStrategy) = strategy.x
shrink{T}(x::T, strategy::JustStrategy{T}) = Task(() -> nothing)   