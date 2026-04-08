# Julia Package Project Structure

Reference patterns for Julia package organisation based on established projects like CensoredDistributions.jl.

## Directory Structure

```
Package.jl/
├── .claude/                    # Claude Code config
├── .github/
│   └── workflows/              # CI, docs, etc.
├── .gitignore
├── .JuliaFormatter.toml        # Formatting config
├── .pre-commit-config.yaml     # Pre-commit hooks
├── benchmark/
│   ├── Project.toml
│   ├── Manifest.toml
│   └── runbenchmarks.jl
├── CLAUDE.md                   # Claude instructions
├── docs/
│   ├── Project.toml
│   ├── Manifest.toml
│   ├── make.jl                 # Documentation build
│   ├── pages.jl                # Page structure (optional)
│   └── src/                    # Documentation source
├── LICENSE
├── Manifest.toml
├── NEWS.md                     # Changelog
├── Project.toml                # Package manifest
├── README.md
├── src/
│   ├── Package.jl              # Main module
│   ├── component/              # Component implementations
│   ├── utils/                  # Utility functions
│   ├── docstrings.jl           # Shared templates
│   └── public.jl               # Public API declarations
├── Taskfile.yml                # Task automation
└── test/
    ├── Project.toml
    ├── Manifest.toml
    ├── runtests.jl             # Main test file
    ├── component/              # Component tests
    └── package/                # Quality tests
        ├── Aqua.jl
        ├── CodeFormatting.jl
        └── DocTest.jl
```

## Configuration Files

### Taskfile.yml

**Always use Task for development operations.**

Essential tasks:
```yaml
version: '3'

tasks:
  test:
    desc: Run comprehensive test suite
    cmds:
      - julia --project=. -e 'using Pkg; Pkg.test()'

  test-fast:
    desc: Run tests quickly (skip quality checks)
    cmds:
      - julia --project=. -e 'using Pkg; Pkg.test(test_args=["skip_quality"])'

  test-quality:
    desc: Run only quality checks
    cmds:
      - julia --project=. -e 'using Pkg; Pkg.test(test_args=["quality_only"])'

  docs:
    desc: Build complete documentation
    cmds:
      - julia --project=docs docs/make.jl

  docs-fast:
    desc: Build docs quickly (skip notebooks)
    cmds:
      - julia --project=docs docs/make.jl --skip-notebooks

  format:
    desc: Format code with JuliaFormatter
    cmds:
      - julia --project=test -e 'using JuliaFormatter; format(".")'

  setup:
    desc: Set up development environment
    cmds:
      - julia --project=. -e 'using Pkg; Pkg.instantiate()'
      - julia --project=test -e 'using Pkg; Pkg.instantiate()'
      - julia --project=docs -e 'using Pkg; Pkg.instantiate()'

  dev:
    desc: Development workflow (format + precommit + fast test + fast docs)
    cmds:
      - task: format
      - task: precommit
      - task: test-fast
      - task: docs-fast

  precommit:
    desc: Run pre-commit hooks
    cmds:
      - pre-commit run --all-files

  pkg-status:
    desc: Show package status across environments
    cmds:
      - julia --project=. -e 'using Pkg; Pkg.status()'
      - julia --project=test -e 'using Pkg; Pkg.status()'
      - julia --project=docs -e 'using Pkg; Pkg.status()'
```

### .pre-commit-config.yaml

```yaml
repos:
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
    -   id: trailing-whitespace
    -   id: end-of-file-fixer
    -   id: check-yaml
    -   id: check-added-large-files
        args: ['--maxkb=200']
-   repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
    -   id: detect-secrets
```

### .JuliaFormatter.toml

```toml
style = "sciml"
```

### .gitignore

```
*.jl.cov
*.jl.mem
/docs/build/
/docs/site/
Manifest.toml
.DS_Store
*.cov
lcov.info
```

## Development Workflow

### Task Commands (Preferred)

```bash
# Discover available tasks
task --list

# Common development cycle
task dev

# Testing
task test          # Full suite
task test-fast     # Skip quality checks
task test-quality  # Only quality checks

# Documentation
task docs-fast     # Quick build
task docs          # Full build with notebooks

# Environment
task setup         # Set up from scratch
task pkg-status    # Check all environments
```

### Direct Julia Commands (Reference)

```bash
# Only use when tasks don't cover the need

# Environment management (use Pkg, never edit Project.toml directly)
julia --project=. -e 'using Pkg; Pkg.update()'
julia --project=. -e 'using Pkg; Pkg.add("PackageName")'

# Testing
julia --project=. -e 'using Pkg; Pkg.test()'

# Documentation
julia --project=docs docs/make.jl
```

## Testing Patterns

### TestItemRunner

```julia
using TestItemRunner

@testitem "Component functionality" begin
    using MyPackage

    @test my_function(1) == 2
    @test_throws ArgumentError my_function(-1)
end
```

### Test Organisation

```
test/
├── runtests.jl           # Main runner
├── component/            # Tests by component
│   ├── feature1.jl
│   └── feature2.jl
└── package/              # Quality tests
    ├── Aqua.jl           # Package quality
    ├── CodeFormatting.jl # JuliaFormatter check
    ├── CodeLinting.jl    # (if applicable)
    └── DocTest.jl        # Documentation tests
```

### Quality Tests

**Aqua.jl** (test/package/Aqua.jl):
```julia
@testitem "Aqua.jl quality tests" begin
    using Aqua, MyPackage
    Aqua.test_all(MyPackage)
end
```

**JuliaFormatter** (test/package/CodeFormatting.jl):
```julia
@testitem "Code formatting" begin
    using JuliaFormatter
    @test format(pkgdir(MyPackage), overwrite=false)
end
```

## Documentation Standards

### Docstring Syntax

```julia
# Simple docstrings
@doc "
Brief description.

# Arguments
- `x`: Description

# Returns
Description of return value

# Examples
```jldoctest
julia> my_function(1)
2
```
"
function my_function(x)
    # implementation
end

# With LaTeX (use raw string)
@doc raw"
Computes ``f(x) = \int_0^x t^2 dt``
"
function math_function(x)
    # implementation
end
```

### DocStringExtensions

```julia
using DocStringExtensions

# Use regular strings for template expansion
@doc "
$(TYPEDSIGNATURES)

Brief description.

$(TYPEDFIELDS)
"
struct MyType
    "Field description"
    field::Int
end
```

**Never use `@doc raw"` with templates** - prevents expansion.

## Code Style

### SciML Standards

- Avoid type instability
- Ensure efficient precompilation
- Max 80 characters per line
- No trailing whitespace
- Use JuliaFormatter with SciML style

### Performance Patterns

```julia
# Check type stability
@code_warntype my_function(args...)

# Precompilation
using PrecompileTools
@compile_workload begin
    my_function(example_args...)
end
```

## Package Structure

### Main Module

```julia
# src/Package.jl
module Package

using SomeDependency

# Public API
include("public.jl")

# Core implementations
include("component/Component.jl")
include("utils/Utils.jl")

# Docstring templates
include("docstrings.jl")

# Exports
export main_function, MainType

end
```

### Multiple Environments

Julia packages maintain separate environments:
- Root (`Project.toml`) - Package dependencies
- `test/` - Test dependencies
- `docs/` - Documentation dependencies
- `benchmark/` - Benchmark dependencies

Use `Pkg.add()` in appropriate environment, never edit Project.toml directly.
