const EXE7Z_LOCK = ReentrantLock()
const EXE7Z = Ref{String}()

function exe7z()
    # If the JLL is available, use the wrapper function defined in there
    if p7zip_jll.is_available()
        return p7zip_jll.p7zip()
    end

    lock(EXE7Z_LOCK) do
        if !isassigned(EXE7Z)
            EXE7Z[] = find7z()
        end
        return Cmd([EXE7Z[]])
    end
end

function find7z()
    pathsep = @static Sys.iswindows() ? ';' : ':'
    path = join((joinpath(Sys.BINDIR, Base.LIBEXECDIR), Sys.BINDIR, ENV["PATH"]), pathsep)
    bin = withenv("PATH" => path) do
        Sys.which("7z")  # Automatically tries ".exe" extension
    end
    bin !== nothing && return bin
    error("7z binary not found")
end

"""
    unpack(archive, directory, [files]; [verbose=false]) -> Nothing

Unpacks files from a compressed tarball `archive` to the specified `directory`. If
specified, only the `files` listed will be extracted. When `verbose` is set additional
details will be sent to `stdout`.
"""
function unpack(archive, directory, files=String[]; verbose::Bool=false)
    show_output = verbose ? `-bso1` : `-bso0`
    run(pipeline(
        `$(exe7z()) x $archive -y -so`,
        `$(exe7z()) x -y -si -ttar -ba -bd -bb1 $show_output -o$directory $files`,
    ))
    return nothing
end

"""
    isarchive(path) -> Bool

Determines if the given `path` is an archive.
"""
function isarchive(path::AbstractString)
    return success(`$(exe7z()) t $path -y`)
end

"""
    list(archive::AbstractString) -> Vector{String}

Returns the file names contained in the `archive`.
"""
function list(archive::AbstractString)
    cmd = pipeline(`$(exe7z()) x $archive -y -so`, `$(exe7z()) l -y -si -ttar -ba`)
    files = map(eachline(cmd)) do line
        # Extract the file name from the last column in the 7-zip output table.
        line[54:end]
    end
    return files
end
