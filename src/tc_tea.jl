module TcTEA
export decrypt

const SALT_LEN = 2;
const ZERO_LEN = 7;
const FIXED_PADDING_LEN = 1 + SALT_LEN + ZERO_LEN;

function parse_key(key::Vector{UInt8})
    @assert length(key)>=16 "key not valid"
    UInt32[read_u32_be(key,i*4+1) for i in 0:3]
end

const ROUNDS = 0x00000010
const DELTA = 0x9e3779b9
tc_tea_single_round_arithmetic(value::T,sum::T,key1::T,key2::T) where T<:Unsigned=
((value << 4) + key1) ⊻ (value + sum) ⊻ ((value >> 5) + key2)
read_u32_be(x::AbstractVector{UInt8},offset::Integer)=reinterpret(UInt32,Tuple(view(x,offset:offset+3)))|>ntoh
to_u32_be(value::UInt32)=reinterpret(NTuple{4, UInt8}, hton(value))
function ecb_decrypt!(block::AbstractVector{UInt8},k::AbstractVector{UInt32})
    y=read_u32_be(block,1)
    z=read_u32_be(block,5)
    _sum=ROUNDS*DELTA
    for _ in 1:ROUNDS
        z-=tc_tea_single_round_arithmetic(y,_sum,k[3],k[4])
        y-=tc_tea_single_round_arithmetic(z,_sum,k[1],k[2])
        _sum-=DELTA
    end
    block[1:4].=to_u32_be(y)
    block[5:8].=to_u32_be(z)
    block
end
function xor_prev_tea_block!(block::AbstractVector,offset::Int)
    block[offset:offset+7] .⊻= block[offset-8:offset-1]
    block
end
xor_block!(block::AbstractVector{T}, dst_offset::Int, size::Int, src::AbstractVector{T}, src_offset::Int) where T<:Unsigned=
block[dst_offset+1 : dst_offset + size] .⊻= src[src_offset + 1 : src_offset+size]

function decrypt(encrypted::T,key::T;strict::Bool=false) where T<:Vector{UInt8}
    key=parse_key(key)
    len=length(encrypted)
    @assert (len > FIXED_PADDING_LEN) && (len % 8 == 0) "Error key"
    decrypted_buf=copy(encrypted)
    decrypted_buf=ecb_decrypt!(decrypted_buf, key)
    for i in 9:8:len-1
        xor_prev_tea_block!(decrypted_buf,i)
        ecb_decrypt!(view(decrypted_buf,i:i+7), key)
    end
    xor_block!(decrypted_buf,8,len-8,encrypted,0)
    pad_size=decrypted_buf[1]&0b111
    start_loc = 1 + pad_size + SALT_LEN
    end_loc = len - ZERO_LEN
    if strict
        @assert sum(decrypted_buf[end_loc:end])==0 "Key Decryption Error"
    end
    decrypted_buf[start_loc+1:end_loc]
    
end
end