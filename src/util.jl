splitat(x::AbstractVector,idx)=x[1:idx],x[idx+1:end]
splitat_view(x::AbstractVector,idx)=@views x[1:idx],x[idx+1:end]
function swap_offset_plusone!(s::AbstractVector,i,j)
    s[[i+1,j+1]]=s[[j+1,i+1]]
end