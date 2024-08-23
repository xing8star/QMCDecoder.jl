const INITIAL_SEGMENT_SIZE = 0x80
const OTHER_SEGMENT_SIZE = 0x1400
const KEY_STREAM_LEN = 0x1FF + OTHER_SEGMENT_SIZE
# const DECRYPTION_BUFFER_SIZE = 2 * 1024 * 1024
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
        hash=_next
   end
   hash
end

function get_segment_key(key_hash::UInt32,id::Integer,seed::UInt8)
    iszero(seed)&&return 0
    Float64(key_hash)/Float64(seed*(id+1))*100.0 |> floor |> Int
end
QMCv2RC4(key::Vector{UInt8})=QMCv2RC4(key,calc_key_hash(key),rc4(key)(KEY_STREAM_LEN))
QMCv2RC4(ekey::String)=QMCv2RC4(decrypt_v1(ekey))
function encode_first_segment!(buffer::AbstractVector{UInt8},s::QMCv2RC4,offset::Integer)
    key_len=length(s.key)
    key_hash=s.key_hash
    key=s.key
    for i in eachindex(buffer)
        buffer[i]⊻=s.key[get_segment_key(key_hash,offset,key[offset%key_len+1])%key_len+1]
        offset+=1
    end
    buffer
end

function encode_other_segment!(buffer::AbstractVector{UInt8},s::QMCv2RC4,offset::Integer)
    key_len=length(s.key);key_hash=s.key_hash;key=s.key
    segment_idx = fld(offset,OTHER_SEGMENT_SIZE)
    segment_offset = offset % OTHER_SEGMENT_SIZE
    segment_key=get_segment_key(key_hash,segment_idx,key[(segment_idx%key_len)+1])
    skip_len=segment_key&0x1FF
    _len=min(length(buffer),OTHER_SEGMENT_SIZE-segment_offset)
    buffer[begin:_len].⊻=@view s.key_stream[skip_len+segment_offset+1:end][1:_len]
end

function decipher_buffer!(buffer::Vector{UInt8},s::QMCv2RC4,offset::Integer)
    if offset<INITIAL_SEGMENT_SIZE
        _len=min(length(buffer),INITIAL_SEGMENT_SIZE-offset)
        segment, rest=splitat_view(buffer,_len)
        encode_first_segment!(segment,s,offset)
        offset+=INITIAL_SEGMENT_SIZE
        buffer=rest
    end
    if (offset % OTHER_SEGMENT_SIZE) != 0 
        _len = OTHER_SEGMENT_SIZE - (offset % OTHER_SEGMENT_SIZE);
        _len = min(length(buffer), _len);
        segment, rest=splitat_view(buffer,_len)
        encode_other_segment!(segment,s,offset)
        offset += _len;
        buffer = rest;
    end
    for _ in 1:OTHER_SEGMENT_SIZE:length(buffer)
        _len = min(OTHER_SEGMENT_SIZE,length(buffer));
        segment, rest=splitat_view(buffer,_len)
        encode_other_segment!(segment,s,offset)
        offset += _len;
        buffer = rest;
    end
    nothing
end

function decrypt_stright(io::IO,out_stream::IO,s::QMCv2RC4)
    # buffer_len=OTHER_SEGMENT_SIZE
    # bytes_processed=0
    write(out_stream,encode_first_segment!(read(io,INITIAL_SEGMENT_SIZE),s,0))
    offset=INITIAL_SEGMENT_SIZE
    write(out_stream,encode_other_segment!(read(io,OTHER_SEGMENT_SIZE - offset),s,offset))
    offset=OTHER_SEGMENT_SIZE
    # bytes_processed+=INITIAL_SEGMENT_SIZE+OTHER_SEGMENT_SIZE
    while !eof(io)
        # block_len=min(max_read-bytes_processed,buffer_len)
        block=read(io,OTHER_SEGMENT_SIZE)
        read_len=length(block)
        write(out_stream,encode_other_segment!(block,s,offset))
        offset+=read_len
        # bytes_processed+=read_len
    end
end

