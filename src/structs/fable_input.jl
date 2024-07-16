#-------------fable_input------------------------------------------------------#
#
# Purpose: This file is meant to create fable inputs for Fable
#          Fable Inputs are any values meant to be modified by the user
#              within a Fable executable to avoid recompilation.
#
#   Notes: Maybe save as pointers to expressions for usability?
#
#------------------------------------------------------------------------------#
export FableInput, @fi

struct FableInput{E}
    expr::E
end

"""
    x = @fi 7

    or

    x = @fi 7*y+5

Marks the variable `x` as a FableInput -- a dynamic variable passed in to the
final executable at runtime.
This avoids recompilation of code for variables that are dynamically changing.
"""
macro fi(ex)
    esc(FableInput(ex))
end
