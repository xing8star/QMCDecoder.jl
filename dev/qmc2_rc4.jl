const INITIAL_SEGMENT_SIZE = 0x80
const OTHER_SEGMENT_SIZE = 0x1400
const KEY_STREAM_LEN = 0x1FF + OTHER_SEGMENT_SIZE
const DECRYPTION_BUFFER_SIZE = 2 * 1024 * 1024
include("util.jl")
include("rc4.jl")
include("ekey.jl")
struct QMCv2RC4
    key::Vector{UInt8}
    key_hash::UInt32
    key_stream::Vector{UInt8}
end
function calc_key_hash(key::Vector{UInt8})
   hash=UInt32(1)
   for i in filter(!iszero,key)
        _next=hash*i
        if _next<=hash break end
   end
   hash
end

function get_segment_key(key_hash::UInt32,id::Int,seed)
    iszero(seed)&&return 0
    key_hash/(seed*(id+1))*100
end
QMCv2RC4(key::Vector{UInt8})=QMCv2RC4(key,calc_key_hash(key),get_key_stream(RC4(key),KEY_STREAM_LEN))
QMCv2RC4(ekey::String)=QMCv2RC4(decrypt_v1(ekey))
function encode_first_segment!(buffer::Vector{UInt8},s::QMCv2RC4,offset::Int)
    key_len=length(s.key)
    key_hash=s.key_hash
    key=s.key
    for i in eachindex(buffer)
        buffer[i]⊻=s.key[get_segment_key(key_hash,offset,key[offset%key_len+1])%key_len+1]
        offset+=1
    end
    buffer
end

function encode_other_segment(buffer::Vector{UInt8},s::QMCv2RC4,offset::Int)
    key_len=length(s.key)
    key_hash=s.key_hash
    key=s.key
    segment_idx = cld(offset,OTHER_SEGMENT_SIZE)
    segment_offset = offset % OTHER_SEGMENT_SIZE
    segment_key=get_segment_key(key_hash,segment_idx,key[segment_idx%key_len+1])
    skip_len=segment_key&0x1FF
    _len=min(length(buffer),OTHER_SEGMENT_SIZE-segment_offset)
    # buffer=buffer[begin:_len]
    key_stream=s.key_stream[skip_len+segment_offset+1:end]
    buffer[begin:_len].⊻key_stream[1:_len]

     # i=0
    # for (item, _key) in zip(buffer,key_stream)
    #     result[i+=1]=item⊻_key
    # end
    # result

end

function decipher_buffer(buffer::Vector{UInt8},s::QMCv2RC4,offset::Int)
    io=IOBuffer()
    if offset<INITIAL_SEGMENT_SIZE
        _len=min(length(buffer),INITIAL_SEGMENT_SIZE-offset)
        segment, rest=splitat(buffer,_len)
        write(io,encode_first_segment!(segment,s,offset))
        offset+=_len
        buffer=rest
    end
    if (offset % OTHER_SEGMENT_SIZE) != 0 
        _len = OTHER_SEGMENT_SIZE - (offset % OTHER_SEGMENT_SIZE);
        _len = min(length(buffer), _len);
        segment, rest=splitat(buffer,_len)
        write(io,encode_other_segment(segment,s,offset))
        offset += _len;
        buffer = rest;
    end
    for i in 1:OTHER_SEGMENT_SIZE:length(buffer)
        _len = min(i+OTHER_SEGMENT_SIZE-1,length(buffer));
        segment=buffer[i:_len]
        write(io,encode_other_segment(segment,s,offset))
        offset += _len;
    end
    io
end

# function decrypt(write_callback::Function,io,offset,max_read,buffer_len)
#     bytes_processed=0
#     while !eof(io)
#         block_len=min(max_read-bytes_processed,buffer_len)
#         block=read(io,block_len)
#         read_len=length(block)
#         block=decipher_buffer(block,offset)
#         write_callback(block)
#         offset+=read_len
#         bytes_processed+=read_len
#     end
# end
function decrypt_stright(io::IO,out_stream::IO,s::QMCv2RC4)
    offset=0
    buffer_len=OTHER_SEGMENT_SIZE
    # bytes_processed=0
    write(out_stream,encode_first_segment!(read(io,INITIAL_SEGMENT_SIZE),s,offset))
    # bytes_processed+=INITIAL_SEGMENT_SIZE
    offset+=INITIAL_SEGMENT_SIZE
    while !eof(io)
        # block_len=min(max_read-bytes_processed,buffer_len)
        block=read(io,buffer_len)
        read_len=length(block)
        write(out_stream,encode_other_segment(read(io,OTHER_SEGMENT_SIZE),s,offset))
        offset+=read_len
        # bytes_processed+=read_len
    end
end


# test
# tes_key=QMCv2RC4(b"this is a test key" .|>UInt8)
# get_segment_key(tes_key.key_hash,1,2)
# tes_key.key_stream