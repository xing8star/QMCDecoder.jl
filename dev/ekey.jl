const key1,key2=UInt8[0x33, 0x38, 0x36, 0x5a, 0x4a, 0x59, 0x21, 0x40, 0x23, 0x2a, 0x24, 0x25, 0x5e, 0x26, 0x29, 0x28],UInt8[0x2a, 0x2a, 0x23, 0x21, 0x28, 0x23, 0x24, 0x25, 0x26, 0x5e, 0x61, 0x31, 0x63, 0x5a, 0x2c, 0x54]
include("tc_tea.jl")
using Base64

# function make_simple_key(n::Int)
    # result=Vector{UInt8}(undef,n)
    # for i in eachindex(result) 
        # value = 106 + (i-1) * 0.1
        # value = abs(tan(value)) * 100
        # result[i] = floor(value) 
        # result[i] = floor(abs(tan(106 + (i-1) * 0.1)) * 100) 
    # end
#     result
# end
make_simple_key(n::Int)=UInt8[floor(abs(tan(106 + i * 0.1)) * 100) for i in 0:n-1]

function decrypt_v1(ekey)
    ekey=base64decode(ekey)
    header,cipher=ekey[1:8],ekey[9:end]
    # simple_key=make_simple_key(8)
    tea_key=UInt8[]
    foreach(zip(make_simple_key(8),header)) do x
        append!(tea_key,x)
    end
    # plaintext = decrypt(cipher, tea_key)
    vcat(header,decrypt(cipher, tea_key))
end

function decrypt_v2(ekey)
    ekey=base64decode(ekey)
    ekey=decrypt(ekey,key1)
    ekey=decrypt(ekey,key1)
end

# ekey="""bTJaUTMyUXXXxxAgQoRW8J80JUsWXUUjs54faKVRxn4P77Ozm9veIC4G7Mb1iaPvrBOxPxYICSIQbgM4AZ0wHaMb739qjyAADFQzQWuOipF7qhYVIAqxsoMOVvr9apo0NZHhc2kg4zjEWn0Y5WIRgD0i/xlkx/a+Gam5apOBwK9/XdCiQnodPzGz6s/dPAw8BypUBsxYNOwyzzJ5Tsn29Uz5jaFTwjh4xPB4uHJ7tn/x7dnTc2n9mwo5zJmUjBxPy+RR1Low+vi8iFzf5FocRtyCA+NP/KHCZH6QG7y+UdgLmMF3pUJGqZtliDiyJHtXsKKa10+KFMogxWryQ7Nvv3bK4J0Gx+FxxBYmL6ZBuFONLvHVr/xb1xEHq9/fj1lbpRrbj7FqBIX+2bxkcPig2kXWJkpWOS5J37ud0d5/QtaTKZvNsQgpA/6QHeyVjUXJ+LcJmI+VGcyDFuFYNvrYTLaloTo5ANbZUGXo+aWzhqL53JEJwp5sVPxpyhB+nQfFXM7pORg05XmD/yvLuhM4PZg4AsK86/rm7FNZiBUyVRoBwriwBliiKuRElZ562XYS9ljFaVav+nCDVUBpfDTURNJYMizRaqygcpWRMpTlWQlf8yLHr+BRgtyDNSoTT45NF+wbdl7025SXIc/B0zIlSoPrs+HYAPU142shM3fQbxs3/VOophYQUz3a0hRnjuO3"""
# ekey1=base64decode(ekey)
# ekey2=decrypt(ekey1,key1)
# b=ekey2[1][ekey2[3]:end]
# reduce(|,b)
# ekey2=ekey2[1][ekey2[2]+1:ekey2[3]-1]
# ekey=decrypt(ekey2,key2)
# ek=base64decode(String(ekey))

# decrypt_v1(ekey)

# a=[[1,2],[3,4]]
# b=collect(a...)
# convert(Vector{Int},a)
# reshape(a,:)
# vec(a)