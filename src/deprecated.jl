using Base: @deprecate

@deprecate anynull(x) any(isnull, x)
@deprecate allnull(x) all(isnull, x)
