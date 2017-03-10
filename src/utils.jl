import Compat: @static, is_windows

"""
    extract(archive, directory, [files]) -> Void

Extracts files from a compressed tar `archive` to the specified `directory`. If `files` is
specified only the files given will be extracted.
"""
function extract(archive, directory, files=String[])
    @static if is_windows()
        run(pipeline(`7z x $archive -y -so`, `7z x -si -y -ttar -o$directory $files`))
    else
        run(`tar xvf $archive --directory=$directory $files`)
    end
end

"""
    @optional(expr)

Creates multiple method signatures to allow optional arguments before required arguments.
For example:

    f(a=1, b=2, c) = ...

becomes:

    f(a, b, c) = ...
    f(a, c) = f(a, 2, c)
    f(c) = f(1, 2, c)
"""
macro optional(ex)
    esc(Expr(:block, optional(ex)...))
end

function optional(ex::Expr)
    funcs = Expr[]
    if ex.head == :function || ex.head == :(=)
        sig, body = ex.args
    else
        throw(ArgumentError("Expected expression to be a function"))
    end

    # Determine the optional arguments that occur prior to the last required argument
    dynamic = Int[]
    last_required = 0
    for (i, arg) in enumerate(sig.args)
        if isa(arg, Expr) && arg.head == :kw
            push!(dynamic, i)
        end

        if isa(arg, Symbol) || arg.head == :(::)
            last_required = i
        end
    end
    dynamic = filter(i -> i < last_required, dynamic)

    # Return early if we don't have to generate additional methods
    isempty(dynamic) && return Expr[ex]

    # Generate a new signature which converts the dynamic arguments to required arguments
    default = Array{Any}(length(dynamic))
    new_sig = Array{Any}(length(sig.args))
    for (i, arg) in enumerate(sig.args)
        if i in dynamic
            name, value = arg.args
            new_sig[i] = name
            default[findin(dynamic,i)] = value
        else
            new_sig[i] = arg
        end
    end

    # Generate the primary function
    push!(funcs, Expr(ex.head, Expr(:call, new_sig...), body))

    # Generate the
    func_call = copy(sig)
    for (i, argument) in enumerate(func_call.args)
        isa(argument, Expr) || continue

        if argument.head == :parameters
            for keyword in argument.args
                keyword.args[2] = keyword.args[1]
            end
        elseif argument.head == :(::)
            func_call.args[i] = argument.args[1]
        elseif argument.head == :kw
            if isa(argument.args[1], Symbol)
                func_call.args[i] = argument.args[1]
            else
                func_call.args[i] = argument.args[1].args[1]
            end
        end
    end

    # Generate additional methods which call the primary function
    while !isempty(dynamic)
        i = pop!(dynamic)

        deleteat!(new_sig, i)
        func_call.args[i] = pop!(default)

        push!(funcs, Expr(:(=), Expr(:call, new_sig...), Expr(:block, copy(func_call))))
    end

    return funcs
end
