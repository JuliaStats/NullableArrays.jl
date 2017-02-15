# No longer needed since https://github.com/JuliaLang/julia/pull/15928
# and https://github.com/JuliaLang/julia/issues/16354
if VERSION < v"0.5.0-dev+3610"
    using Base: tty_size, alignment, print_matrix_row, strwidth, showcompact_lim,
                undef_ref_alignment, undef_ref_str

    function Base.show(io::IO, X::NullableArray)
        print(io, typeof(X))
        Base.show_vector(io, X, "[", "]")
    end

    @compat abstract type NULL end

    Base.showcompact(io::IO, ::Type{NULL}) = show(io, NULL)
    Base.show(io::IO, ::Type{NULL}) = print(io, "#NULL")
    Base.alignment(io::IO, ::Type{NULL}) = (5,0)

    function Base.show_delim_array(io::IO, X::NullableArray, op, delim, cl,
                                   delim_one, compact=false, i1=1, l=length(X))
        print(io, op)
        newline = true
        first = true
        i = i1
        if l > 0
            while true
                if !isassigned(X, i)
                    print(io, undef_ref_str)
                    multiline = false
                else
                    x = X.isnull[i] ? NULL : X.values[i]
                    multiline = isa(x, AbstractArray) && ndims(x) > 1 && length(x) > 0
                    newline && multiline && println(io)
                    if !isbits(x) && is(x, X)
                        print(io, "#= circular reference =#")
                    elseif compact
                        showcompact_lim(io, x)
                    else
                        show(io, x)
                    end
                end
                i += 1
                if i > i1+l-1
                    delim_one && first && print(io, delim)
                    break
                end
                first = false
                print(io, delim)
                if multiline
                    println(io); println(io)
                    newline = false
                else
                    newline = true
                end
            end
        end
        print(io, cl)
    end

    function Base.alignment{T,N,U<:NullableArray}(
        io::IO, X::SubArray{T,N,U},
        rows::AbstractVector, cols::AbstractVector,
        cols_if_complete::Integer, cols_otherwise::Integer, sep::Integer
    )
        a = []
        for j in cols
            l = r = 0
            for i in rows
                if isassigned(X, i, j)
                    if isnull(X, i, j)
                        aij = alignment(io, NULL)
                    else
                        aij = alignment(io, values(X, i, j))
                    end
                else
                    aij = undef_ref_alignment
                end
                l = max(l, aij[1])
                r = max(r, aij[2])
            end
            push!(a, (l, r))
            if length(a) > 1 && sum(map(sum, a)) + sep*length(a) >= cols_if_complete
                pop!(a)
                break
            end
        end
        if 1 < length(a) < size(X, 2)
            while sum(map(sum, a)) + sep*length(a) >= cols_otherwise
                pop!(a)
            end
        end
        return a
    end

    function Base.alignment(
        io::IO, X::Union{NullableArray, NullableMatrix},
        rows::AbstractVector, cols::AbstractVector,
        cols_if_complete::Integer, cols_otherwise::Integer, sep::Integer
    )
        a = []
        for j in cols
            l = r = 0
            for i in rows
                if isassigned(X, i, j)
                    if isnull(X, i, j)
                        aij = alignment(io, NULL)
                    else
                        aij = alignment(io, values(X, i, j))
                    end
                else
                    aij = undef_ref_alignment
                end
                l = max(l, aij[1])
                r = max(r, aij[2])
            end
            push!(a, (l, r))
            if length(a) > 1 && sum(map(sum,a)) + sep*length(a) >= cols_if_complete
                pop!(a)
                break
            end
        end
        if 1 < length(a) < size(X, 2)
            while sum(map(sum, a)) + sep*length(a) >= cols_otherwise
                pop!(a)
            end
        end
        return a
    end

    function Base.print_matrix_row{T,N,P<:NullableArray}(
        io::IO, X::SubArray{T,N,P}, A::Vector,
        i::Integer, cols::AbstractVector, sep::AbstractString
    )
        if VERSION < v"0.5.0-dev+1936" # compat issues from
                                    # https://github.com/JuliaLang/julia/pull/13825
            for k = 1:length(A)
                j = cols[k]
                if isassigned(X, i, j)
                    x = isnull(X, i, j) ? NULL : values(X, i, j)
                    a = alignment(x)
                    sx = sprint(showcompact_lim, x)
                else
                    a = undef_ref_alignment
                    sx = undef_ref_str
                end
                l = repeat(" ", A[k][1]-a[1])
                r = repeat(" ", A[k][2]-a[2])
                print(io, l, sx, r)
                if k < length(A); print(io, sep); end
            end
        else
            for k = 1:length(A)
                j = cols[k]
                if isassigned(X, i, j)
                    x = isnull(X, i, j) ? NULL : values(X, i, j)
                    a = alignment(io, x)
                    sx = sprint(showcompact_lim, x)
                else
                    a = undef_ref_alignment
                    sx = undef_ref_str
                end
                l = repeat(" ", A[k][1]-a[1])
                r = repeat(" ", A[k][2]-a[2])
                print(io, l, sx, r)
                if k < length(A); print(io, sep); end
            end
        end
    end

    function Base.print_matrix_row(io::IO,
        X::Union{NullableVector, NullableMatrix}, A::Vector,
        i::Integer, cols::AbstractVector, sep::AbstractString
    )
        if VERSION < v"0.5.0-dev+1936" # compat issues from
                                    # https://github.com/JuliaLang/julia/pull/13825
            for k = 1:length(A)
                j = cols[k]
                if isassigned(X, i, j)
                    x = isnull(X, i, j) ? NULL : values(X, i, j)
                    a = alignment(x)
                    sx = sprint(showcompact_lim, x)
                else
                    a = undef_ref_alignment
                    sx = undef_ref_str
                end
                l = repeat(" ", A[k][1]-a[1])
                r = repeat(" ", A[k][2]-a[2])
                print(io, l, sx, r)
                if k < length(A); print(io, sep); end
            end
        else
            for k = 1:length(A)
                j = cols[k]
                if isassigned(X, i, j)
                    x = isnull(X, i, j) ? NULL : values(X, i, j)
                    a = alignment(io, x)
                    sx = sprint(showcompact_lim, x)
                else
                    a = undef_ref_alignment
                    sx = undef_ref_str
                end
                l = repeat(" ", A[k][1]-a[1])
                r = repeat(" ", A[k][2]-a[2])
                print(io, l, sx, r)
                if k < length(A); print(io, sep); end
            end
        end
    end

    # Methods for compatibility issues for VERSION < 0.5.0-dev+1936 stemming
    # from https://github.com/JuliaLang/julia/pull/13825

    Base.alignment(::Type{NULL}) = (5,0)
    function Base.alignment{T,N,U<:NullableArray}(
        X::SubArray{T,N,U},
        rows::AbstractVector, cols::AbstractVector,
        cols_if_complete::Integer, cols_otherwise::Integer, sep::Integer
    )
        a = []
        for j in cols
            l = r = 0
            for i in rows
                if isassigned(X, i, j)
                    if isnull(X, i, j)
                        aij = alignment(NULL)
                    else
                        aij = alignment(values(X, i, j))
                    end
                else
                    aij = undef_ref_alignment
                end
                l = max(l, aij[1])
                r = max(r, aij[2])
            end
            push!(a, (l, r))
            if length(a) > 1 && sum(map(sum, a)) + sep*length(a) >= cols_if_complete
                pop!(a)
                break
            end
        end
        if 1 < length(a) < size(X, 2)
            while sum(map(sum, a)) + sep*length(a) >= cols_otherwise
                pop!(a)
            end
        end
        return a
    end
    function Base.alignment(
        X::Union{NullableArray, NullableMatrix},
        rows::AbstractVector, cols::AbstractVector,
        cols_if_complete::Integer, cols_otherwise::Integer, sep::Integer
    )
        a = []
        for j in cols
            l = r = 0
            for i in rows
                if isassigned(X, i, j)
                    if isnull(X, i, j)
                        aij = alignment(NULL)
                    else
                        aij = alignment(values(X, i, j))
                    end
                else
                    aij = undef_ref_alignment
                end
                l = max(l, aij[1])
                r = max(r, aij[2])
            end
            push!(a, (l, r))
            if length(a) > 1 && sum(map(sum,a)) + sep*length(a) >= cols_if_complete
                pop!(a)
                break
            end
        end
        if 1 < length(a) < size(X, 2)
            while sum(map(sum, a)) + sep*length(a) >= cols_otherwise
                pop!(a)
            end
        end
        return a
    end
end
