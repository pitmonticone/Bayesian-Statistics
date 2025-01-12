using Turing
using CSV
using DataFrames
using StatsBase
using LinearAlgebra

# reproducibility
using Random: seed!

seed!(123)

# load data
df = CSV.read("datasets/sparse_regression.csv", DataFrame)

# define data matrix X and standardize
X = select(df, Not(:y)) |> Matrix |> float
X = standardize(ZScoreTransform, X; dims=1)

# define dependent variable y and standardize
y = df[:, :y] |> float
y = standardize(ZScoreTransform, y; dims=1)

# define the model
@model function sparse_horseshoe_p_regression(X, y; predictors=size(X, 2))
    # priors
    α ~ TDist(3) * 2.5
    λ ~ filldist(truncated(Cauchy(0, 1); lower=0), predictors)
    τ ~ truncated(Cauchy(0, 1 / predictors); lower=0)
    η ~ truncated(Cauchy(0, 1); lower=0)
    σ ~ Exponential(1)

    β ~ MvNormal(Diagonal(((η * τ) .* λ) .^ 2))

    # likelihood
    y ~ MvNormal(α .+ X * β, σ^2 * I)
    return (; y, α, λ, τ, η, σ, β)
end

# instantiate the model
model = sparse_horseshoe_p_regression(X, y)

# sample with NUTS, 4 multi-threaded parallel chains, and 2k iters with 1k warmup
chn = sample(model, NUTS(1_000, 0.8), MCMCThreads(), 1_000, 4)
println(DataFrame(summarystats(chn)))

# results:
#  parameters      mean       std      mcse   ess_bulk   ess_tail      rhat   ess_per_sec
#      Symbol   Float64   Float64   Float64    Float64    Float64   Float64       Float64
#
#           α   -0.0002    0.0323    0.0030   118.1721   278.9664    1.0243        0.1621
#        λ[1]    6.0579   10.0663    3.0204    11.4497    16.7640    1.6951        0.0157
#        λ[2]   -0.0932    1.4153    0.3142    19.2305   113.7813    1.2594        0.0264
#        λ[3]   -2.1663    4.1320    1.2938    13.3036    38.5615    1.6035        0.0182
#        λ[4]   -0.0910    2.0557    0.4913    18.0305    33.4431    1.3416        0.0247
#        λ[5]   -2.1000    5.6797    1.7336    12.2582    22.8753    1.7188        0.0168
#        λ[6]    4.1577    2.6026    0.3537    70.9042    71.3911    1.0716        0.0972
#        λ[7]   -0.0265    1.7567    0.4542    14.3379    53.9656    1.4495        0.0197
#        λ[8]   -1.2036    2.7373    0.8406    13.6670    66.2890    1.5591        0.0187
#        λ[9]   -0.4556    1.5960    0.3653    16.0928    83.1542    1.3777        0.0221
#       λ[10]   -0.0798    1.7582    0.4172    14.8505    94.2973    1.4384        0.0204
#       λ[11]    1.3065    2.5436    0.7263    11.9299    25.9705    1.6909        0.0164
#       λ[12]   -0.1817    1.9640    0.3500    24.6331   171.4874    1.1679        0.0338
#       λ[13]   -0.1405    1.9775    0.4119    20.3797    72.7982    1.2415        0.0280
#       λ[14]   -3.5763    5.9160    1.8301    12.9173    70.7797    1.6019        0.0177
#       λ[15]   -0.9324    1.6119    0.4098    14.5331    44.1432    1.4755        0.0199
#       λ[16]    0.5214    1.9429    0.4558    16.4813    27.3755    1.3681        0.0226
#       λ[17]    0.6175    1.4098    0.2924    23.2504    39.4808    1.2017        0.0319
#       λ[18]    0.2180    1.6932    0.4328    13.5904    58.7350    1.5340        0.0186
#       λ[19]   -0.1591    1.4039    0.3444    16.1316    33.6346    1.3759        0.0221
#       λ[20]   -2.6696    4.3510    1.3857    13.3690    55.2658    1.6173        0.0183
#           τ    0.0629    0.0533    0.0058    54.2184   109.9163    1.1076        0.0744
#           η    1.5893    1.1604    0.1441    46.6923   142.6147    1.1152        0.0640
#           σ    0.3277    0.0267    0.0032    81.0144   157.5050    1.0326        0.1111
#        β[1]    0.4926    0.0360    0.0044    69.2672    97.7435    1.0376        0.0950
#        β[2]    0.0073    0.0258    0.0047    30.1671   167.0479    1.1761        0.0414
#        β[3]    0.2565    0.0379    0.0041    89.2120   239.9928    1.0207        0.1224
#        β[4]    0.0147    0.0305    0.0037    78.0556   139.8530    1.0337        0.1071
#        β[5]   -0.2802    0.0328    0.0027   147.2640   257.6856    1.0237        0.2020
#        β[6]    0.2099    0.0343    0.0036    90.6120   157.6924    1.0392        0.1243
#        β[7]    0.0219    0.0276    0.0025   127.7747   191.9369    1.0125        0.1752
#        β[8]    0.1323    0.0327    0.0026   153.7350   364.8132    1.0359        0.2109
#        β[9]   -0.0008    0.0276    0.0027   108.0584   166.8649    1.0372        0.1482
#       β[10]    0.0214    0.0295    0.0030   102.5774   145.1183    1.0140        0.1407
#       β[11]    0.0643    0.0369    0.0049    56.9598   238.9494    1.0615        0.0781
#       β[12]   -0.0130    0.0267    0.0023   137.9953   260.4812    1.0264        0.1893
#       β[13]   -0.0118    0.0240    0.0021   125.8721   236.2345    1.0301        0.1726
#       β[14]   -0.4283    0.0365    0.0040    87.5668    59.6759    1.0415        0.1201
#       β[15]   -0.0220    0.0296    0.0029   104.5022   314.5114    1.0348        0.1433
#       β[16]   -0.0033    0.0260    0.0025   104.9021   171.2699    1.0245        0.1439
#       β[17]   -0.0020    0.0275    0.0030    83.8294   175.2058    1.0545        0.1150
#       β[18]    0.0070    0.0268    0.0027   106.2810   142.6289    1.0446        0.1458
#       β[19]    0.0015    0.0284    0.0035    64.7765    88.3422    1.0586        0.0888
#       β[20]   -0.3416    0.0367    0.0051    52.7042   136.4280    1.0851        0.0723
