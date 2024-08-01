#-------------fable_input.jl---------------------------------------------------#
#
# Purpose: Recompilation is a costly process in Julia (and for GPU programming
#          in general). FableInputs are meant to allow users to store specific
#          variables that are meant to be modified dynamically without
#          triggering recompilation.
#
#   Notes: Improvements:
#          1. Make the buffer object less noticeable when creating fis (for 
#             example, it might be nice not to specify index)
#
#------------------------------------------------------------------------------#

export FableInput, fi, set!, value

"""
    x = FableInput(buffer, 5)

Will create a FableInput at index 5 of the FableBuffer.
FableInputs (fis) are variables meant to be dynamically modified by the user.
This way we do not unnecessarily triger a costly recompilation
"""
struct FableInput{FB <: FableBuffer, I <: Integer}
    buffer::FB
    index::I
end

"""
    x = fi(buffer, 5)

This is a shorthand for FableInput construction
"""
fi(args...) = FableInput(args...)

"""
    x = fi(buffer, index, value)

Will create a FableInput that points to `index` in `buffer`
 and then sets it to `value`
"""
function fi(fb::FableBuffer, idx::Integer, val::N) where N <: Number
    x = FableInput(buffer, idx)
    set!(x, val)
    return x
end

"""
    set!(fi, 5)

Will set the associated CPU buffer element for your FableInput to 5
"""
function set!(fi::FableInput, val)
    fi.buffer.cpu[fi.index] = val
end

"""
This just returns the stored value of your FablInput
"""
value(fi::FableInput) = fi.buffer.cpu[fi.index]
