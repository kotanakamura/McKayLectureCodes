include("AiyagariEGM.jl")
K0 = 48.0 

########################EGM
AA0,pol0,Aggs0 = AiyagariEGM(K0)

#interpEGM(polA_ss[1:201],AA0.aGrid,1.0,201)
polA_ss,polC_ss,D_ss,K_ss,Aggs_ss = equilibriumEGM(pol0,AA0,K0)

#### If doesn't want to actually compute the SS equilibrium
#polA_ss = readdlm("pol_ss.csv")
#D_ss = readdlm("dis_ss.csv")
#K_ss = dot(D_ss,AA0.aGridl)

exoshocks = [0.0]
xss = vcat(polA_ss,D_ss[2:end],K_ss,1.0)
roots = FEGM(xss,xss,xss,exoshocks,AA0,1)

Am = ForwardDiff.jacobian(t -> FEGM(xss,xss,t,exoshocks,AA0,3),xss)
Bm = ForwardDiff.jacobian(t -> FEGM(xss,t,xss,exoshocks,AA0,2),xss)
Cm = ForwardDiff.jacobian(t -> FEGM(t,xss,xss,exoshocks,AA0,1),xss)
Em = ForwardDiff.jacobian(t -> FEGM(xss,xss,xss,t,AA0,1),exoshocks)

###both SIMs and Rendhal's algorithm working. Sims' faster
#PP,QQ = SolveSystem(Am,Bm,Cm,Em)
G,H,E,EE = TurnABCEtoSims(Am,Bm,Cm,Em)
eu,G1,Impact = SolveQZ(G,H,E,EE)


##################### error analysis
fineGrid = collect(range(AA0.aGrid[1],stop = AA0.aGrid[end],length = 10000))
fineGridzero = fill(0.0, AA0.ns*10000)
cMat = fill(0.0,(AA0.na*AA0.ns,))
aMat = fill(0.0,(AA0.na*AA0.ns,))
pol = SolveEGM(pol0,Aggs0,AA0,cMat,aMat)
egmerr = EulerResidualError(pol,pol,Aggs0,Aggs0,AA0,fineGridzero,fineGridzero,vcat(fineGrid,fineGrid))
egmerrm = reshape(egmerr,length(fineGrid),AA0.ns)
@show sum(abs.(egmerrm[:,1]))
@show sum(abs.(egmerrm[:,2]))
p1 = plot(fineGrid,log10.(abs.(egmerrm[:,1])),title="low prod EGM error")
p2 = plot(fineGrid,log10.(abs.(egmerrm[:,2])),title="high prod EGM error")
p = plot(p1,p2,layout=(1,2),legend=false)
savefig(p,"ErrorEGM.pdf")


############### Comparing with complete representative agent economy
Time = 200
IRFaZ = fill(0.0,(size(G1,1),Time))
IRFaZ[:,1] = Impact[:,1]
for t =2:Time
    IRFaZ[:,t] = G1*IRFaZ[:,t-1]
end

include("RBC.jl")

p1 = plot(IRFaZ[end-2,:],title="K",label="Aiyagari",titlefont=font(7, "Courier"))
p1 = plot!(IRFrbcZ[3,:],title="K",label="RBC",titlefont=font(7, "Courier"))
p2 = plot(IRFaZ[end-1,:],title="Z",label="Aiyagari",titlefont=font(7, "Courier"))
p2 = plot!(IRFrbcZ[1,:],title="Z",label="RBC",titlefont=font(7, "Courier"))
p = plot(p1,p2, layout=(1,2))
savefig(p,"irfEGM.pdf")


















