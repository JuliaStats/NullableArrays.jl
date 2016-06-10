import Compat: @functorize

@noinline throw_error() = error()

for f in (
    :(@compat Base.:+),
    :(@compat Base.:-),
    :(@compat Base.:!),
    :(@compat Base.:~),
)
    @eval begin
        @inline function $(f){S}(x::Nullable{S})
            if isbits(S)
                Nullable($(f)(x.value), x.isnull)
            else
                throw_error()
            end
        end
    end
end

# Implement the binary operators: +, -, *, /, %, &, |, ^, <<, and >>
for f in (
    :(@compat Base.:+),
    :(@compat Base.:-),
    :(@compat Base.:*),
    :(@compat Base.:/),
    :(@compat Base.:%),
    :(@compat Base.:&),
    :(@compat Base.:|),
    :(@compat Base.:^),
    :(@compat Base.:<<),
    :(@compat Base.:>>),
)
    @eval begin
        @inline function $(f){S1, S2}(x::Nullable{S1}, y::Nullable{S2})
            if isbits(S1) & isbits(S2)
                Nullable($(f)(x.value, y.value), x.isnull | y.isnull)
            else
                throw_error()
            end
        end
    end
end

# Implement the binary operators: == and !=
for f in (
    :(@compat Base.:(==)),
    :(@compat Base.:!=),
)
    @eval begin
        function $(f){S1, S2}(x::Nullable{S1}, y::Nullable{S2})
            if isbits(S1) & isbits(S2)
                Nullable{Bool}($(f)(x.value, y.value), x.isnull | y.isnull)
            else
                error()
            end
        end
    end
end

# Implement the binary operators: <, >, <=, and >=
for f in (
    :(@compat Base.:<),
    :(@compat Base.:>),
    :(@compat Base.:<=),
    :(@compat Base.:>=),
)
    @eval begin
        function $(f){S1, S2}(x::Nullable{S1}, y::Nullable{S2})
            if isbits(S1) & isbits(S2)
                Nullable{Bool}($(f)(x.value, y.value), x.isnull | y.isnull)
            else
                error()
            end
        end
    end
end

# Miscellaneous lifted operators

function Base.abs{T}(x::Nullable{T})
    if isbits(T)
        return Nullable(abs(x.value), x.isnull)
    else
        error()
    end
end

function Base.abs2{T}(x::Nullable{T})
    if isbits(T)
        return Nullable(abs2(x.value), x.isnull)
    else
        error()
    end
end

function Base.sqrt{T}(x::Nullable{T})
    if isbits(T)
        return Nullable(sqrt(x.value), x.isnull)
    else
        error()
    end
end

## Lifted functors

@compat function (::typeof(@functorize(scalarmin))){S1, S2}(x::Nullable{S1}, y::Nullable{S2})
    if isbits(S1) & isbits(S2)
        return Nullable(Base.scalarmin(x.value, y.value), x.isnull | y.isnull)
    else
        error()
    end
end
@compat function (::typeof(@functorize(scalarmax))){S1, S2}(x::Nullable{S1}, y::Nullable{S2})
    if isbits(S1) & isbits(S2)
        return Nullable(Base.scalarmax(x.value, y.value), x.isnull | y.isnull)
    else
        error()
    end
end
