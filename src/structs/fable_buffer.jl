#-------------fable_buffer.jl--------------------------------------------------#
#
# Purpose: FableBuffers are Array / GPUArray pairs that are mewant for passing
#          variables from the CPU to GPU.
#
#   Notes: Improvements:
#          1. Make the buffer always UInt and then carry the types around
#             so you can recast the fis in the kernel to the appropriate type.
#             Right now, we are just defaulting to floats
#          2. Think about textures!
#
#------------------------------------------------------------------------------#

export FableInput, fi, set!, value
export FableBuffer, create_fable_buffer, to_cpu!, to_gpu!

"""
A FableBuffer is an Array / GPUArray pair for storing FableInputs.
FableInputs are variables that are meant to be modified on-the-fly by the user
"""
struct FableBuffer{AT <: AbstractArray, GPUAT <: AbstractArray}
    cpu::AT
    gpu::GPUAT
end

"""
    create_fable_buffer(zeros(10); ArrayType = Array)

Will create a FableBuffer of zeros of size 10 for storing FableInputs.
This will create a buffer on the CPU and an additional buffer stored as an
ArrayType (meant for passing variables to the GPU)
"""
function create_fable_buffer(A::AT; ArrayType = Array) where AT <: AbstractArray
    return FableBuffer(A, ArrayType(A))
end

"""
    create_fable_buffer(10; ArrayType = Array, ElementType = Float64)

Will create a FableBuffer of zeros (Float64) of size 10 for storing FableInputs.
"""
function create_falbe_buffer(i::N; ArrayType = Array,
                          ElementType = Float64) where N <: Number
    create_falbe_buffer(zeros(ElementType, 10); ArrayType)
end

"""
This function copies the GPU FableBuffer back to the CPU
"""
function to_cpu!(fb::FableBuffer)
    fb.cpu .= fb.gpu
end

"""
This function copies the CPU FableBuffer to the GPU. This is particularly useful because all FableInputs modify the CPU array by default.
"""
function to_gpu!(fb::FableBuffer)
    fb.gpu .= fb.cpu
end
