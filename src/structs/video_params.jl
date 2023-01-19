export VideoParams, open_video, close_video

# frame is an intermediate frame before being written to the writer
mutable struct VideoParams
    writer::VideoIO.VideoWriter
    frame::Array{RGB{N0f8}}
    frame_count::Int
end

function VideoParams(res; framerate = 30, filename = "out.mp4",
                     encoder_options = (crf=23,
                                        preset="medium",
                                        pixel_format = "yuv420p"))
    return VideoParams(VideoIO.VideoWriter(filename, RGB{N0f8}, res;
                                           framerate = framerate,
                                           encoder_options = encoder_options),
                       zeros(RGB{N0f8}, res), 0)
end

function open_video(args...; kwargs...)
    if OUTPUT
        return VideoParams(args...; kwargs...)
    else
        return nothing
    end
end

function close_video(v::VideoParams)
    close_video_out!(v.writer)
end

# In the case OUTPUT = false
function close_video(n::Nothing)
end
