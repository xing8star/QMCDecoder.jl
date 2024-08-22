# const key1,key2=UInt8[0x33, 0x38, 0x36, 0x5a, 0x4a, 0x59, 0x21, 0x40, 0x23, 0x2a, 0x24, 0x25, 0x5e, 0x26, 0x29, 0x28],UInt8[0x2a, 0x2a, 0x23, 0x21, 0x28, 0x23, 0x24, 0x25, 0x26, 0x5e, 0x61, 0x31, 0x63, 0x5a, 0x2c, 0x54]
include("tc_tea.jl")
using Base64
using .TcTEA
make_simple_key(n::Int)=UInt8[floor(abs(tan(106 + i * 0.1)) * 100) for i in 0:n-1]

function decrypt_v1(ekey)
    ekey=base64decode(ekey)
    header,cipher=ekey[1:8],ekey[9:end]
    tea_key=zeros(UInt8,16)
    tea_key[1:2:16]=make_simple_key(8)
    tea_key[2:2:16]=header
    vcat(header,decrypt(cipher, tea_key))
end

# function decrypt_v2(ekey)
#     ekey=base64decode(ekey)
#     ekey=decrypt(ekey,key1)
#     ekey=decrypt(ekey,key1)
# end
