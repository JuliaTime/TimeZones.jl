# Utility functions for testing

function ignore_output(body::Function; stdout::Bool=true, stderr::Bool=true)
    out_old = STDOUT
    err_old = STDERR

    if stdout
        (out_rd, out_wr) = redirect_stdout()
    end
    if stderr
        (err_rd, err_wr) = redirect_stderr()
    end

    result = body()

    if stdout
        redirect_stdout(out_old)
        close(out_wr)
        close(out_rd)
    end
    if stderr
        redirect_stderr(err_old)
        close(err_wr)
        close(err_rd)
    end

    return result
end
