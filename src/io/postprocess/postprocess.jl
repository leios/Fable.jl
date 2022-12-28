function postprocess!(layer::AL) where AL <: AbstractLayer
    for postprocess in layer.postprocessing_steps
        postprocess.op(layer)
    end
end
