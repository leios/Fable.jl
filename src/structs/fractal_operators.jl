struct FractalOperator
    name::Symbol
    args::Vector{Any}
    kwargs::Vector{Any}
    body::Union{Expr, Number, Symbol}
end

# Note: this operator currently works like this:
#       f = @fo function f(x) x+1 end
#       There should be a way to define f in this macro, so we don't need to
#       say `f = @fo function ...`, but instead just `@fo function ...`
macro fo(expr)

    if isa(expr, Symbol)
        error("Cannot convert Symbol to Fractal Operator!")
    elseif expr.head == :(=)
        # inline function definitions
        if isa(expr.args[1], Expr)
            def = MacroTools.splitdef(expr)
            name = def[:name]
            args = def[:args]
            kwargs = def[:kwargs]
            return FractalOperator(name,args,kwargs,expr.args[2])
        # inline symbol definitions
        elseif isa(expr.args[1], Symbol)
            error("Cannot create Fractal Operator (@fo)! "*
                  "Maybe try Fractal Input (@fi)?")
        end
    elseif expr.head == :function
        def = MacroTools.splitdef(expr)
        name = def[:name]
        args = def[:args]
        kwargs = def[:kwargs]
        return FractalOperator(name,args,kwargs,expr.args[2])
    else
        error("Cannot convert expr to Fractal Operator!")
    end
end

function find_fo(arg::Symbol, fos::Vector{FractalOperator})
    for i = 1:length(fos)
        if arg == fos[i].name
            return fos[i]
        end
    end

    error("Symbol ", arg, " not defined!")
end

# The FractalOperators can have any number of arguments, but we only know about
# x -> p[tid,2], y -> p[tid,1], t -> t (we might care about z and w eventually)
# This function is run with hutchinson configuration and creates a "header" to 
# configure all Fractal Operators when placed into the Hutchinson operator.
# Notes:
#     1. If a fo has a dependency outside of x, y, or t, that dependency
#        will also be placed in the header; however, complex dependencies
#        might be redundant (if 2 fos need a, a might be defined 2x)
#        This redundancy could be removed by erasing the lower definitions...
function create_header(fo::FractalOperator, fis::Vector{FractalInput};
                       max_symbols = 50)

    # Start with the known items
    arg_dict = Dict(
        :(x) => "p[tid,2]",
        :(y) => "p[tid,1]",
    )

    arg_list = [:(_) for i = 1:max_symbols]
    arg_list[1] = :(x)
    arg_list[2] = :(y)

    # If you change this value, don't forget to also change the index below!
    index = 3
    ignore = index

    # we will DFS through the arg lists
    s = Stack{Symbol}()

    # setting up the stack initially
    for i = 1:length(fo.args)
        if !in(fo.args[i], arg_list) && isa(fo.args[i],Symbol)
            push!(s, fo.args[i])
            arg_list[index] = fo.args[i]
            index += 1
        end
    end

    iteration = 0
    while length(s) > 0
        current_arg = pop!(s)
        current_fi = find_fi(current_arg, fis)
        if isa(current_fi.body, Union{Number, Array})
            arg_dict[current_arg] = "symbols["* string(current_fi.index)*"]"
        elseif isa(current_fi.body, Expr)
            arg_dict[current_arg] = string(current_fi.body)
        else
            arg_dict[current_arg] = string(current_fi.body)
        end
        for i = 1:length(current_fi.args)
            if current_fi.args[i] != :(x) &&
               current_fi.args[i] != :(y)
                push!(s, current_fi.args[i])
                arg_list[index]  = current_fi.args[i]
                index += 1
            end
        end

        iteration += 1
        if iteration > 100
            error("Cyclical dependency found in fractal operator definitions!")
        end
    end

    # Creating string to Meta.parse
    parse_string = ""
    for i = index-1:-1:ignore
        parse_string *= string(arg_list[i]) *" = "* arg_dict[arg_list[i]] *"\n"
    end

    for i = 1:length(fo.kwargs)
        parse_string *= string(fo.kwargs[i].args[end-1]) *" = "* 
                        string(fo.kwargs[i].args[end]) *"\n"
    end

    return parse_string

end

function configure_fo(fo::FractalOperator, fis::Vector{FractalInput})

    fx_string = "function "*string(fo.name)*"_finale(p, tid, symbols)\n"
    fx_string *= "x = p[tid, 2] \n y = p[tid, 1]"

    fx_string *= create_header(fo, fis)*
                 string(fo.body)*"\n"
    fx_string *= "p[tid, 2] = x \n p[tid, 1] = y \n"
    fx_string *= "end"

    F = Meta.parse(replace(fx_string, "'" => '"'))

    #println(fx_string)
    println(F)

    return eval(F)
end

function (a::Fae.FractalOperator)(args...; kwargs...)
    new_kwargs = deepcopy(a.kwargs)
    for kwarg in kwargs
        for i = 1:length(a.kwargs)
            if string(kwarg[1]) == string(a.kwargs[i].args[end-1])
                new_kwargs[i] = Meta.parse(string(kwarg[1]) *"="*
                                                   string(kwarg[2]))
            end
        end
    end

    return FractalOperator(a.name, a.args, new_kwargs, a.body)
end

