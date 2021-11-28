"""
    resize(view, len)

Returns a view to the parent of `view` with the length `len`, starting from the initial point of `view`.
"""
resize(v::SubArray{T, 1}, len) where T = return @view v.parent[v.offset1 .+ 1:len]
