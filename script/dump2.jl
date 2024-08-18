using Pkg
Pkg.activate(".")
using SQLite
using ArgumentProcessor
group = Group(
    "group1",
    flags=[
        Flag("iskeep";outername="keep",abbr="k")
    ],
    opts=[
        Option("input", abbr="i", fmt=" %s",required=true),
        Option("db", abbr="d",default=" player_process_db", fmt=" %s") ,
        Option("outdir", abbr="o", fmt=" %s")
    ])
const input1 = ArgumentProcessor.parse(ARGS, group)
# println(input1)
posthandle(x)=if !input1.iskeep
    rm(x)
end
function decode_delete(x::String,output=nothing)
    ekey=search_ekey(x,db)
    if ekey isa Bool return "no key" end
    res=decode(Val(:safe),x,ekey,output)
    if res isa Exception return res.msg end
        # if !(res isa Bool && res)
            posthandle(x)
        # end
    true
end
function get_ekey(db::String)
    DBInterface.execute(SQLite.DB(db),"SELECT * FROM audio_file_ekey_table")|>Dict
end
trim_basename(db::Dict)=Dict(zip(basename.(keys(db)),values(db)))
function search_ekey(x::String,db=db)
    k=basename(x)
    if haskey(db,k)
        return db[k]
    end
    false
end
using QMCDecoder

const db=get_ekey(input1.db)|>trim_basename
output_name(x::String)=if isnothing(input1.outdir)
    nothing
else
    name,_=splitext(basename(x))
    joinpath(input1.outdir,name)
end

i=input1.input

if isdirpath(i)
    files=readdir(i, join=true)
    for z in files
        println(z)
        res=decode_delete(z,output_name(z))
        if res isa Bool
            res && println("decode success")
        elseif res isa String
            println(res)
        end
    end
elseif isfile(i)
    res=decode_delete(i,output_name(i))
    if res isa Bool
        res && println("decode success")
    elseif res isa String
        println(res)
    end
end



