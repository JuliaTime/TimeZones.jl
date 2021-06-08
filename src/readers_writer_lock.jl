using Base.Threads: AbstractLock, Atomic

struct StateLock{L} <: AbstractLock
    state::Atomic{UInt8}
end

const ReadersLock = StateLock{:Readers}
const WriterLock = StateLock{:Writer}

function Base.lock(r::ReadersLock)
    while true
        x = r.state[]
        if x != 0xff
            y = x + 0x01
            if Threads.atomic_cas!(r.state, x, y) == x
                break
            end
        end
    end
end

function Base.unlock(r::ReadersLock)
    Threads.atomic_sub!(r.state, 0x01)
end

function Base.lock(w::WriterLock)
    while true
        x = w.state[]
        if x == 0x00
            if Threads.atomic_cas!(w.state, x, 0xff) == x
                break
            end
        end
    end
end

function Base.unlock(w::WriterLock)
    Threads.atomic_xchg!(w.state, 0x00)
end

# https://en.wikipedia.org/wiki/Readers–writer_lock
# https://yizhang82.dev/lock-free-rw-lock

"""
    ReadersWriterLock

Allow for concurrent read-only operations, while providing exclusive access for write
operations.
"""
struct ReadersWriterLock
    readers::ReadersLock
    writer::WriterLock

    function ReadersWriterLock()
        state = Threads.Atomic{UInt8}(0)
        readers = ReadersLock(state)
        writer = WriterLock(state)

        return new(readers, writer)
    end
end
