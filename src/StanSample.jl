"""
Helper infrastructure to compile and sample models using `cmdstan`.

[`StanModel`](@ref) wraps a model definition (source code), while [`stan_sample`](@ref) can
be used to sample from it.

[`stan_compile`](@ref) can be used to pre-compile a model without sampling. A
[`StanModelError`](@ref) is thrown if this fails, which contains the error messages from
`stanc`.
"""
module StanSample

using Unicode, DelimitedFiles, Distributed
using DocStringExtensions: FIELDS, SIGNATURES, TYPEDEF
using StanDump
using StanSamples
using StanRun

import StanRun: stan_cmd_and_paths, stan_sample

include("read_stanrun_samples.jl")

export StanModel, StanModelError, stan_sample, stan_compile,
  read_samples, read_stanrun_samples

"""
$(SIGNATURES)

Make a Stan command. Internal, not exported.
"""
function stan_cmd_and_paths(exec_path::AbstractString,
                            output_base::AbstractString, id::Integer)
    #println("Using StanSample version of stan_cmd_and_paths.\n")
    sample_file = StanRun.sample_file_path(output_base, id)
    log_file = StanRun.log_file_path(output_base, id)
    data_file = data_file_path(output_base, id)
    cmd = `$(exec_path) sample id=$(id) data file=$(data_file) output file=$(sample_file)`
    #println(cmd)
    pipeline(cmd; stdout = log_file), (sample_file, log_file)
end

"""
$(SIGNATURES)

Default `output_base`, in the same directory as the model. Internal, not exported.
"""
data_file_path(output_base::AbstractString, id::Int) = output_base * "_data_$(id).R"

"""
$(SIGNATURES)

Sample `n_chains` from `model` using `data_file`. Return the full paths of the sample files
and logs as pairs. In case of an error with a chain, the first value is `nothing`.

`output_base` is used to write the data file (using `StanDump.stan_dump`) and to determine
the resulting names for the sampler output. It defaults to the source file name without the
extension.

When `data` is provided as a `NamedTuple`, it is written using `StanDump.stan_dump` first.

When `rm_samples` (default: `true`), remove potential pre-existing sample files after
compiling the model.
"""
function stan_sample(model::StanModel,
                    n_chains::Integer;
                    output_base = StanRun.default_output_base(model),
                    rm_samples = true)
    #println("Using StanSample version of stan_sample.\n")
    exec_path = StanRun.ensure_executable(model)
    rm_samples && rm.(StanRun.find_samples(model))
    cmds_and_paths = [stan_cmd_and_paths(exec_path, output_base, id)
                      for id in 1:n_chains]
    pmap(cmds_and_paths) do cmd_and_path
        cmd, (sample_path, log_path) = cmd_and_path
        success(cmd) ? sample_path : nothing, log_path
    end
end

function stan_sample(model, data::Union{Dict, NamedTuple}, n_chains::Integer;
                     output_base = StanRun.default_output_base(model),
                     data_file = output_base * ".data.R",
                     rm_samples = true)
    stan_dump(data_file, data; force = true)
    stan_sample(model, data_file, n_chains; output_base = output_base, rm_samples = rm_samples)
end


end # module
