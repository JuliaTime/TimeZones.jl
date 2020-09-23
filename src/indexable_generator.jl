struct IndexableGenerator{I,F}
    g::Base.Generator{I,F}
end

IndexableGenerator(args...) = IndexableGenerator(Base.Generator(args...))
Base.iterate(ig::IndexableGenerator, s...) = iterate(ig.g, s...)

Base.length(ig::IndexableGenerator) = length(ig.g)
Base.size(ig::IndexableGenerator) = size(ig.g)
Base.axes(ig::IndexableGenerator) = axes(ig.g)
Base.ndims(ig::IndexableGenerator) = ndims(ig.g)

Base.getindex(ig::IndexableGenerator, i::Integer) = ig.g.f(ig.g.iter[i])
Base.lastindex(ig::IndexableGenerator) = lastindex(ig.g.iter)
