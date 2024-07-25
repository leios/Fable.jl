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
    body::Expr
end

#------------------------------------------------------------------------------#
# Macro @fum
#------------------------------------------------------------------------------#

# Check whether there are `return` statements
function contains_return(expr)
    result = false
    MacroTools.postwalk(expr) do ex
        if @capture(ex, return x_)
            result = true
        end
        expr
    end
    result
end

function __find_kind(s)
    if s == :color
        return FUMColor()
    elseif s == :transform
        return FUMTransform()
    end
end

function __find_kwarg_keys(kwargs)
    ks = [:x for i = 1:length(kwargs)]
    for i = 1:length(ks)
        ks[i] = kwargs[i].args[1]
    end
    return ks
end

function __check_args(args, kwargs, config)
    correct_args = (:y, :x, :z, :frame, :fi_buffer, :color)

    input_kwargs = __find_kwarg_keys(kwargs)
    # checking the kwargs
    for i = 1:length(kwargs)
        if in(input_kwargs[i], correct_args)
            error("Fable User Method key word arguments cannot be:\n"*
              string(correct_args)*"\n"*
              "These are defined for all fums. Please redefine "*
              string(kwarg.args[1])*"!")
        end
        if i > 1 && in(input_kwargs[i], input_kwargs[1:i-1])
            error(string(input_kwargs[i])*" key word already defined!")
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

    if contains_return(body_qt)
        error("Fable User Methods must not return values!")
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

    if length(ex) > 1
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

function __extract_keys(v)
    final_v = [:x for i = 1:length(v)]
    for i = 1:length(v)
        final_v[i] = v[i].args[1]
    end
    return final_v
end
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

    final_kwargs = copy(a.kwargs)

    ks = keys(kwargs)
    vals = values(NamedTuple(kwargs))
    known_kwargs = __extract_keys(final_kwargs)

    for i = 1:length(final_kwargs)
        for j = 1:length(ks)
            if known_kwargs[i] == ks[j]
                s = known_kwargs[i]
                if isa(vals[j], FableInput)
                    final_kwargs[i] = :($s = fi_buffer[$(vals[j].index)])
                else
                    final_kwargs[i] = :($s = $(vals[j]))
                end
            end
        end
        final_kwargs[i].head = :(=)
    end

    if error_flag
        error("one or more keys not found in set of fum key-word args!\n"*
              "Maybe consider creating a new fum function with the right "*
              "key-word arguments?")
    end

    # combining it all together
    return FableUserMethod(Expr(:block, final_kwargs..., a.body))
end
