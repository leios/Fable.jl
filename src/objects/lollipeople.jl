export Lolli

module Lolli

import Fae: @fum, FractalUserMethod, FractalInput

mutable struct LolliPerson
    head::FractalUserMethod
    eyes::FractalUserMethod
    body::FractalUserMethod
    angle::Union{Float32, Float64, FractalInput}
    foot_pos::Union{Tuple{FT}, FractalInput} where FT <: Union{Float32, Float64}
    head_height::Union{Float32, Float64, FractalInput}

    eye_color::FractalUserMethod
    body_color::FractalUserMethod

    transform::Union{Nothing, FractalUserMethod}
    head_transform::Union{Nothing, FractalUserMethod}
    body_transform::Union{Nothing, FractalUserMethod}
end

function LolliPerson(size)
end

# This brings a lolli from loc 1 to loc 2
# 1. Changes fis
# 2. adds smears for body / head
function step!(lolli::LolliPerson, loc1, loc2, time)
end

# This adds quotes above a lolli head and bounces them up and down
# 1. we need some way of syncing the end of a bounce to the end "time"
#    IE, if the bounce is 2pi, but a T is 3.5 periods, we need to round
function speak!(lolli::LolliPerson, head_angle, time)
end

# This creates an exclamation mark over a lolli head
function exclaim!(lolli::LolliPerson, head_angle, time)
end

# This creates a question mark over a lolli head
function question!(lolli::LolliPerson, head_angle, time)
end

# This creates a heart over the lollihead
function love!(lolli::LolliPerson, head_angle, time)
end

# This makes a lolliperson seem drowsy
function nod_off!(lolli::LolliPerson, time)
end

# This causes a LolliPerson to blink. Should be used on a regular interval
function blink!(lolli::LolliPerson, time)
end
end
