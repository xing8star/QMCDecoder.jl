splitat(x::Vector,idx)=x[1:idx],x[idx+1:end]
function swap_offset_plusone!(s::Vector,i,j)
    s[[i+1,j+1]]=s[[j+1,i+1]]
end