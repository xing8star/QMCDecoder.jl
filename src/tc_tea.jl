module TcTEA
export decrypt

const SALT_LEN = 2;
const ZERO_LEN = 7;
const FIXED_PADDING_LEN = 1 + SALT_LEN + ZERO_LEN;

function parse_key(key::Vector{UInt8})
    @assert length(key)>=16 "key not valid"
    io=IOBuffer(key)
    UInt32[ntoh(read(io,UInt32)) for _ in 1:4]
end

const ROUNDS = 0x00000010
const DELTA = 0x9e3779b9
tc_tea_single_round_arithmetic(value::T,sum::T,key1::T,key2::T) where T<:Unsigned=
((value << 4) + key1) ⊻ (value + sum) ⊻ ((value >> 5) + key2)

function ecb_decrypt(block::Vector{UInt8},k::Vector{UInt32})
    io=IOBuffer(block,read=true,write=true)
    y=ntoh(read(io,UInt32))
    z=ntoh(read(io,UInt32))
    _sum=ROUNDS*DELTA
    for _ in 1:ROUNDS
        z-=tc_tea_single_round_arithmetic(y,_sum,k[3],k[4])
        y-=tc_tea_single_round_arithmetic(z,_sum,k[1],k[2])
        _sum-=DELTA
    end
    seekstart(io)
    write(io,hton(y))
    write(io,hton(z))
    io.data
end
function xor_prev_tea_block!(block::Vector,offset::Int)
    block[offset:offset+7] .⊻= block[offset-8:offset-1]
    block
end
xor_block!(block::Vector{T}, dst_offset::Int, size::Int, src::Vector{T}, src_offset::Int) where T<:Unsigned=
block[dst_offset+1 : dst_offset + size] .⊻= src[src_offset + 1 : src_offset+size]

function decrypt(encrypted::T,key::T;strict::Bool=false) where T<:Vector{UInt8}
    key=parse_key(key)
    len=length(encrypted)
    @assert (len > FIXED_PADDING_LEN) && (len % 8 == 0) "Error key"
    decrypted_buf=copy(encrypted)
    decrypted_buf=ecb_decrypt(decrypted_buf, key)
    for i in 9:8:len-1
        xor_prev_tea_block!(decrypted_buf,i)
        decrypted_buf[i:i+7]=ecb_decrypt(decrypted_buf[i:i+7], key)
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