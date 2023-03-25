export LolliLayer, LolliPerson, run!, postprocess!, simple_eyes, update_fis!,
       blink!

#------------------------------------------------------------------------------#
# Struct Definition
#------------------------------------------------------------------------------#

mutable struct LolliLayer <: AbstractLayer
    head::FractalLayer
    eyes::Union{Nothing, FractalUserMethod}
    body::FractalLayer

    angle::Union{FT, FractalInput} where FT <: Number
    foot_position::Union{Tuple, FractalInput}
    head_height::Union{FT, FractalInput} where FT <: Number

    body_color::FractalUserMethod

    transform::Union{Nothing, FractalUserMethod}
    head_transform::Union{Nothing, FractalUserMethod}
    body_transform::Union{Nothing, FractalUserMethod}

    canvas::Union{Array{C}, CuArray{C}, ROCArray{C}} where C <: RGBA
    position::Tuple
    world_size::Tuple
    ppu::Number
    params::NamedTuple
    postprocessing_steps::Vector{APP} where APP <: AbstractPostProcess
end

LolliPerson(args...; kwargs...) = LolliLayer(args...; kwargs...)

#------------------------------------------------------------------------------#
# Helper Functions / PostProcessing steps
#------------------------------------------------------------------------------#
function dump(lolli::LolliLayer)
    println(lolli)
end

function run!(layer::LolliLayer; diagnostic = false, frame = 0)
    run!(layer.head; diagnostic = diagnostic, frame = frame)
    run!(layer.body; diagnostic = diagnostic, frame = frame)
end

function postprocess!(layer::LolliLayer)
    postprocess!(layer.head)
    postprocess!(layer.body)

    for i = 1:length(layer.postprocessing_steps)
        if !layer.postprocessing_steps[i].initialized
            @info("initializing " *
                  string(typeof(layer.postprocessing_steps[i])) * "!")
            initialize!(layer.postprocessing_steps[i], layer)
        end
        layer.postprocessing_steps[i].op(layer, layer.postprocessing_steps[i])
    end
end

function to_canvas!(layer::LolliLayer, canvas_params::CopyToCanvas)
    to_canvas!(layer)
end

function to_canvas!(layer::LolliLayer)

    if layer.params.ArrayType <: Array
        kernel! = lolli_copy_kernel!(CPU(), layer.params.numcores)
    elseif has_cuda_gpu() && layer.params.ArrayType <: CuArray
        kernel! = lolli_copy_kernel!(CUDADevice(), layer.params.numthreads)
    elseif has_rocm_gpu() && layer.params.ArrayType <: ROCArray
        kernel! = lolli_copy_kernel!(ROCDevice(), layer.params.numthreads)
    end

    wait(kernel!(layer.canvas, layer.head.canvas, layer.body.canvas;
                 ndrange = size(layer.canvas)))
    
    return nothing
end

@kernel function lolli_copy_kernel!(canvas_out, head_canvas, body_canvas)

    tid = @index(Global, Linear)

    if head_canvas[tid].alpha == 0
        canvas_out[tid] = body_canvas[tid]
    else
        canvas_out[tid] = head_canvas[tid]
    end
end

function update_fis!(layer::LolliLayer;
                     fis::Vector{FractalInput} = FractalInput[],
                     head_fis::Vector{FractalInput} = FractalInput[],
                     body_fis::Vector{FractalInput} = FractalInput[])
    l = length(fis) + length(head_fis)
    if l >= 1
        H = layer.head.H1
        H2 = layer.head.H2
        for i = 1:length(fis)
            for j = 1:length(H.fi_set)
                if fis[i].name == H.fi_set[j].name
                    H.fi_set[j] = fis[i]
                end
            end
            if H2 != nothing
                for j = 1:length(H2.fi_set)
                    if fis[i].name == H2.fi_set[j].name
                        H2.fi_set[j] = fis[i]
                    end
                end
            end
        end
        for i = 1:length(head_fis)
            for j = 1:length(H.fi_set)
                if head_fis[i].name == H.fi_set[j].name 
                    H.fi_set[j] = head_fis[i]
                end
            end
            if H2 != nothing
                for j = 1:length(H2.fi_set)
                    if head_fis[i].name == H2.fi_set[j].name
                        H2.fi_set[j] = head_fis[i]
                    end
                end
            end

        end
        update_fis!(H)
        if H2 != nothing
            update_fis!(H2)
        end
    end

    l = length(fis) + length(body_fis)
    if l >= 1
        H = layer.body.H1
        H2 = layer.body.H2
        for i = 1:length(fis)
            for j = 1:length(H.fi_set)
                if fis[i].name == H.fi_set[j].name 
                    H.fi_set[j] = fis[i]
                end
            end
            if H2 != nothing
                for j = 1:length(H2.fi_set)
                    if fis[i].name == H2.fi_set[j].name
                        H2.fi_set[j] = fis[i]
                    end
                end
            end
        end
        for i = 1:length(body_fis)
            for j = 1:length(H.fi_set)
                if body_fis[i].name == H.fi_set[j].name 
                    H.fi_set[j] = body_fis[i]
                end
            end
            if H2 != nothing
                for j = 1:length(H2.fi_set)
                    if head_fis[i].name == H2.fi_set[j].name
                        H2.fi_set[j] = head_fis[i]
                    end
                end
            end
        end
        update_fis!(H)
        if H2 != nothing
            update_fis!(H2)
        end
    end
end

function zero!(layer::LolliLayer)
    zero!(layer.head)
    zero!(layer.body)
    zero!(layer.canvas)
end

#------------------------------------------------------------------------------#
# LolliPerson Specifics
#------------------------------------------------------------------------------#

lean_head = @fum function lean_head(x, y;
                                    foot_position = (0.0, 0.0),
                                    head_radius = 0.25,
                                    lean_velocity = 0.0,
                                    lean_angle = 0.0)
    x_temp = x - foot_position[2]
    y_temp = y - foot_position[1]

    lean_angle += lean_velocity*x_temp/head_radius

    x_temp2 = x_temp*cos(lean_angle) - y_temp*sin(lean_angle)
    y_temp = x_temp*sin(lean_angle) + y_temp*cos(lean_angle)

    x = x_temp2 + foot_position[2]
    y = y_temp + foot_position[1]
    
end

lean_body = @fum function lean_body(x, y;
                                    height = 1.0,
                                    foot_position = (0,0),
                                    lean_velocity = 0.0,
                                    lean_angle = 0.0)
    x_temp = x - foot_position[2]
    y_temp = y - foot_position[1]

    lean_angle *= -(y - foot_position[1])/(0.5*height)
    lean_angle += lean_velocity*x_temp/(0.1*height)

    x_temp2 = x_temp*cos(lean_angle) - y_temp*sin(lean_angle)
    y_temp = x_temp*sin(lean_angle) + y_temp*cos(lean_angle)

    x = x_temp2 + foot_position[2]
    y = y_temp + foot_position[1]

end

simple_eyes = @fum function simple_eyes(x, y;
                                        height = 1.0,
                                        ellipticity = 2.5,
                                        location = (0.0, 0.0),
                                        inter_eye_distance = height*0.150,
                                        color = (1,1,1,1),
                                        size = height*0.08,
                                        show_brows = false,
                                        brow_angle = 0.0,
                                        brow_size = (0.3, 1.25),
                                        brow_height = 1.0)
    head_position = (-height/4, 0.0)
    location = location .+ head_position
    r2 = size*0.5
    r1 = ellipticity*r2
    y_height = location[1] + r1 - 2*r1 * brow_height
    if y >= y_height
        if in_ellipse(x,y,location.+(0, 0.5*inter_eye_distance),0.0,r1,r2) ||
           in_ellipse(x,y,location.-(0, 0.5*inter_eye_distance),0.0,r1,r2)
            red = color[1]
            green = color[2]
            blue = color[3]
            alpha = color[4]
        end
    end

    if Bool(show_brows)
        brow_size = brow_size .* size
        brow_x = 0.5*inter_eye_distance + brow_size[2]*0.1
        if in_rectangle(x, y, (y_height-brow_size[1]*0.5, brow_x),
                        brow_angle, brow_size[2], brow_size[1]) ||
           in_rectangle(x, y, (y_height-brow_size[1]*0.5, -brow_x),
                        brow_angle, brow_size[2], brow_size[1])
            red = color[1]
            green = color[2]
            blue = color[3]
            alpha = color[4]
        end
    end

end

function LolliLayer(height; angle=0.0, foot_position=(height*0.5,0.0),
                    body_multiplier = min(1, height),
                    eye_color = Shaders.white, body_color = Shaders.black,
                    head_position = (-height*1/4, 0.0),
                    head_radius = height*0.25,
                    name = "", ArrayType = Array, diagnostic = false,
                    known_operations = [],
                    ppu = 1200, world_size = (0.9, 1.6),
                    num_particles = 1000, num_iterations = 1000,
                    postprocessing_steps = Vector{AbstractPostProcess}([]),
                    eye_fum::Union{FractalUserMethod, Nothing} = nothing,
                    fis::Vector{FractalInput} = FractalInput[],
                    head_fis::Vector{FractalInput} = FractalInput[],
                    body_fis::Vector{FractalInput} = FractalInput[])

    head_fis = vcat(head_fis, fis)
    body_fis = vcat(body_fis, fis)

    # Going through all Fractal Inputs and checking to see if we need additional
    # Hutchinson operators
    H2_head = nothing
    H2_body = nothing
    for i = 1:length(fis)
        if fis[i].name == "lean_angle"
            lean_velocity_idx = find_fi(fis, "lean_velocity")
            if lean_velocity_idx != nothing
                lean_velocity = fis[lean_velocity_idx]
            else
                lean_velocity = 0.0
            end
            H_head = Hutchinson(lean_head(lean_angle = fis[i],
                                          lean_velocity = lean_velocity,
                                          head_radius = head_radius,
                                          foot_position = foot_position);
                                diagnostic = diagnostic,
                                name = "lean_head_"*name,
                                final = true, fis = head_fis)
            if H2_head == nothing
                H2_head = H_head
            else
                H2_head = fee(Hutchinson, (H_head, H2_head))
            end

            H_body = Hutchinson(lean_body(lean_angle = fis[i],
                                          lean_velocity = lean_velocity,
                                          foot_position = foot_position,
                                          height = height);
                                diagnostic = diagnostic,
                                name = "lean_body_"*name,
                                final = true, fis = body_fis)
            if H2_body == nothing
                H2_body = H_body
            else
                H2_body = fee(Hutchinson, (H_body, H2_body))
            end
        end
    end

    if eye_fum == nothing
        eye_fum = simple_eyes(height = height)
    end

    postprocessing_steps = vcat([CopyToCanvas()], postprocessing_steps)
    offset = 0.1*body_multiplier
    layer_position = (foot_position[1] - height*0.5, foot_position[2])
    body = define_rectangle(; position = foot_position .- (height*0.25, 0),
                              rotation = 0.0,
                              scale_x = 0.1*body_multiplier,
                              scale_y = 0.5*height-offset,
                              color = body_color,
                              name = "body"*name,
                              diagnostic = diagnostic,
                              additional_fis = body_fis)

    body_layer = FractalLayer(num_particles = num_particles,
                              num_iterations = num_iterations,
                              ppu = ppu, world_size = world_size,
                              position = layer_position, ArrayType = ArrayType,
                              H1 = body, H2 = H2_body)

    head = define_circle(; position = head_position,
                           radius = head_radius,
                           color = overlay(body_color, eye_fum),
                           name = "head"*name,
                           diagnostic = diagnostic,
                           additional_fis = head_fis)

    head_layer = FractalLayer(num_particles = num_particles,
                              num_iterations = num_iterations,
                              ppu = ppu, world_size = world_size,
                              position = layer_position, ArrayType = ArrayType,
                              H1 = head, H2 = H2_head)

    canvas = copy(head_layer.canvas)
    return LolliLayer(head_layer, eye_fum, body_layer, angle, foot_position,
                      height, body_color, nothing, nothing, nothing,
                      canvas, layer_position, world_size, ppu,
                      params(LolliLayer; ArrayType = ArrayType),
                      postprocessing_steps)
    
end

#------------------------------------------------------------------------------#
# LolliPerson Animations
#------------------------------------------------------------------------------#

# This causes a LolliPerson to blink.
function blink!(lolli::LolliLayer, curr_frame, start_frame, end_frame)
    # split into 3rds, 1 close, 1 closed, 1 open
    third_frame = (end_frame - start_frame)*0.333

    fi_set = lolli.head.H1.fi_set
    if curr_frame < start_frame + third_frame
        brow_height = 1 - (curr_frame - start_frame)/(third_frame)
    elseif curr_frame >= start_frame + third_frame &&
           curr_frame <= start_frame + third_frame*2
        brow_height = 0.0
    else
        brow_height = (curr_frame - start_frame - third_frame*2)/(third_frame)
    end

    if brow_height < 1.0
        show_brows = true
    else
        show_brows = false
    end

    brow_height_idx = find_fi(fi_set, "brow_height")
    if isnothing(brow_height_idx)
        @warn("Brow height not set as FractalInput. Blinking will not work!")
    else
        fi_set[brow_height_idx] = set(fi_set[brow_height_idx], brow_height)

    end

    show_brows_idx = find_fi(fi_set, "show_brows")
    if isnothing(show_brows_idx)
        @warn("show_brows not set as FractalInput. Blinking will not work!")
    else
        fi_set[show_brows_idx] = set(fi_set[show_brows_idx], show_brows)
    end

    update_fis!(lolli; head_fis = fi_set)
end
