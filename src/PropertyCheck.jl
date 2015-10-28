module PropertyCheck

import Distributions
import Distributions: UnivariateDistribution, Bernoulli, Uniform, DiscreteUniform
const dist = Distributions

# package code goes here
include("general.jl")
include("Number.jl")
include("Just.jl")
include("Collections.jl")

end # module
