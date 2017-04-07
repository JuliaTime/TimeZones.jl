import Compat: @static, is_windows

"""
    extract(archive, directory, [files]; [verbose=false]) -> Void

Extracts files from a compressed tar `archive` to the specified `directory`. If `files` is
specified only the files given will be extracted. The `verbose` flag can be used to display
additional information to STDOUT.
"""
function extract(archive, directory, files=AbstractString[]; verbose::Bool=false)
    @static if is_windows()
        cmd = pipeline(`7z x $archive -y -so`, `7z x -si -y -ttar -o$directory $files`)
    else
        cmd = `tar xvf $archive --directory=$directory $files`
    end

    if !verbose
        cmd = pipeline(cmd, stdout=DevNull, stderr=DevNull)
    end

    run(cmd)
end

"""
    isarchive(path) -> Bool

Determines if the given `path` is an archive.
"""
function isarchive(path)
    @static if is_windows()
        success(`7z t $path -y`)
    else
        success(`tar tf $path`)
    end
end

"""
    readarchive(archive) -> Vector{AbstractString}

Returns the file names contained in the `archive`.
"""
function readarchive(archive)
    @static if is_windows()
        files = AbstractString[]
        header = "-" ^ 24
        content = false

        cmd = pipeline(`7z x $archive -y -so`, `7z l -si -y -ttar`)
        output = readchomp(pipeline(cmd, stderr=DevNull))
        for line in split(output, "\r\n")
            # Extract the file name from the last column in the 7-zip output table.
            # Note: We can just write `line[54:end]` on Julia 0.5 and up (JuliaLang/julia#15624)
            len = length(line)
            file = len >= 54 ? line[54:len] : ""

            if file == header
                if !content
                    content = true
                else
                    break
                end
            elseif content
                push!(files, file)
            end
        end

        return files
    else
        output = readchomp(pipeline(`tar tf $archive`, stderr=DevNull))
        return split(output, '\n')
    end
end
