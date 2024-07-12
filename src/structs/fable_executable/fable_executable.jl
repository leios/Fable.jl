export FableExecutable, fee, update!

abstract type FableExecutable end;

function fee(T::Type{FE}, args...; kwargs...) where FE <: FableExecutable
    return FE(args...; kwargs...)
end

function update!(H::FableExecutable; kwargs...)
    possible_kwargs = [H.fis[i].s for i = 1:length(H.fis[i])]
    for i = 1:length(kwargs)
        if in(kwargs[i][1], possible_kwargs)
            set!(H.fis[i], kwargs[i][2])
        else
            @error("Key word argument "*string(kwarg[1])*
                   " is not a FableInput!\n"*
                   "Please use one of the following...\n", possible_kwargs)
        end
    end
end

