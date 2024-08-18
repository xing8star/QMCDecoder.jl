module QMCDecoder
export QQMusicV2,
decode,
isqmc
using SafeThrow
include("qmc2_rc4.jl")
struct QQMusicV2
    filenamepath::String
    ekey::String
    decipher::QMCv2RC4
    valid_file_size::Int
    io::IO
end
function isqmc(file_path::AbstractString)::Bool
    open(file_path) do io
        seekend(io);skip(io,-4)
        read(io)==b"STag"
    end
end
@add_safefunction function QQMusicV2(file_path::AbstractString,ekey::AbstractString)
    f=open(file_path)
    seekend(f);skip(f,-4)
    max_read=position(f)
    header=read(f)
    close(f)
    header==b"STag" || throw(ErrorException("Not is a STag file."))
    file_upper_path,_=splitext(file_path)
    QQMusicV2(file_upper_path,ekey,QMCv2RC4(ekey),max_read,open(file_path))
end


function decode(x::QQMusicV2,out::IO=IOBuffer())
    io=x.io;s=x.decipher;
    # buffer_len=OTHER_SEGMENT_SIZE
    write(out,encode_first_segment!(read(io,INITIAL_SEGMENT_SIZE),s,0))
    offset=INITIAL_SEGMENT_SIZE
    write(out,encode_other_segment(read(io,OTHER_SEGMENT_SIZE - offset),s,offset))
    offset=OTHER_SEGMENT_SIZE
    while !eof(io)
        block=read(io,OTHER_SEGMENT_SIZE)
        read_len=length(block)
        write(out,encode_other_segment(block,s,offset))
        offset+=read_len
    end
    out
end
function decode(x::QQMusicV2,max_read::Integer,out::IO=IOBuffer())
    io=x.io;s=x.decipher;
    # buffer_len=OTHER_SEGMENT_SIZE
    bytes_processed=0
    write(out,encode_first_segment!(read(io,INITIAL_SEGMENT_SIZE),s,0))
    offset=INITIAL_SEGMENT_SIZE
    write(out,encode_other_segment(read(io,OTHER_SEGMENT_SIZE - offset),s,offset))
    offset=OTHER_SEGMENT_SIZE
    bytes_processed+=INITIAL_SEGMENT_SIZE+OTHER_SEGMENT_SIZE
    while !eof(io)
        block_len=min(max_read-bytes_processed,OTHER_SEGMENT_SIZE)
        if block_len==0 break end
        block=read(io,block_len)
        read_len=length(block)
        write(out,encode_other_segment(block,s,offset))
        offset+=read_len
        bytes_processed+=read_len
    end
    out
end
@add_safefunction function decode(x::String,ekey::AbstractString,outname::Union{Nothing,String}=nothing)
    isqmc(x) || throw(ErrorException("Not is a STag file."))
    music=QQMusicV2(x,ekey)
    file_name = if isnothing(outname) 
        music.filenamepath * "t.flac"
    else
        outname * ".flac"
    end
    io = open(file_name, "w")
    decode(music,music.valid_file_size,io)
    close(io)
end
end # module QMCDecoder
