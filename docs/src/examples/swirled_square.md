# A Swirled Square

This is a quick example to show how to use Fable.jl

## Step 1: create a square

First, we should create a square.
To do this, we need to set up Fable with the right parameters:

```
    # Physical space location. 
    world_size = (9*0.15, 16*0.15)

    # Pixels per unit space
    # The aspect ratio is 16x9, so if we want 1920x1080, we can say we want...
    ppu = 1920/world_size[2]

```

Right now, this part of the API is in flux, but we need some sort of physical world to hold the objects in, so we set this to be some size (`world_size = (9*0.15, 16*0.15)`).
We also define the *Pixels Per Unit* or `ppu` value.
The resolution should be the `world_size * ppu`, so if we want a 1920x1080 image, we need to set the ppu accordingly (here we set it as `1920/world_size[2]`).
This will be replaced with a camera struct eventually.

Now we need to define a color.
This can be done by passing in an array or tuple (such as `color = [1.0, 0, 0, 1]` for red), or as an array of arrays or tuples, like:

```
    colors = [[1.0, 0.25, 0.25,1],
              [0.25, 1.0, 0.25, 1],
              [0.25, 0.25, 1.0, 1],
              [1.0, 0.25, 1.0, 1]]

```

In this case, each row of the array will define the color of a different quadrant of the square.
Now we can define our fractal executable...

```
H = create_square(; position = [0.0, 0.0], rotation = pi/4, color = colors)
```

Here, `ArrayType` can be either an `Array` or `CuArray` depending whether you would like to run the code on the CPU or (CUDA / AMD) GPU.
`num_particles` and `num_iterations` are the number of points we are solving with for the chaos game and the number of iterations for each point.
The higher these numbers are, the better resolved our final image will be.
Notationally, we are using the variable `H` to designate a Hutchinson operator, which is the mathematical name for a function set.

Finally, we need to attach this function to the layer and run everything with the `run!(...)` function and write it to an image:

```
    layer = FableLayer(; ArrayType = ArrayType, logscale = false,
                         world_size = world_size, ppu = ppu, H = H,
                         num_particles = num_particles,
                         num_iterations = num_iterations)

    run!(layer)

    write_image(layer; filename = "out.png")

```

Note that the `H = H` keyword argument is the one actually defining `H` as the first Hutchinson operator for the `FableLayer`.
After running this, we will get the following image:

![a simple square](res/swirled_square_1.png)

The full code can be found at the bottom of this page

## Step 2: swirl the square

Next, we will try to "swirl the square" by also adding another fractal executable to the mix, the swirl operator (defined already in Fable.jl):

```
swirl = @fum function swirl(x, y)
    r = sqrt(y*y + x*x)

    v1 = x*cos(r*r) + y*sin(r*r)
    v2 = x*sin(r*r) - y*cos(r*r)

    y = v1
    x = v2
    return point(y,x)
end
```

Here, we are using the `@fum` syntax to show how users might define their own operators.
The same can be done for colors.

The code here does not change significantly, except that we create a `H_post` and add it to the `fractal_flame(...)` function:

```
...
    H_post = Hutchinson(swirl_operator)

    layer = FableLayer(res; ArrayType = ArrayType, logscale = false,
                         FloatType = FloatType, H = H, H_post = H_post,
                         num_particles = num_particles,
                         num_iterations = num_iterations)

    run!(layer)
...
```

There are a few nuances to point out:

1. We are using `Shaders.previous`, which simply means that the swirl will use whatever colors were specified in `H`.
2. Fable operators can be called with `fee` or `Hutchinson` and require `Array` or `Tuple` inputs.
3. `final = true`, means that this is a post processing operation. In other words, `H` creates the object primitive (square), and `H_post` always operates on that square.
4. We are specifying the Floating Type, `FloatType`, as `Float32`, but that is not necessary.

Once this is run, it should provide the following image:

![a swirled square](res/swirled_square_2.png)

## Step 3: a different kind of swirl

Now some people might be scratching their heads at the previous result.
If we are solving with both `H` and `H_post`, why does it look like two separate actions instead of one combined one?
In other words, why is the swirl so clearly different than the square operation?

This is because we operate on two separate sets of points.
`H` creates object primitives. Every step of the simulation, we will read from the points after `H` operates on them.
`H_post` works on a completely different location in memory specifically for image output.
If we want, we can make `H_post` operate on the object, itself, by creating a new fractal executable:

```
    final_H = fee(Hutchinson, [H, H_post])

    layer = FableLayer(res; ArrayType = ArrayType, logscale = false,
                         FloatType = FloatType, H = final_H
                         num_particles = num_particles,
                         num_iterations = num_iterations)

    run!(layer)

```

which will create the following image:

![a swirled square (again)](res/swirled_square_3.png)

## The full example

```
function square_example(num_particles, num_iterations;
                        ArrayType = Array,
                        dark = true,
                        transform_type = :standard,
                        filename = "out.png")
    # Physical space location. 
    world_size = (9*0.15, 16*0.15)

    # Pixels per unit space
    # The aspect ratio is 16x9, so if we want 1920x1080, we can say we want...
    ppu = 1920/world_size[2]

    colors = [[1.0, 0.25, 0.25,1],
              [0.25, 1.0, 0.25, 1],
              [0.25, 0.25, 1.0, 1],
              [1.0, 0.25, 1.0, 1]]

    H = create_square(; position = [0.0, 0.0], rotation = pi/4,  color = colors)
    swirl_operator = fo(Flames.swirl)
    H_post = nothing
    if transform_type == :outer_swirl
        H_post = Hutchinson(swirl_operator)
    elseif transform_type == :inner_swirl
        H = fee(Hutchinson, [H, Hutchinson(swirl_operator)])
    end

    layer = FableLayer(; ArrayType = ArrayType, logscale = false,
                         world_size = world_size, ppu = ppu,
                         H = H, H_post = H_post,
                         num_particles = num_particles,
                         num_iterations = num_iterations)

    run!(layer)

    write_image(layer; filename = filename)
end

```
