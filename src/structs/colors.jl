#-------------colors.jl--------------------------------------------------------#
#
# Purpose: This file defines the AbstractFableColor type and corresponding 
#          structs. The purpose is to allow for better construction of the 
#          output pixel layer for various purposes.
#
#   Notes: Each FableColor must define an addition operator
#          These types will be used to determine how to postprocess each layer
#          We might need to specify that C <: RGBA but not N0f8 for GPU
#
#------------------------------------------------------------------------------#

export StandardColor, PriorityColor, DepthColor
abstract type AbstractFableColor end;

function Base.:(+)(a::AbstractFableColor, b::AbstractFableColor)
    typeof(a)(a.color + b.color)
end

#------------------------------------------------------------------------------#
# Standard Color
#------------------------------------------------------------------------------#

"""
    c = StandardColor{RGBA(0,0,0,0)}

Will create a Standard Fable Color that is transparent white.
It is just a wrapper used on RGBA for dispatch
"""
struct StandardColor{C <: RGBA} <: AbstractFableColor
    color::C
end

function Base.:(+)(a::StandardColor, b::StandardColor)
    StandardColor(a.color + b.color)
end

#------------------------------------------------------------------------------#
# Priority Color
#------------------------------------------------------------------------------#
# Not sure if priority should be an int (for layer num) or float (for position)

"""
    pc = PriorityColor(RGBA{0,0,0,0}, 0)

Will create a transparent white PriorityColor with a priority of 0.
This is useful for when you want to blend objects together in the same kernel
so you can tell which object is meant to be on top of one another.
It is particularly useful when the objects are moving in space and need more
depth information.
"""
struct PriorityColor{C <: RGBA, P <: Number} <: AbstractFableColor
    color::C
    priority::P
end

PriorityColor(c::C) where C <: RGBA = PriorityColor(c, 0)

function Base.:(+)(a::PriorityColor, b::PriorityColor)
    if a.priority > b.priority
        return a
    else
        return b
    end
end

#------------------------------------------------------------------------------#
# Depth Color
#------------------------------------------------------------------------------#
# val will just += 1 in the kernel, but then be postprocessed at the end
"""
    dc = DepthColor(RGBA{0,0,0,0}, 0)

Will create a transparent white DepthColor value with a total value of 0.
This color is useful for when you want to do shading based on the number of 
points that fall into each pixel bin such as for fractal flame methods.
The depth information will be encoded in the postprocessing steps
"""
struct DepthColor{C <: RGBA, V <: Number}
    color::C
    val::V
end

DepthColor(c::C) where C <: RGBA = DepthColor(c, 0)

function Base.:(+)(a::DepthColor, b::DepthColor)
    return DepthColor(a.color + b.color, a.val + b.val)
end
