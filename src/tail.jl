struct AndroidSTagMetadata
    # Size of the payload to trim off the end of the file.
    tail_len::Int
    # Should always be `2`.
    tag_version::UInt32
    # Resource identifier (aka. `file.media_mid`).
    media_mid::String
    # Numeric id.
    media_numeric_id::UInt64
end
function get_tail_len(io::IO,::Type{AndroidSTagMetadata})
    seekend(io);skip(io,-8)
    ntoh(read(io,UInt32))+8
end
function Base.read(s::IO,::Type{AndroidSTagMetadata})
    seekend(s);skip(s,-4)
    read(s)==b"STag" || throw(ErrorException("Error read STag."))
    skip(s,-8)
    tail_len=ntoh(read(s,UInt32))
    skip(s,-4-tail_len)
    media_numeric_id=parse(Int,String(readuntil(s,0x2c)))
    tag_version=parse(UInt32,String(readuntil(s,0x2c)))
    media_mid=String(readuntil(s,0x00))
    AndroidSTagMetadata(tail_len,tag_version,media_mid,media_numeric_id)
end