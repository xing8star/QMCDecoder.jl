
function init_state(key::AbstractVector{UInt8})
    n=length(key)
    state=(0:n-1).&0xff
    j=0
    for i in 0:n-1
        j=(j+state[i+1]+key[i%n+1])%n
        swap_offset_plusone!(state,i,j)
    end
    state
end

function rc4(key::AbstractVector{UInt8})
    state=init_state(key)
    i,j=zeros(Int,2)
    n=length(state)
    function next()
        i=(i+1)%n
        j=(j+state[i+1])%n
        final_idx=(state[i+1]+state[j+1])%n
        swap_offset_plusone!(state,i,j)
        state[final_idx+1]
    end
    (n::Integer)->UInt8[next() for _ in 1:n]
end
