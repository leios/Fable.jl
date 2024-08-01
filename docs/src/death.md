# The Future of Fable(.jl)

Alright. I'm going to lay it all on the line here. Fable(.jl) will no longer be developed by me at this point in time.
I have moved on to a new project, [quibble](https://github.com/leios/quibble).

Let's talk about that in detail.

This rendering engine has taken many forms:

1. **FFlamify.jl** was an attempt to do fast fractal flame rendering in Julia. It worked, but it wasn't fast.
2. **Fae.jl** was a Fractal Animation Engine that used the FFlamify idea and then extended it to general purpose rendering.
3. **Fable.jl** was / is the final incarnation of that idea in Julia. It took years of full time work and I was never really happy with it.

A few weeks ago, I took an afternoon to rewrite the heart of the code in OpenCL C.
I got it working and it was lightning fast.
To reiterate: I got it to work in an *afternoon in C.*
That was "the final nail in the coffin" for me.
It made me realize I was in a bit of a bubble and flushed two years of full time effort down the drain.

That said, I do wholeheartedly believe that Julia has the best GPGPU ecosystem in the business.
It's just that for this specific project, I cannot use Julia.
Rather, I *can*.
There's a possibility that SPIRV(.jl) and Vulkan(.jl) can save me here, but I really need a break for now. 

## So What's the Problem?

Fable is a general-purpose rendering engine that does away with the traditional mesh machinery from OpenGL and Vulkan.
It's all function systems.
You can read more about it here in the docs if you are interested.

To be honest, it works.
The runtime is super fast.
Like 5000 frames per second fast.
The problem is that the user-generated functions need to be *compiled* somewhere and compilation (in Julia) can take minutes of time.
The reason I switched to C is that the same process can be done in OpenCL in milliseconds.

So why?
Why is Julia uniquely bad here?
Why is this so hard?

Well, it's not just a Julia issue.
It's also a GPU one.

See, function pointers aren't really properly sussed out in GPU code.
You can technically use them in CUDA with restrictions and in OpenCL 2.1, but OpenCL 1, OpenCL 3, Vulkan, OpenGL, and pretty much every other GPU library forbids them (for good reason).
GPUs are quite different than CPUs.
Memory is limited.
Threads are weak.
Function call graphs, though not incredibly hefty, are hefty enough to be avoided for thread-wise execution.

That said, GPU programming is hard, and most people are not working alone.
If there's only one GPU programmer and several other lab mates all wanting to use their GPU code, then it makes sense to allow for some flexibility.
For that reason, even though function pointers are not straightforward, it's incredibly common for GPU programmers to simulate this functionality in other ways.
Let's discuss how:

1. *The CUDA Approach*: As mentioned earlier, CUDA actually *does* allow for function pointers on the GPU. The problem is that they are limited only to functions compiled in the same CuModule. This effectively means there are two options for simulating general function pointers on CUDA-capable devices:
    1. Mess around with the compilation of the code, itself, to make sure that the appropriate functions are in the same CuModule. There are actually CMake commands to do this.
    2. Send the functions in to your kernel as an Abstract Syntax Tree (or Expression Tree) and parse that on the GPU. To do this, you just need to make sure that all the functions necessary for parsing the AST are in the same module.
2. *The OpenCL Approach*: This approach is way, way easier. Because OpenCL (and OpenGL / Vulkan) separate out the compilation of kernels (shaders), all you need to do to simulate function pointers is throw user code directly into the string that eventually turns into a kernel. For this reason, I often say that "OpenCL has the best metaprogramming of any language I've ever used." It's just so easy to work with.

So now let's talk Julia.
I've been using the language for some time.
I'm a member of the Julia Lab at MIT.
I am a developer of the JuliaGPU ecosystem.

If anyone was going to get this to work in Julia, it would be me.
Or so I thought.
But then came the time to actually write the code.

### Attempt 1: The OpenCL approach

The first thing I tried was generating a giant function string and compiling that into a function with `Meta.parse(...)` and `eval`.
Should I have used `Expr`s directly instead of strings?
Yeah, probably, but string manipulation was easier and I was looking for a proof of concept at the time.
So I did what I could and got the code to work.
The problem was that it was super slow to compile.

At this point, I had already sunk months into development, so I thought, "No problem! I'll fix it in post!"
I then proceeded to package things up and get it ready for the Julia Registries.
Just one small problem.

As I started to encapsulate everything into a more usable API, I found that it was really difficult to use `eval`ed code in other functions.
The problem is that Julia's compiler does not allow for users to call code that was compiled at a later time (in a different `world`).
Up until this point, I had been doing most of my development in the REPL, so I had somehow completely avoided this issue.

Now, there is a solution: `Base.@invokelatest`.
This function will force a function written at an older time to accept a newer function, but it comes at a small cost.
At the time, I thought that my compile times were already too long and I was not willing to spend another half-second at this step, so I looked for other options.
Also, due to a bug in AMDGPU,jl (which has since been fixed), my entire system was crashing quite regularly and at random due to this codebase.

So let's talk about the "Julia way."

### Attempt 2: Macros, macros, and more macros.

In Julia, macros are powerful. 
They can do just about anything you want to do with `Expr`s
So I thought this would be the perfect solution to my problem.
But let's define the problem in more detail.

There are essentially 4 levels of metaprogramming:

1. The variable scope. To avoid recompilation, it's important to tag certain variables as "dynamic" (stuff that could change during the runtime). For example, if you have a point that needs to move around in space, the actual location of that point might be a variable input value. These values are essentially stored in a large buffer to be sent in to the GPU at the last minute.
2. The user function stage. This is where users write their own functions to manipulate their point clouds. It's equivalent to vertex and fragment shading in OpenGL and essentially moves and colors individual points.
3. The generator stage. This is where the user's functions all get stitched together into a larger function, along with a generator for the initial primitive (squares, circles, etc) before transformation.
4. The executable stage. Here, multiple objects are all bound to the same layer and all the extra GPU junk is tacked on.

I suppose these stages could be simplified, but I found them to be the easiest to reason about.
The problem is that implementing this pipeline exclusively with macros is difficult because they *only accept expressions*.
If you do:

```
expr = @macro_1 stuff
@macro_2 expr
```

`@macro_2` will not see the components of the variable `expr`, but the single symbol `:expr`, itself, which is essentially useless.

So what do you do?
You macro some stuff, and `@generate` others.
`@generated` functions are special functions that generate function bodies based on the type information of the arguments.
Let me pause here.

Remember how I just tried the OpenCL approach in Julia *and it worked*?
What was I doing there?
I was generating a large function body with my own tooling.
What am I doing with the macro approach?
The same thing!
I am now just using less flexible tooling that is bound by weird restrictions that Julia decides to impose on me.
But, macros are probably much more safe than whatever I was doing before, so it's best to use them when possible.

This approach involved passing all the functions in as a Tuple (of mixed type because functions are all designated to have their own type in Julia).
I will say that the final code was very, very unique and the closest thing to "real" function pointers I've seen on the GPU.
The only issue was that I could not iterate through the Tuple of functions.
Considering I was literally trying to solve *iterated* function systems, this was a huge problem.
So I needed to `@generate` a function that would call my specific function from the Tuple with a fixed index (`1` instead of `i`).
This meant that if I passed in 100 functions, I would `@generate` a 100 `if` statement block and would call that function any time I wanted to call `fxs[i]`.

Throughout this process, I needed constant help.
I didn't know how to `@generate` the right functions.
I couldn't figure out how to configure the functions with the right key word arguments.
I ran into an LLVM bug that (let's face it) would have been impossible for me to solve without someone else.

At the end of the day, my code felt...
bad.
I can't really describe it.

Never in my life have I copied code from someone else.
Sure, there's sometimes the odd bit of boilerplate that I yoink and twist from StackOverflow, but it's never more than a few odd lines here and there.

When I was done with this version of the code, it didn't feel like mine.
The macros were all basically designed by a friend.
It was prone to breaking at any point in time without me understanding why.
There was one, specific bug that would send me straight into a panic because it always took a full month to solve and I had hit it almost 10 times ad that point.

Regardless, the code worked.
Just like before.

This time I did some testing and was quite pleased with the runtime results.
However, compile time was abysmal.
For a simple system, I was averaging 70 seconds to compile a kernel that would run in 0.0001 s.
As much as I tried to avoid recompilation, it's hard to do when you need to dynamically generate a new scene for testing each frame.

This meant that I was spending literal hours out of my day just waiting for Julia to finish compiling.

So I reached out to the GPU channel on slack (instead of the Julia Lab folks) and asked for help, only to receive a relatively unhelpful set of answers.
I understand that that was entirely my fault.
I had asked so many people for help with this project, that I had failed to adequately document my issues on github because I thought they were "well known."
More than that, I had solved this exact problem so many times in my career, I was genuinely surprised that others were not stumbling into them as well.

So I (finally) created the issues and kept at it.

### Attempt 3 and performance tests.

At this point, I was frazzled beyond belief and felt like I had just been majorly gaslighted.
I had solved this very problem multiple times before.
In CUDA.
In OpenCL.
In Julia even.
This was possible.
It should be fast to compile.

So I went back to the first strategy, but used `Expr`s this time.
And you know what?
It was faster than the `@generated` approach.
By a lot.

But I decided to take it one step further and actually implement the same functionality in OpenCL.
I did it in an afternoon after years of leaving my C skills to collect dust.
The fact that I could do it in an afternoon already speaks volumes:
1. I am not insane. This is actually a fairly trivial thing to do.
2. OpenCL's actually great. I'm a big fan.

So let's put some rough numbers down.
The compile time for composing 2000 (super simple) functions:

1. With `Base.Cartesian.@nif`: 26 seconds
2. With evaluating a set of exprs: 10 seconds
3. With OpenCL C: negligible. ~100ms for everything.

Note that `@nif` cannot do much larger without erroring, but methods 2 and 3 can keep going. OpenCL even starts to sweat at 200,000 functions (4 seconds overall time).

The runtimes for all these cases are negligible (something like 0.001 s).
Also: all the code is at the end.

Now you might be asking, "Ok. But do you really need to compile 2000 functions?"
Yeah.
Probably more actually.
I can mess around with object culling, but if I want somewhat realistic imagery, I need a lot of objects.
Maybe it's not 2000 functions, exactly, but it will certainly be the same level of complexity at the end of the day.
The fact that I could easily go up to kernels with 200,000 lines of code in OpenCL was really reassuring that it could handle almost any task I could throw at it.

The truth is that I would love to get this engine to work in realtime.
It's runtime is fast enough that I should be able to.
All I need to do is find clever ways to mask the compile time.
That's easy enough if the compile time is less than a second, but 10 seconds is a little too long.
26 seconds is completely unreasonable.

So...

## Let's talk Julia

Alright.
Now for the elephant in the room.
Am I quitting Julia?

Kinda.

There is a future where compile times get way better, even sub 1 second in Julia, but I don't see them ever catching up to OpenCL.
Even if they did catch up, I am really burnt out from Julia programming right now.
Like I said before, the more I embrace Julia tooling, the less I feel like I actually understand the code that I'm writing and I don't like that feeling.
For this reason, even if compile times go down, I don't know if I'll ever feel comfortable returning to the language for this project.
But feelings change.
Ideas change.
There could be a future timeline where I come back.
I just don't know what it will take to bump me over to that timeline.

I don't want to make this a "hit piece" against the language or anything.
I do genuinely feel it is great and has the best GPGPU ecosystem in the business.
But (for me) it's really bogged down by Julia, itself.

Higher level languages have always been difficult for me to understand.
I know loops.
I know functions.
I know conditionals.

When I see matlab code, my eyes bug out.
I don't know what to look for or how to reason about the text in front of me because the things I just listed are usually missing from the code entirely.
It becomes even harder to read when your code starts to look too much like math.

Julia has a kinda similar problem.
There are all these functions I just "need to know about" to write performant code.
I need `@inbounds` to stop Julia from checking my bounds for me.
I need `@generated` functions to do metaprogramming for me.
I need abstract types and multiple dispatch and function closures and runtime generated functions and...
It's just so much stuff I need to think about and I feel like I am in a constant fight with the compiler.

Back when I was writing the Algorithm Archive, I used to write the initial code snippets in C++.
Why?
I like C++.
It's C, but with a few new tools sprinkled in.

Well, that's what I thought.
But C++14 is way different than C++11, which is obviously incredibly different than C99.
So when you write C++ code, there will always be someone, somewhere critiquing it and saying, "well, you should have done it this way."

That's what happens when you give programmers too many tools.
All of a sudden, the right approach is unclear.
In fact there is probably no objectively "correct" answer.
If you ask anyone for advice, though, your solution was "objectively wrong."

And that's how I have felt writing Julia code.
It just always feels like I'm looking over my shoulder and doing something wrong.
It's really taken away my love of programming.

The problem is that even in this case, my gut was right!
`eval`ing `Expr`s ended up being faster *and* more flexible.
But I know there will be a Julia user somewhere saying, "Ah, but you did your `@generated` functions wrong."
And I think you might be right.
There could have been a way to do things faster that I just didn't know about.
But that's the core problem.

Going back to C was a huge breath of fresh air.
I recognize I am in my "honeymoon phase" right now and that feeling will die off soon, but for now, I am happy enough.
I prefer simplicity to ease of use.

I don't really have a way to wrap this up, so...

## Let's look at the code.

I wrote two quick examples for performance testing.
To be honest, they are ugly.
I guess I could clean them up, but I don't care to.

Long story short, I created 20 functions, and then looped through them all in a kernel and executing them all on each thread.
I would then increase the number of functions by concatenating things together into a big set of functions.

### `@generated` method

```
using KernelAbstractions
using AMDGPU

f_1(x) = x + 1
f_2(x) = x + 2
f_3(x) = x + 3
f_4(x) = x + 4
f_5(x) = x + 5
f_6(x) = x + 6
f_7(x) = x + 7
f_8(x) = x + 8
f_9(x) = x + 9
f_10(x) = x + 10
f_11(x) = x + 11
f_12(x) = x + 12
f_13(x) = x + 13
f_14(x) = x + 14
f_15(x) = x + 15
f_16(x) = x + 16
f_17(x) = x + 17
f_18(x) = x + 18
f_19(x) = x + 19
f_20(x) = x + 20

@generated function call_fxs(fxs, fidx, args...)
    N = length(fxs.parameters)
    quote
       Base.Cartesian.@nif $(N+1) d->fidx==d d->return fxs[d](args...) d->error(
"fidx oob")
    end
end

function run(n)
    @kernel function call_fxs_kernel(a, fxs)
        i = @index(Global, Linear)
        for j = 1:length(fxs)
            @inbounds a[i] = call_fxs(fxs, j, a[i])
        end
    end

    a = AMDGPU.zeros(10)
    #a = zeros(10)
    @time begin
        fxs = (f_1, f_2, f_3, f_4, f_5, f_6, f_7, f_8, f_9, f_10,
               f_11, f_12, f_13, f_14, f_15, f_16, f_17, f_18, f_19, f_20)
        base_fxs = fxs
        for i = 2:n
            fxs = (fxs..., base_fxs...)
        end
        println(length(fxs))
        backend = get_backend(a)
        kernel = call_fxs_kernel(backend, 256)
        AMDGPU.@time begin
            kernel(a, fxs; ndrange = length(a))
            synchronize(backend)
        end
    end
    @time begin
        AMDGPU.@time begin
            kernel(a, fxs; ndrange = length(a))
            synchronize(backend)
        end
    end
end
```

### Fable method
You need to use some tooling from my latest `remove_points` branch:

```
using Fable
using MacroTools
using KernelAbstractions
using AMDGPU

macro fable_run(ex)
    esc(ex)
end

struct Exe{F}
    f::F
end

function Exe(expr::Expr, name, backend) 
    eval(expr)
    eval(:(Exe(eval($name)($backend))))
end

function (E::Exe{F})(args...; kwargs...) where F 
    E.f(args...; kwargs...)
end 

function combine_to_fx(name, fums)
    def = Dict([:name => name, :args => Any[:x], :kwargs => Any[],
                :body => fums.body, :whereparams => ()])
    MacroTools.combinedef(def)
end

function create_kernel(name, fxs)
    final_body = Expr(:block,
                      :(i = @index(Global, Linear)),
                      fxs.body)

    def = Dict([:name => name, :args => Any[:x], :kwargs => Any[],
                :body => final_body, :whereparams => ()])
    Expr(:macrocall, Symbol("@kernel"), :(), MacroTools.combinedef(def))
end

function premeh(n)

    f_1 = @fum f_1(x) = @inbounds x[i] += 1
    f_2 = @fum f_2(x) = @inbounds x[i] += 2
    f_3 = @fum f_3(x) = @inbounds x[i] += 3
    f_4 = @fum f_4(x) = @inbounds x[i] += 4
    f_5 = @fum f_5(x) = @inbounds x[i] += 5
    f_6 = @fum f_6(x) = @inbounds x[i] += 6
    f_7 = @fum f_7(x) = @inbounds x[i] += 7
    f_8 = @fum f_8(x) = @inbounds x[i] += 8
    f_9 = @fum f_9(x) = @inbounds x[i] += 9
    f_10 = @fum f_10(x) = @inbounds x[i] += 10
    f_11 = @fum f_11(x) = @inbounds x[i] += 11
    f_12 = @fum f_12(x) = @inbounds x[i] += 12
    f_13 = @fum f_13(x) = @inbounds x[i] += 13
    f_14 = @fum f_14(x) = @inbounds x[i] += 14
    f_15 = @fum f_15(x) = @inbounds x[i] += 15
    f_16 = @fum f_16(x) = @inbounds x[i] += 16
    f_17 = @fum f_17(x) = @inbounds x[i] += 17
    f_18 = @fum f_18(x) = @inbounds x[i] += 18
    f_19 = @fum f_19(x) = @inbounds x[i] += 19
    f_20 = @fum f_20(x) = @inbounds x[i] += 20

    fxs = fuse_fums([(f_1(), f_2(), f_3(), f_4(), f_5(), f_6(), f_7(), f_8(), f_
9(), f_10(), f_11(), f_12(), f_13(), f_14(), f_15(), f_16(), f_17(), f_18(), f_1
9(), f_20()) for i = 1:n]...)
    backend = get_backend(ROCArray([1]))
    Exe(create_kernel(:check, fxs), :check, backend)
end

function meh(exe)
    
    a = AMDGPU.zeros(10)
    backend = get_backend(a)
    #a = zeros(10)

    AMDGPU.@time exe(a; ndrange = length(a))
    AMDGPU.@time exe(a; ndrange = length(a))
    synchronize(backend)
end
```

To avoid the conflicting world age issue, you need to run this as:
```
exe = premeh(n)
meh(exe)
```
