using QMCDecoder
i=ARGS[1]
ekey=ARGS[2]
output=if length(ARGS)>=3
    ARGS[3]
else
    nothing end
if isfile(i)
println(i)
decode(Val(:safe),i,ekey,output)
end