# `PackageBundler.jl` provider example

This repository contains example configuration for consuming a package bundler
artifact generated via `PackageBundler.jl`.

## Installation

> [!TIP]
>
> You need to have `juliaup` installed to be able to continue with this guide.

To install the bundled packages and environments that this package provides
run the following:

> [!IMPORTANT]
> <details>
>  <summary><strong>Windows Powershell</strong></summary>
>  
> Copy and run the below code in a terminal:
>
> ```
> julia --startup-file=no --project=@PackageBundlerProviderExample -e '
>   import Pkg;
>   Pkg.add(; url = \"https://github.com/MichaelHatherly/package-bundler-provider-example\");
>   import PackageBundlerProviderExample;
>   PackageBundlerProviderExample.install()
> '
> ```
> </details>
>
> <details>
>  <summary><strong>macOS and Linux Shells</strong></summary>
>
> Copy and run the below code in a terminal:
>
> ```
> julia --startup-file=no --project=@PackageBundlerProviderExample -e '
>   import Pkg;
>   Pkg.add(; url = "https://github.com/MichaelHatherly/package-bundler-provider-example");
>   import PackageBundlerProviderExample;
>   PackageBundlerProviderExample.install()
> '
> ```
> </details>

## Updating

To update the bundled packages and environments that this package provides
run the following:

```
julia --startup-file=no --project=@PackageBundlerProviderExample -e '
  import Pkg;
  Pkg.update();
  import PackageBundlerProviderExample;
  PackageBundlerProviderExample.install()
'
```

## Usage

The installation above adds several global environments to your Julia depot. These can be used
via the `--project=@` syntax as follows:

```
julia --project=@bundled@v1.1.0
```

> [!WARNING]
>
> Each bundled environment requires a specific `julia` version. Make sure to run `julia` with
> the correct channel, e.g.
>
> ```
> julia +1.10.1 --project=@bundled@v1.0.0
> ```
