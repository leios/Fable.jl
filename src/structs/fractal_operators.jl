struct FractalOperator
    name::Symbol
    args::Vector{Any}
    body::Union{Expr, Number, Symbol}
end

# Note: this operator currently works like this:
#       f = @frop function f(x) x+1 end
#       There should be a way to define f in this macro, so we don't need to
#       say `f = @frop function ...`, but instead just `@frop function ...`
macro frop(expr)

    if isa(expr, Symbol)
        error("Cannot convert Symbol to Fractal Operator!")
    elseif expr.head == :(=)
        if isa(expr.args[1], Expr)
            def = MacroTools.splitdef(expr)
            name = def[:name]
            args = def[:args]
            return FractalOperator(name,args,expr.args[2])
        elseif isa(expr.args[1], Symbol)
            name = expr.args[1]
            args = []
            if !isa(expr.args[2], Number)
                args = find_args(expr.args[2])
            end
            body = expr.args[2]
            return FractalOperator(name, args, body)
        end
    elseif expr.head == :function
        def = MacroTools.splitdef(expr)
        name = def[:name]
        args = def[:args]
        return FractalOperator(name,args,expr.args[2])
    else
        error("Cannot convert expr to Fractal Operator!")
    end
end

#This function goes through an expression and returns back any symbols
function find_args(expr::Union{Expr, Symbol})
    args = []

    for i = 2:length(expr.args)
        if isa(expr.args[i], Symbol)
            push!(args, expr.args[i])
        elseif isa(expr.args[i], Expr)
            args = vcat(args,find_args(expr.args[i]))
        end
    end

    return args
    
end

function find_frop(arg::Symbol, frops::Vector{FractalOperator})
    for i = 1:length(frops)
        if arg == frops[i].name
            return frops[i]
        end
    end

    error("Symbol ", arg, " not defined!")
end

# The FractalOperators can have any number of arguments, but we only know about
# x -> p[tid,2], y -> p[tid,1], t -> t (we might care about z and w eventually)
# This function is run with hutchinson configuration and creates a "header" to 
# configure all Fractal Operators when placed into the Hutchinson operator.
# Notes:
#     1. If a frop has a dependency outside of x, y, or t, that dependency
#        will also be placed in the header; however, complex dependencies
#        might be redundant (if 2 frops need a, a might be defined 2x)
#        This redundancy could be removed by erasing the lower definitions...
function create_frop_header(frop::FractalOperator,
                            others::Vector{FractalOperator};
                            max_symbols = 50)

    # Start with the known items
    arg_dict = Dict(
        :(x) => :(p[tid,2]),
        :(y) => :(p[tid,1]),
        :(t) => :(t)
    )

    arg_list = [:(_) for i = 1:max_symbols]
    arg_list[1] = :(x)
    arg_list[2] = :(y)
    arg_list[3] = :(t)

    index = 4

    # we will DFS through the arg lists
    s = Stack{Symbol}()

    # setting up the stack initially
    for i = 1:length(frop.args)
        if !in(frop.args[i], arg_list)
            push!(s, frop.args[i])
            arg_list[index] = frop.args[i]
            index += 1
        end
    end

    iteration = 0
    while length(s) > 0
        current_arg = pop!(s)
        current_frop = find_frop(current_arg, others)
        arg_dict[current_arg] = current_frop.body
        for i = 1:length(current_frop.args)
            if frop.args[i] != :(x) &&
               frop.args[i] != :(y) &&
               frop.args[i] != :(1)
                push!(s, frop.args[i])
                arg_list[index]  = frop.args[i]
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
    for i = 4:index-1
        parse_string *= string(arg_list[i]) *" = "* 
                        string(arg_dict[arg_list[i]]) *"\n"
    end

    #println(parse_string)

    return parse_string

end
