# Fractal inputs are essentially wrappers for the symbols tuple
# I would like to use have these outward-facing so users can update the tuple
struct FractalInput
    index::Union{Int, UnitRange{Int}}
    name::Symbol
    args::Vector{Any}
    body::Union{Expr, Symbol, Number}
end

# Note: this operator currently works like this:
#       item = @fi item = 5
#       It returns a Fractal Input to be used with Hutchinson ops
macro fi(expr)

    if isa(expr, Symbol)
        error("Cannot convert Symbol to Fractal Input!")
    elseif expr.head == :(=)
        # inline function definitions
        if isa(expr.args[1], Expr)
            error("Invalid Fractal Input (@fi)! "*
                  "Maybe try Fractal Operator (@fo)?")
        # inline symbol definitions
        elseif isa(expr.args[1], Symbol)
            index = 0
            name = expr.args[1]
            args = []
            kwargs = []
            if isa(expr.args[2], Union{Symbol, Number})
                return FractalInput(index, name, args, expr.args[2])
            end
            if expr.args[2].args[1] == :eval
                return FractalInput(index, name, args,
                                    eval(expr.args[2].args[2]))
            end
            if !isa(expr.args[2], Number)
                args = find_args(expr.args[2])
            end
            body = expr.args[2]
            return FractalInput(index, name, args, body)
        end
    elseif expr.head == :function
        error("Invalid Fractal Input (@fi)! Maybe try Fractal Operator (@fo)?")
    else
        error("Cannot convert expr to Fractal Input!")
    end
end

#This function goes through an expression and returns back any symbols
function find_args(expr::Union{Expr, Symbol})
    args = []

    if isa(expr, Expr)
        for i = 2:length(expr.args)
            if isa(expr.args[i], Symbol)
                push!(args, expr.args[i])
            elseif isa(expr.args[i], Expr)
                args = vcat(args,find_args(expr.args[i]))
            end
        end
    else
        push!(args, expr)
    end

    return args
    
end

function find_fi(arg::Symbol, fis::Vector{FractalInput})
    for i = 1:length(fis)
        if arg == fis[i].name
            return fis[i]
        end
    end

    error("Symbol ", arg, " not defined!")
end
