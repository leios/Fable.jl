export FractalExecutable, fee, update!

abstract type FractalExecutable end;

function fee(T::Type{FE}, args...; kwargs...) where FE <: FractalExecutable
    return FE(args...; kwargs...)
end

function update!(H::FractalExecutable; kwargs...)
    possible_kwargs = [H.fis[i].s for i = 1:length(H.fis[i])]
    for i = 1:length(kwargs)
        if in(kwargs[i][1], possible_kwargs)
            set!(H.fis[i], kwargs[i][2])
        else
            @error("Key word argument "*string(kwarg[1])*
                   " is not a FractalInput!\n"*
                   "Please use one of the following...\n", possible_kwargs)
        end
    end
end

