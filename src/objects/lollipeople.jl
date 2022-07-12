export Lolli

module Lolli

import Fae: @fum, FractalUserMethod, FractalInput, Colors,
            define_circle, update_circle!, fractal_flame!, 
            define_rectangle, update_rectangle!, Pixels, fee, Hutchinson

mutable struct LolliPerson
    head::Hutchinson
    eyes::Vector{Hutchinson}
    body::Hutchinson
    angle::Union{Float32, Float64, FractalInput}
    foot_position::Union{Tuple, FractalInput} where FT <: Union{Float32, Float64}
    head_height::Union{Float32, Float64, FractalInput}

    eye_color::FractalUserMethod
    body_color::FractalUserMethod

    transform::Union{Nothing, FractalUserMethod}
    head_transform::Union{Nothing, FractalUserMethod}
    body_transform::Union{Nothing, FractalUserMethod}
end

place_eyes = @fum function place_eyes(x, y;
                                      eye_radius = 0,
                                      eye_angle = 0,
                                      head_position = (0,0),
                                      head_radius = 1,
                                      eye_height = 2.5,
                                      eye_width = 1,
                                      right_eye = 0)

    y = (y - head_position[1]) * eye_height * head_radius * 0.15 +
        head_position[1] + eye_radius * sin(eye_angle)
    x = (x - head_position[2]) * eye_width* head_radius * 0.15 -
        head_position[2] + eye_radius * cos(eye_angle) -
        head_radius * (0.25 - 0.5 * right_eye)

end

function LolliPerson(height; angle=0.0, foot_position=(height*0.5,0.0),
                     body_multiplier = 1.0,
                     eye_color = Colors.white, body_color = Colors.black,
                     head_position = (-height*1/4, 0.0),
                     head_radius = height*0.25,
                     eye_radius = 0.0, eye_angle = 0.0,
                     eye_height = 2.5, eye_width = 1,
                     name = "", AT = Array, diagnostic = true,
                     known_operations = [])

    offset = 0.1*body_multiplier
    foot_position = foot_position .- (height*1/4-0.5*offset,0)
    body = define_rectangle(foot_position, 0.0, 0.1*body_multiplier,
                            height*1/2-offset,
                            body_color; name = "body"*name,
                            diagnostic = diagnostic, AT = AT)

    head_tuple = head_position
    if isa(head_position, FractalInput)
        head_tuple = head_position.val
    end

    head = define_circle(head_tuple, head_radius, body_color;
                         name = "head"*name, diagnostic = diagnostic,
                         AT = AT)

    eyeball = define_circle(head_tuple, 1.0, eye_color;
                            name = "eye"*name, diagnostic = diagnostic,
                            AT = AT)

    # finding the FractalInputs
    kwargs = [eye_radius, eye_angle, head_position, head_radius]

    eye_kwargs = [FractalInput() for i = 1:(length(kwargs)+
                                            length(known_operations))]
    count = 1
    for i = 1:length(eye_kwargs)
        if isa(kwargs[i], FractalInput)
            eye_kwargs[count] = kwargs[i]
            count += 1
        end
    end

    for i = 1:length(known_operations)
        if known_operation[i] == :blink
            eye_kwargs[count] = fi("eye_height", eye_height)
            count += 1
        end
        if known_operation[i] == :shock
            eye_kwargs[count] = fi("eye_width", eye_width)
            count += 1
        end
    end

    if count == 1
        eye_kwargs = []
    else
        eye_kwargs = eye_kwargs[1:count-1]
    end
    
    eyes = fee([place_eyes(eye_radius = eye_radius, eye_angle = eye_angle,
                           head_position = head_position,
                           head_radius = head_radius, right_eye = 0,
                           eye_height = eye_height, eye_width = eye_width),
                place_eyes(eye_radius = eye_radius, eye_angle = eye_angle,
                           head_position = head_position,
                           head_radius = head_radius, right_eye = 1,
                           eye_height = eye_height, eye_width = eye_width)],
                eye_kwargs, [eye_color, eye_color], (0.5, 0.5);
                diagnostic = diagnostic, final = true)

    return LolliPerson(head, [eyeball, eyes], body, angle,
                       foot_position, height, eye_color,
                       body_color, nothing, nothing, nothing)
    
end

function render_lolli(lolli::LolliPerson,
                      num_particles, num_iterations, bounds, res;
                      logscale = false, AT = Array, FT = Float32,
                      num_ignore = 20, diagnostic = false, numthreads = 256,
                      numcores = 4)
    pix = Pixels(res; AT = AT, FT = FT, logscale = logscale)

    render_lolli!(pix, lolli, nothing, nothing, nothing, 
                  num_particles, num_iterations, bounds, res;
                  AT = AT, FT = FT, num_ignore = num_ignore, 
                  diagnostic = diagnostic, numthreads = numthreads,
                  numcores = numcores)

    return pix
end

function render_lolli(lolli::LolliPerson, head_smear, eye_smear, body_smear,
                      num_particles, num_iterations, bounds, res;
                      logscale = false, AT = Array, FT = Float32,
                      num_ignore = 20, diagnostic = false, numthreads = 256,
                      numcores = 4)
    pix = Pixels(res; AT = AT, FT = FT, logscale = logscale)

    render_lolli!(pix, lolli, head_smear, eye_smear, body_smear,
                  num_particles, num_iterations, bounds, res;
                  AT = AT, FT = FT, num_ignore = num_ignore, 
                  diagnostic = diagnostic, numthreads = numthreads,
                  numcores = numcores)

    return pix
end

function render_lolli!(pix::Pixels, lolli::LolliPerson,
                       num_particles, num_iterations, bounds, res;
                       AT = Array, FT = Float32, num_ignore = 20,
                       diagnostic = false, numthreads = 256, numcores = 4)

    render_lolli!(pix, lolli, nothing, nothing, nothing,
                  num_particles, num_iterations, bounds, res;
                  AT = AT, FT = FT, num_ignore = num_ignore, 
                  diagnostic = diagnostic, numthreads = numthreads,
                  numcores = numcores)

end

function render_lolli!(pix::Pixels, lolli::LolliPerson, head_smear, eye_smear,
                       body_smear, num_particles, num_iterations, bounds, res;
                       AT = Array, FT = Float32, num_ignore = 20,
                       diagnostic = false, numthreads = 256, numcores = 4)

    if isnothing(body_smear)
        fractal_flame!(pix, lolli.body, num_particles, num_iterations,
                       bounds, res; AT = AT, FT = FT, diagnostic = diagnostic,
                       num_ignore = num_ignore, numthreads = numthreads,
                       numcores = numcores)
    else
        fractal_flame!(pix, lolli.body, body_smear,
                       num_particles, num_iterations,
                       bounds, res; AT = AT, FT = FT, diagnostic = diagnostic,
                       num_ignore = num_ignore, numthreads = numthreads,
                       numcores = numcores)
    end

    if isnothing(head_smear)
        fractal_flame!(pix, lolli.head, num_particles, num_iterations,
                       bounds, res; AT = AT, FT = FT, diagnostic = diagnostic,
                       num_ignore = num_ignore, numthreads = numthreads,
                       numcores = numcores)
    else
        fractal_flame!(pix, lolli.head, head_smear,
                       num_particles, num_iterations,
                       bounds, res; AT = AT, FT = FT, diagnostic = diagnostic,
                       num_ignore = num_ignore, numthreads = numthreads,
                       numcores = numcores)
    end

    if isnothing(eye_smear)
        final_eyes = fee(lolli.eyes[2:end];
                         diagnostic = diagnostic, final = true)
        fractal_flame!(pix, lolli.eyes[1], final_eyes, 
                       num_particles, num_iterations,
                       bounds, res; AT = AT, FT = FT, diagnostic = diagnostic,
                       num_ignore = num_ignore, numthreads = numthreads,
                       numcores = numcores)
    else
        final_eyes = fee([lolli.eyes[2:end]..., eye_smear]; final = true,
                         diagnostic = diagnostic)
        fractal_flame!(pix, lolli.eyes[1], final_eyes,
                       num_particles, num_iterations,
                       bounds, res; AT = AT, FT = FT, diagnostic = diagnostic,
                       num_ignore = num_ignore, numthreads = numthreads,
                       numcores = numcores)
    end
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

# This causes a LolliPerson to blink.
function blink!(lolli::LolliPerson, num_frames)

    idx = find_fi(lolli.eyes.fi_set, "eye_height")

    # change eye height over a particular period

end

# This function will check how much time is in `num_frames` and how many frames
# it takes to blink (`blink_frames`) and then blink randomly within the time
function intermittent_blinking(lolli::LolliPerson, num_frames, blink_frames)
end

end
