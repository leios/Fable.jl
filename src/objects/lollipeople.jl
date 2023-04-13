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

function run!(layer::LolliLayer; frame = 0)
    run!(layer.head; frame = frame)
    run!(layer.body; frame = frame)
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
    
    return point(y,x)
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

    return point(y,x)
end

simple_eyes = @fum color function simple_eyes(x, y;
                                              height = 1.0,
                                              ellipticity = 2.5,
                                              location = (0.0, 0.0),
                                              inter_eye_distance = height*0.150,
                                              eye_color=RGBA{Float32}(1,1,1,1),
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
            return eye_color
        end
    end

    if Bool(show_brows)
        brow_size = brow_size .* size
        brow_x = 0.5*inter_eye_distance + brow_size[2]*0.1
        if in_rectangle(x, y, (y_height-brow_size[1]*0.5, brow_x),
                        brow_angle, brow_size[2], brow_size[1]) ||
           in_rectangle(x, y, (y_height-brow_size[1]*0.5, -brow_x),
                        brow_angle, brow_size[2], brow_size[1])
            return eye_color
        end
    end

    return color

end

function LolliLayer(height; angle=0.0, foot_position=(height*0.5,0.0),
                    body_multiplier = min(1, height),
                    eye_color = Shaders.white, body_color = Shaders.black,
                    head_position = (-height*1/4, 0.0),
                    head_radius = height*0.25,
                    name = "", ArrayType = Array,
                    known_operations = [],
                    ppu = 1200, world_size = (0.9, 1.6),
                    num_particles = 1000, num_iterations = 1000,
                    postprocessing_steps = Vector{AbstractPostProcess}([]),
                    eye_fum::Union{FractalUserMethod, Nothing} = nothing,
                    head_smears = Vector{FractalOperator}([]),
                    body_smears = Vector{FractalOperator}([]))

    H2_head = nothing
    H2_body = nothing

    if length(head_smears) > 0
        H2_head = Hutchinson()
        for i = 1:length(head_smears)
            H2_head = Hutchinson(H2_head, Hutchinson(head_smears[i]))
        end
    end

    if length(body_smears) > 0
        H2_body = Hutchinson()
        for i = 1:length(body_smears)
            H2_body = Hutchinson(H2_body, Hutchinson(body_smears[i]))
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
                              color = body_color)

    body_layer = FractalLayer(num_particles = num_particles,
                              num_iterations = num_iterations,
                              ppu = ppu, world_size = world_size,
                              position = layer_position, ArrayType = ArrayType,
                              H1 = body, H2 = H2_body)

    head = define_circle(; position = head_position,
                           radius = head_radius,
                           color = (body_color, eye_fum))

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

    fis = lolli.head.H1.color_fis[1][2]
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

    brow_height_idx = find_fi_index(:brow_height, fis)
    if isnothing(brow_height_idx)
        @warn("Brow height not set as FractalInput. Blinking will not work!")
    else
        set!(fis[brow_height_idx], brow_height)
    end

    show_brows_idx = find_fi_index(:show_brows, fis)
    if isnothing(show_brows_idx)
        @warn("show_brows not set as FractalInput. Blinking will not work!")
    else
        set!(fis[show_brows_idx], show_brows)
    end
end
