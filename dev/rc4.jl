include("util.jl")
mutable struct RC4
    const state::Vector{UInt8}
    i::Int
    j::Int
    RC4(key::Vector{UInt8})=new(init_state(key),0,0)
end

function init_state(key::Vector{UInt8})
    n=length(key)
    state=(0:n-1).%UInt8
    j=0
    for i in 0:n-1
        j=(j+state[i+1])+key[i%n+1]%n
        state[[i+1,j+1]]=state[[j+1,i+1]]
    end
    state
end

getindex(s::RC4,idx::Int)=s.state[idx]
function next(s::RC4)
    n=length(s.state)
    s.i=(s.i+1)%n
    s.j=(s.j+s[s.i+1])%n
    i,j=s.i,s.j
    final_idx=(s[i+1]+s[j+1])%n
    swap_offsetone(s.state,i,j)
    s[final_idx+1]
end
function get_key_stream(s::RC4,n::Int)
    [next(s) for _ in 1:n]
end


# test 
# key_stream = rc4(b"this is a test key")(11)
# data = b"hello world"
# result=Vector{UInt8}(undef,11)
# i=0
# for (p, key) in zip(data,key_stream)
#     result[i+=1] = p ⊻ key
# end
# b"\x68\x75\x6b\x64\x64\x24\x7f\x60\x7c\x7d\x60"
# result