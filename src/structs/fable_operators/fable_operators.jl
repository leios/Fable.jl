#-------------fable_operators.jl-----------------------------------------------#
#
# Purpose: This file defines the FableOperator, a method to combine 
#          Fable User Methods
#
#------------------------------------------------------------------------------#
export FableOperator, fo

abstract type FableOperator end;

"""
    fo(operator_type, args..., kwargs...)

Will create a FableOperator of `operator_type` with necessary args and kwargs
"""
function fo(fo_t::Type{FO}, args; kwargs) where FO <: FableOperator
    fo_t(args...; kwargs...)
end

