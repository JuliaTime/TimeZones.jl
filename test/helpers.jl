# Utility functions for testing
import Compat

function ignore_output(body::Function; stdout::Bool=true, stderr::Bool=true)
    out_old = Compat.stdout
    err_old = Compat.stderr

    if stdout
        (out_rd, out_wr) = redirect_stdout()
    end
    if stderr
        (err_rd, err_wr) = redirect_stderr()
    end

    result = try
        body()
    finally
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
    end

    return result
end
