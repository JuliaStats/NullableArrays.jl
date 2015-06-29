#
# Calculates the SVD of a NullableMatrix containing missing entries.
#
# Uses the iterative algorithm of Hastie et al. 1999
#

# Impute a missing entries using current (w/r/t the iterative algorithm)
# approximation.
function impute!(X::Matrix, missing_entries::Vector,
                 U::Matrix, D::Vector, V::Matrix,
                 k::Integer)
    approximation = U[:, 1:k] * diagm(D[1:k]) * V[1:k, :]
    for indices in missing_entries
        X[indices[1], indices[2]] = approximation[indices[1], indices[2]]
    end
end

@generated function global_mean{T, N}(X::NullableArray{T, N})
    return quote
        mu = 0.0
        n = 0
        @nloops $N i X begin
            if (@nref $N X i).isnull
                mu += (@nref $N X i).value
                n += 1
            end
        end
        return mu / n
    end
end

function nullsafe_rowmeans(M::NullableMatrix)
    n, p = size(M)
    mus = NullableArray(Float64, n)
    for i = 1:n
        mu = 0.0
        n = 0
        for j = 1:p
            if !M.isnull[i, j]
                mu += M.values[i, j]
                n += 1
            end
        end
        if n != 0
            mus[i] = mu / n
        end
    end
    return mus
end

function Base.svd(M::NullableMatrix,
                  k::Int;
                  impute = false,
                  tracing = false,
                  tolerance = 10e-4)
    if anynull(M)
        msg = "to impute null entries, call with 'impute=true'"
        !impute && throw(ArgumentError(msg))
    end
    _M = copy(M)
    n, p = size(_M)

    # Report missingness estimate if tracing = true
    null_entries = findnull(_M)
    missingness = length(null_entries) / (n * p)
    if tracing
        @printf "Matrix is missing %.2f%% of entries \n" missingness * 100
    end

    # Initial imputation uses global mean and row means
    global_mu = global_mean(_M)
    mu_i = nullsafe_rowmeans(_M)
    for i = 1:n
        for j = 1:p
            if _M[i, j].isnull
                if mu_i[i].isnull
                    _M[i, j] = global_mu
                else
                    _M[i, j] = mu_i[i]
                end
            end
        end
    end

    # Convert dm to a Float array now that we've removed all NA's
    _M = convert(Matrix{Float64}, _M)

    # Count iterations of proper imputation method
    itr = 0

    # Keep track of approximate matrices
    previous_M = copy(_M)
    current_M = copy(_M)

    # Keep track of Frobenius norm of changes in imputed matrix
    change = Inf

    # Iterate until imputation stops changing up to chosen tolerance
    while change > tolerance
        if tracing
            @printf "Iteration %d\nChange %f\n" itr change
        end

        # Impute missing entries using current SVD
        previous_M = copy(current_M)
        U, D, V = svd(current_M)
        impute!(current_M, null_entries, U, D, V', k)

        # Compute the change in the matrix across iterations
        change = norm(previous_M - current_M) / norm(_M)

        # Increment the iteration counter
        itr = itr + 1
    end

    # Tell the user how many iterations were required to impute matrix
    if tracing
        @printf "Tolerance achieved after %d iterations" itr
    end

    # Return the rank-k SVD entries
    U, D, V = svd(current_M)

    # Only return the SVD entries, not the imputation
    return (U[:, 1:k], D[1:k], V[:, 1:k])
end

function Base.svd(M::NullableMatrix; impute = false)
    if anynull(M)
        msg = "to impute null entries, call with 'impute=true'"
        !impute && throw(ArgumentError(msg))
    end
    return svd(M, minimum(size(M)), impute = impute)
end

function Base.eig(M::NullableMatrix; impute = false)
    if anynull(M)
        msg = "to impute null entries, call with 'impute=true'"
        !impute && throw(ArgumentError(msg))
    end
    U, D, V = svd(M, impute=impute)
    return eig(U * diagm(D) * V')
end
