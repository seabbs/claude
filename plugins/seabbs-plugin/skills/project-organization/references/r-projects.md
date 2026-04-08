# R Package Project Structure

Reference patterns for R package organisation based on established projects like primarycensored, EpiNow2, and epinowcast.

## Directory Structure

```
package/
├── .claude/                    # Claude Code config
├── .github/
│   └── workflows/              # R-CMD-check, pkgdown, etc.
├── .lintr                      # Linting configuration
├── .pre-commit-config.yaml     # Pre-commit hooks
├── .Rbuildignore               # Build exclusions
├── _pkgdown.yml                # Documentation site config
├── CITATION.cff                # Citation metadata
├── CLAUDE.md                   # Claude instructions
├── codemeta.json               # Package metadata
├── cran-comments.md            # CRAN submission notes
├── data/                       # Exported datasets
├── data-raw/                   # Scripts to create data
├── DESCRIPTION                 # Package metadata
├── inst/
│   ├── CITATION                # R citation file
│   └── stan/                   # Stan models (if applicable)
│       └── functions/          # Stan function files
├── LICENSE.md
├── man/                        # Generated documentation
├── NAMESPACE                   # Export declarations
├── NEWS.md                     # Changelog
├── pkgdown/                    # pkgdown assets
├── R/                          # R source code
├── README.md
├── README.Rmd                  # README source
├── tests/
│   └── testthat/
│       ├── helper-*.R          # Test helpers
│       ├── setup.R             # Test setup
│       └── test-*.R            # Test files
├── touchstone/                 # Benchmarking
└── vignettes/                  # Long-form documentation
```

## Configuration Files

### .pre-commit-config.yaml

```yaml
repos:
-   repo: https://github.com/lorenzwalthert/precommit
    rev: v0.4.3.9003
    hooks:
    -   id: style-files
        args: [--style_pkg=styler, --style_fun=tidyverse_style]
    -   id: use-tidy-description
    -   id: lintr
    -   id: parsable-R
    -   id: no-browser-statement
    -   id: deps-in-desc
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
    -   id: check-added-large-files
        args: ['--maxkb=200']
    -   id: end-of-file-fixer
        exclude: '\.Rd'
    -   id: trailing-whitespace
    -   id: check-yaml
-   repo: local
    hooks:
    -   id: forbid-to-commit
        name: Don't commit common R artifacts
        entry: Cannot commit .Rhistory, .RData, .Rds or .rds.
        language: fail
        files: '\.Rhistory|\.RData|\.Rds|\.rds$'
-   repo: meta
    hooks:
    -   id: check-hooks-apply
    -   id: check-useless-excludes
```

### .lintr

```
linters: linters_with_defaults(
  line_length_linter(80),
  object_name_linter = NULL
)
```

### .Rbuildignore

```
^\.claude$
^\.github$
^\.pre-commit-config\.yaml$
^\.lintr$
^_pkgdown\.yml$
^pkgdown$
^CLAUDE\.md$
^README\.Rmd$
^cran-comments\.md$
^touchstone$
^codemeta\.json$
^CITATION\.cff$
```

### .gitignore

```
.Rhistory
.RData
.Rproj.user
*.Rproj
docs/
inst/doc/
```

## Development Workflow

### Standard Commands

```bash
# Update documentation (REQUIRED before committing)
Rscript -e "devtools::document()"

# Run tests
Rscript -e "devtools::test()"

# Run specific test file
Rscript -e "testthat::test_file('tests/testthat/test-name.R')"

# Check package
Rscript -e "devtools::check()"

# Build pkgdown site
Rscript -e "pkgdown::build_site()"

# Test coverage
Rscript -e "covr::package_coverage()"

# Lint package
Rscript -e "lintr::lint_package()"
```

### Testing Patterns

**File naming**: `test-{component}.R`
**Helpers**: `helper-{name}.R` for shared test utilities
**Setup**: `setup.R` for fixtures and global test config

**testthat edition 3** conventions:
- `expect_identical()` over `expect_equal()` where exact match expected
- Multiple `expect_true()` calls over stacking with `&&`
- `expect_s3_class()` over `expect_true(inherits(...))`
- Specific expectations: `expect_lt()`, `expect_gt()`, `expect_length()`

**Environment helpers** (commonly defined in helper.R):
```r
on_ci <- function() isTRUE(as.logical(Sys.getenv("CI")))
not_on_cran <- function() !identical(Sys.getenv("NOT_CRAN"), "false")
```

### Stan Integration

For packages with Stan:

```
inst/stan/
├── functions/
│   ├── likelihood.stan
│   ├── priors.stan
│   └── utils.stan
└── model.stan
```

Stan functions exposed during tests via setup.R.
Use `pcd_cmdstan_model()` or similar wrapper for compilation.

## Package Naming

- **Internal functions**: Prefix with `.`
  ```r
  .internal_helper <- function() {}
  ```
- **Exported functions**: snake_case
  ```r
  public_function <- function() {}
  ```

## Documentation

### roxygen2 patterns

```r
#' Process input data
#'
#' This function processes input data according to specified parameters.
#'
#' @param data A data.frame containing input data
#' @inheritParams other_function
#'
#' @return A data.frame with processed results
#'
#' @family preprocessing
#'
#' @examples
#' \dontrun{
#' result <- process_data(my_data)
#' }
#'
#' @export
process_data <- function(data, method = "standard") {
  # implementation
}
```

- Use `@inheritParams` to avoid documentation duplication
- One sentence per line in descriptions
- UK English spelling
- `@family` for related function groups
