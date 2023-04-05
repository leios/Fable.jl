export FractalExecutable, fee

abstract type FractalExecutable end;

function fee(T::Type{FE}, args...; kwargs...) where FE <: FractalExecutable
    return FE(args...; kwargs...)
end
