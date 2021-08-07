# Load Julia packages (libraries)

using Pkg, DrWatson

using StanSample

df = CSV.read(joinpath(@__DIR__, "..", "..", "data", "chimpanzees.csv"), DataFrame);

# Define the Stan language model

stan10_4 = "
data{
    int N;
    int N_actors;
    int pulled_left[N];
    int prosoc_left[N];
    int condition[N];
    int actor[N];
}
parameters{
    vector[N_actors] a;
    real bp;
    real bpC;
}
model{
    vector[N] p;
    bpC ~ normal( 0 , 10 );
    bp ~ normal( 0 , 10 );
    a ~ normal( 0 , 10 );
    for ( i in 1:504 ) {
        p[i] = a[actor[i]] + (bp + bpC * condition[i]) * prosoc_left[i];
        p[i] = inv_logit(p[i]);
    }
    pulled_left ~ binomial( 1 , p );
}
";

data = (N = size(df, 1), N_actors = length(unique(df.actor)), 
    actor = df.actor, pulled_left = df.pulled_left,
    prosoc_left = df.prosoc_left, condition = df.condition);

# Sample using cmdstan

m10_4s = SampleModel("m10.4s", stan10_4)
rc10_4s = stan_sample(m10_4s; data);

if success(rc10_4s)
    chns = read_samples(m10_4s)

    # Display the chns

    chns |> display
    println()

    # Display the keys

    axiskeys(chns) |> display
    println()

    axiskeys(chns, :param) |> display
    println()

    chns(chain=1) |> display
    println()

    chns[:, 1, 8] |> display
    println()

    chns(chain=1, param=:bp) |> display
    println()

    chns(chain=[1, 3], param=[:bp, :bpC]) |> display
    println()

    # Select all elements starting with 'a'

    chns_a = matrix(chns, :a)
    chns_a |> display
    println()

    mean(chns_a, dims=1) |> display
    println()

    typeof(chns_a.data) |> display
    println()

    ndraws_a, nchains_a, nparams_a = size(chns_a)
    chn_a = reshape(chns_a, ndraws_a*nchains_a, nparams_a)
    println()

    for row in eachrow(chn_a)
        # ...
    end

    # Or use read_samples to only use chains 2 and 4 using the chains kwarg.

    chns2 = read_samples(m10_4s; chains=[2, 4])
    chns2_a = matrix(chns2, :a)
    ndraws2_a, nchains2_a, nparams2_a = size(chns2_a)
    chn2_a = reshape(chns2_a, ndraws2_a*nchains2_a, nparams2_a)
    mean(chns2_a, dims=1) |> display

end
