"""

Julia package to compile and sample models using Stan's cmdstan binary.

$(SIGNATURES)

# Extended help

Exports:
```Julia
* `SampleModel`                        : Model structure to sample a Stan language model
* `stan_sample`                        : Sample the model
* `read_samples`                       : Read the samples from .csv files
* `read_summary`                       : Read the cmdstan summary .csv file
* `stan_summary`                       : Create the stansummary .csv file
* `stan_generate_quantities`           : Simulate generated_quantities
* `read_generated_quantities`          : Read generated_quantities values
```
"""
module StanSample

using Reexport
using Requires

using CSV, DelimitedFiles, Unicode, Parameters
using NamedTupleTools, Tables, TableOperations
using DataFrames, Serialization

using DocStringExtensions: FIELDS, SIGNATURES, TYPEDEF

@reexport using StanBase

import StanBase: update_model_file, par, handle_keywords!
import StanBase: executable_path, ensure_executable, stan_compile
import StanBase: update_json_files
import StanBase: data_file_path, init_file_path, sample_file_path
import StanBase: generated_quantities_file_path, log_file_path
import StanBase: diagnostic_file_path, setup_diagnostics

function __init__()
    @require MonteCarloMeasurements="0987c9cc-fe09-11e8-30f0-b96dd679fdca" include("utils/particles.jl")
    @require DimensionalData="0703355e-b756-11e9-17c0-8b28908087d0" include("utils/dimarray.jl")
    @require MCMCChains="c7f686f2-ff18-58e9-bc7b-31028e88f75d" include("utils/mcmcchains.jl")
    @require AxisKeys="94b1ba4f-4ee9-5380-92f1-94cde586c3c5" include("utils/keyedarray.jl")
end

include("stanmodel/SampleModel.jl")

include("stanrun/stan_run.jl")
include("stanrun/cmdline.jl")
include("stanrun/diagnose.jl")
include("stanrun/stan_generate_quantities.jl")

include("stansamples/available_chains.jl")
include("stansamples/read_samples.jl")
include("stansamples/read_csv_files.jl")
include("stansamples/convert_a3d.jl")
include("stansamples/stan_summary.jl")
include("stansamples/read_summary.jl")
include("stansamples/stansummary.jl")

include("utils/namedtuples.jl")
include("utils/tables.jl")
include("utils/dataframes.jl")
include("utils/nesteddataframe.jl")

stan_sample = stan_run

export
    CMDSTAN_HOME,
    set_cmdstan_home!,
    SampleModel,
    stan_sample,
    read_samples,
    read_summary,
    stan_summary,
    stan_generate_quantities,
    available_chains,
    diagnose,
    make_string,
    set_make_string

if isdir(joinpath(CMDSTAN_HOME, "..", "bridgestan")) &&
    isfile(joinpath(CMDSTAN_HOME, "..", "bridgestan", "julia",
        "src", "BridgeStan.jl"))
    
    include(joinpath(CMDSTAN_HOME, "..", "bridgestan", "julia",
        "src", "BridgeStan.jl"))

    include("bridgestan/create_smb.jl")

    export
        BridgeStan,
        StanModel
end



end # module
