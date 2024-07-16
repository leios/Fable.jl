#-------------fable-user_methods-----------------------------------------------#
#
# Purpose: This file is meant to define how users interact with fable user 
#              methods.
#          fums are essentially function fragments that will be compiled at
#              a later stage of the Fable pipeline
#
#   Notes: I think the best way to carry fis with the user methods is
#              to define a constructor function that reads in the expr block and
#              kwargs, and then parses out the fis from that list. Then at the
#              end of the @fum macro, I can call into that constructor.
#          We could get fanc with our own @generated macro, but...
#
#------------------------------------------------------------------------------#
export FableUserMethod, @fum

struct FableUserMethod{E, F}
    body::E
    fis::F
end


args(a,n) = a.args[n]

function __warn_args(args, config)
    correct_args = (:y, :x, :frame, :color)
    max_arg_idx = 3
    if config == :color
        max_arg_idx = 4
    end
    if !issubset(args, correct_args[1:max_arg_idx])
        error("Function arguments must be one of the following:\n"*
              string(correct_args[1:max_arg_idx])*"\n"*
              "Please use key-word arguments for any additional arguments!")
    end
end

"""
    f = @fum f(x) = x+1

Defines a Fable User Method (f) that can be used along with other fums to 
build a Fable Executable.
Note that these are not compiled until the Fable Executable is built!
This means you will not have error checking until later in the process!

You may use `:color` to specify that the fum is meant for coloring.
"""
macro fum(exprs...)

    config = :default

    if length(exprs) != 1
        for i = 1:length(exprs)-1
            if exprs[i] == :color || exprs[i] == :shader ||
               exprs[i] == :(:shader) || exprs[i] == :(:color)
                config = :color
            else
                error("Incorrect config argument ", ex[i], "!")
            end
        end
    end

    ex = exprs[end]

    if !isa(ex, Expr)
        error("Cannot convert single inputs to Fable User Method!")
    elseif ex.head == :(=) && !(isa(ex.args[1], Expr))
        error("Invalid function definition!")
    end

    def = MacroTools.splitdef(ex)
    __warn_args(def[:args], config)
    kwargs = def[:kwargs]
    fis = Tuple(FableInput[])
    for i = 1:length(kwargs)
        if !isa(kwargs[i], Expr)
            error("fum key word arguments must be an expression, like "*
                  "`q = 5`")
        end
        kwargs[i].head = :(=)
        if isa(kwargs[i].args[2], FableInput)
            fis = (fis..., kwargs[i].args[2])
        end
    end

    final_ex = Expr(:block, kwargs..., def[:body])
    return esc(FableUserMethod(Expr(:block, def[:kwargs]..., def[:body]),
               fis))
end

#=

function (a::FableUserMethod)(args...; kwargs...)

    # we do not reason about standard args right now, although this could
    # be considered in the future if we ensure users always configure their
    # fums beforehand. We could then save the args and such in each fum and
    # assign them to a value that is passed in to the compute kernels.
    if length(args) > 0
        @warn("function arguments cannot be set at"*
              " this time and will be ignored!\n"*
              "Please use appropriate key-word arguments instead!")
    end

    # checking to make sure the symbols are assignable in the first place
    error_flag = false

    # Note: grabs all keywords from the a.fx. If multiple definitions exist,
    # it takes the first one. It might mistakenly grab the wrong function.
    # If this happens, we need to reason about how to pick the right function
    # when two exist with the same name, but different kwargs...
    known_kwargs = Base.kwarg_decl.(methods(a.fx))[1]

    final_kwarg_idxs = Int[]
    final_fi_idxs = Int[]

    ks = keys(kwargs)
    vals = values(NamedTuple(kwargs))
    for i = 1:length(ks)
        if !in(ks[i], known_kwargs)
            @warn(string(key)*" not found in set of fum key-word args!")
            error_flag = true
        end

        if isa(vals[i], FableInput)
            push!(final_fi_idxs, i)
        else
            push!(final_kwarg_idxs, i)
        end
    end

    if error_flag
        error("one or more keys not found in set of fum key-word args!\n"*
              "Maybe consider creating a new fum function with the right "*
              "key-word arguments?")
    end

    fis = [FableInput(ks[i], vals[i].x) for i in final_fi_idxs]

    ks = Tuple(ks[final_kwarg_idxs])
    vals = Tuple(remove_vectors.(vals[final_kwarg_idxs]))

    final_kwargs = NamedTuple{ks}(vals)
    return FableUserMethod(final_kwargs, fis, a.fx)
end
=#
