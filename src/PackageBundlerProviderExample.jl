module PackageBundlerProviderExample

using Artifacts
import Pkg
import TOML

"""
    install()

Install all bundled package environemnts into the current Julia depot.
"""
function install()
    # Check whether we have `juliaup` installed. Needed since different
    # environments that have been bundled may use different `julia` versions,
    # and so we need to be able to multiplex them. Since `juliaup` is the
    # official method for installing `julia` this is a safe assumption. Other
    # non-standard setups need to handle things themselves.
    multiplexer = juliaup()

    @info "Installing bundled packages and their environments."

    # Install the bundled registry. Can be removed using `remove()`.
    script = joinpath(artifact"PackageBundlerExampleRegistry", "registry", "install.jl")
    run(`$(Base.julia_cmd()[1]) --startup-file=no $script`)

    @info "Resolving dependencies and precompiling all packages. This might take a while."

    # Ensure all the included environments are installed, resolved, and
    # precompiled using the right `julia` versions.
    environments = joinpath(artifact"PackageBundlerExampleRegistry", "environments")
    for each in readdir(environments)
        manifest = joinpath(environments, each, "Manifest.toml")
        if !isfile(manifest)
            error("Could not find the manifest file for the environment `$each`.")
        end
        toml = TOML.parsefile(manifest)

        julia_version = toml["julia_version"]
        channel = "+$julia_version"
        project = "@$each"

        try
            run(`$multiplexer add $julia_version`)
        catch error
            @error "failed to install required `julia` version using `juliaup`." version = julia_version
            rethrow(error)
        end

        @info "Resolving and precompiling environment." environment = each

        try
            run(`julia $channel --startup-file=no --project=$project -e 'import Pkg; Pkg.resolve(); Pkg.precompile()'`)
        catch error
            @error "failed to resolve and precompile environment." environment = each
            rethrow(error)
        end
    end
end

function remove()
    uuid = Base.UUID("90a320f3-05ce-182c-5a7d-cbdad425170e")
    registry = "PackageBundlerExampleRegistry"
    for reg in Pkg.Registry.reachable_registries()
        if reg.uuid == uuid
            script = joinpath(dirname(reg.path), registry, "remove.jl")
            run(`$(Base.julia_cmd()[1]) --startup-file=no $script`)
            Pkg.gc()
            return
        end
    end
    error("could not remove registry.")
end

"""
    juliaup()

Returns the `juliaup` command for use in `run` calls. Throws an error when it is
not available on the `PATH`.
"""
function juliaup()
    if isnothing(Sys.which("juliaup"))
        error("The `juliaup` command is not available. It is required for use of this package.")
    else
        return "juliaup"
    end
end

function __init__()

end

end # module PackageBundlerProviderExample
