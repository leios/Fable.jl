# Time Interaface

To be honest, the time interface for Fable.jl is under construction and not *quite* ready for general use; however, as an *animation* engine, it does allow users to use some form of "time" component for each `FableUserMethod`.

The most important thing to note is that **Fable.jl fundamentally animates per frame, not based on real time!** This simply means that the variable sent to each `FableUserMethod` is not `time`, but the current `frame`.

## How to use the Fable.jl time interface

Right now, simply create a `FableUserMethod` that uses the `frame` variable, and then pass some time argument along to your `run!(...)` function as a keyword argument:

```
run!(layer; time = t)
```

Here `t` could be a `Float` that represents the number of seconds, an `Int` that represents the current frame, or a Unitful quantity (like `1u"s") which represents some other unit of time.

I'll be adding more to these docs as the time interface becomes more stable, but for now, please feel free to let me know what you think on the [relevant issue](https://github.com/leios/Fable.jl/issues/53)!
