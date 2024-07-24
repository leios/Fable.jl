#-------------fable_user_methods-----------------------------------------------#
#
# Purpose: FableUserMethods are user-defined functions that later get compiled 
#          into compute shaders / kernels for Fable
#
#   Notes: FableUserMethods do not define functions precisely, but instead
#              pass along the necessary function bodies to be `eval`ed later at
#              the FableOperator and FableExecutable level.
#
#------------------------------------------------------------------------------#
export FableUserMethod, @fum

abstract type AbstractFUMKind end;

struct FUMColor <: AbstractFUMKind end
struct FUMTransform <: AbstractFUMKind end


"""
A FableUserFragment is a piece of code created with the `@fum` macro that is 
later configured into a FableUserMethod by calling it as a function
"""
struct FableUserFragment{A <: AbstractFUMKind}
    body::Expr
    kwargs::Vector
    kind::A
end

"""
This is a struct for holding all expressions related to the construction of a
FableUserMethod. It is not meant to be diretly created by the user, but instead
it is created by calling a FableUserFragment as a function to configure its
keyword arguments
"""
struct FableUserMethod
    name::Expr
    body::Expr
end

#------------------------------------------------------------------------------#
# Macro @fum
#------------------------------------------------------------------------------#

function __find_kind(s)
    if s == :color
        return FUMColor()
    elseif s == :transform
        return FUMTransform()
    end
end

function __check_args(args, kwargs, config)
    correct_args = (:y, :x, :z, :frame, :color)

    # checking the kwargs
    for kwarg in kwargs
        if in(kwarg.args[1], correct_args)
            error("Fable User Method key word arguments cannot be:\n"*
              string(correct_args)*"\n"*
              "These are defined for all fums. Please redefine "*
              string(kwarg.args[1])*"!")
        end
    end

    # checking the args
    final_idx = length(correct_args) - 1
    if config == :color
        final_idx = final_idx + 1
    end
    if !issubset(args, correct_args[1:final_idx])
        error("Fable User Method arguments must be one of the following:\n"*
              string(correct_args[1:final_idx])*"\n"*
              "Please use key-word arguments for any additional arguments!")
    end
end

function __create_fum_stuff(expr, config, force_inbounds)
    def = MacroTools.splitdef(expr)

    kwargs = def[:kwargs]
    __check_args(def[:args], kwargs, config)

    body_qt = def[:body]
    if force_inbounds
        body_qt = quote
            @inbounds $(def[:body])
        end
    end

    return (body_qt, def[:kwargs])
end

"""
    f = @fum inbounds = true color f(x; q = 7) = x*q

Will create a FableUserFragment `f` with the function body `x*q`, the 
key word argument `q = 7`, default settings for coloring, and `@inbounds`
propagated throughout the fum.

Note that you may also use a full function definition like so:

    f = @fum inbounds = true color function f(x; q = 7)
        x*q
    end

Also note that you can configure the function as a `shader`, which will also
set default settings for coloring.
If you do not configure the fum or otherwise use the `transform` configuration,
it will default to the settings for transformations of points.

You can then configure the FableUserFragment into a FableUserMethod with 
specific key words by calling it as a normal function:

    configured_f = f(q = 6)

Which will return a FableUserMethod `f` with the correct configuration.
"""
macro fum(ex...)

    config = :transform
    force_inbounds = false

    if length(ex) == 1
    else
        for i = 1:length(ex)-1
            if ex[i] == :color || ex[i] == :shader ||
               ex[i] == :(:shader) || ex[i] == :(:color)
                config = :color
            elseif ex[i] isa Expr && ex[i].head == :(=) &&
                ex[i].args[1] == :inbounds && ex[i].args[2] isa Bool
                force_inbounds = ex[i].args[2]
            else
                error("Incorrect config argument ", ex[i], "!")
            end
        end
    end

    expr = ex[end]
    kwargs = nothing

    if isa(expr, Symbol)
        error("Fable User Methods must be Functions")
    elseif expr.head == :(=) && !isa(expr.args[1], Expr)
        error("Cannot create FableUserMethod.\n"*
              "Input is not a valid function definition!")
    else
        return FableUserFragment(__create_fum_stuff(expr,
                                                    config,
                                                    force_inbounds)...,
                                 __find_kind(config))
    end

end

#------------------------------------------------------------------------------#
# Configuration
#------------------------------------------------------------------------------#

"""
    @fum f(; q = 5) = q
    f(q=2)

Will create a FableUserMethod `f` and thenc onfigure it's keyword argument
`q = 5` -> `q = 2`.
"""
function (a::FableUserFragment)(args...; kwargs...)

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
