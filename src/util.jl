"""
    resize(view, len)

Returns a view to the parent of `view` with the length `len`, starting from the initial point of `view`.
"""
function resize(v::SubArray{T, 1}, len) where T
    idxs = v.offset1 .+ (1:len)
    return @view v.parent[idxs]
end
