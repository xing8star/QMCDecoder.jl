# using Pkg
# Pkg.activate(".")
# using ArgumentProcessor
# group = Group(
#     "group1",
#     flags=[
#         Flag("iskeep";outername="keep",abbr="k")
#     ],
#     opts=[
#         Option("input", abbr="i", fmt=" %s",required=true),
#         Option("output", abbr="o", fmt=" \"%s\"") ,
#         Option("ekey", abbr="e", fmt=" %s",required=true)
#     ])
println(ARGS)
# const input1 = ArgumentProcessor.parse(ARGS, group)
# posthandle(x)=if !input1.iskeep
#     rm(x)
# end
using QMCDecoder
# i=input1.input
# if isfile(i)
# println(i)
# decode(Val(:safe),x,input1.ekey,input1.output)
# posthandle(i)
# end

i=ARGS[1]
ekey=ARGS[2]
output=if length(ARGS)>=3
    ARGS[3]
else
    nothing end
if isfile(i)
println(i)
decode(Val(:safe),i,ekey,output)
# posthandle(i)

end