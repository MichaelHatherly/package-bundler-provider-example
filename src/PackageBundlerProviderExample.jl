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
    copy(environment::String, path::String)

Copy a bundled package environment to a new location. The environment is
resolved and precompiled in the new location. The `path` should not exist before
calling this function. The `environment` should be the name of one of the
bundled environments.

This function is useful when you want to duplicate an environment to a new
location locally so that you can add additional packages to it, since bundled
environments should be considered read-only.
"""
function copy(environment::String, path::String)
    environments_dir = joinpath(artifact"PackageBundlerExampleRegistry", "environments")
    environments = readdir(environments_dir)
    if environment in environments
        multiplexer = juliaup()

        # Ensure there aren't stale overrides that could interfere with the
        # copying of the environment since it might have changed `julia`
        # version.
        run(`$multiplexer override unset --nonexistent`)

        path = abspath(path)
        if ispath(path)
            error("`$path` already exists. Please remove it first if you want to duplicate an environment to that location.")
        else
            mkpath(path)

            # Copy from a read-only artifact environment to the new location, so
            # we need to copy the files manually.
            artifact_env = joinpath(environments_dir, environment)
            for (root, _, files) in walkdir(artifact_env)
                for file in files
                    # Skip the signing files since we expect them to be invalid
                    # as soon as a user adds additional packages.
                    endswith(file, r"\.(pub|sign)$") && continue

                    src = joinpath(root, file)
                    dst = joinpath(path, relpath(src, artifact_env))
                    mkpath(dirname(dst))
                    write(dst, read(src))
                end
            end

            # Add some metadata to the project file so that we can track the
            # environment that was copied.
            project = joinpath(path, "Project.toml")
            if !isfile(project)
                error("Could not find the project file for the environment `$path`.")
            end
            toml = TOML.parsefile(project)
            toml["package_bundler"] = Dict("environment" => environment)
            open(project, "w") do file_io
                TOML.print(file_io, toml, sorted=true, by=key -> (Pkg.Types.project_key_order(key), key))
            end

            manifest = joinpath(path, "Manifest.toml")
            if !isfile(manifest)
                error("Could not find the manifest file for the environment `$path`.")
            end
            toml = TOML.parsefile(manifest)

            julia_version = toml["julia_version"]

            try
                run(`$multiplexer add $julia_version`)
            catch error
                @error "failed to install required `julia` version using `juliaup`." version = julia_version
                rethrow(error)
            end

            @info "Resolving and precompiling environment." environment = path

            cd(path) do
                # Set the channel for this directory to override the default.
                run(`$multiplexer override set $julia_version`)
                try
                    run(`julia --startup-file=no --project=$path -e 'import Pkg; Pkg.resolve(); Pkg.precompile()'`)
                catch error
                    @error "failed to resolve and precompile environment." environment = path
                    rethrow(error)
                end
            end
        end
    else
        environments_fmt = join(("`$each`" for each in environments), ", ", ", and ")
        error("The environment `$environment` does not exist. Available environments are: $environments_fmt")
    end
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
