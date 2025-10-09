# Language Configurations

This document describes the configuration files and tools set up for each supported language in the dotfiles.

## Python

### Configuration Files

- `~/.pip/pip.conf`: Pip configuration file
  - Sets default index URL and trusted hosts
  - Configures cache directory and timeout settings
  - [Documentation](https://pip.pypa.io/en/stable/topics/configuration/)

- `~/.pythonrc`: Python startup file
  - Enables tab completion
  - Sets up history file
  - Configures readline settings

- `~/.pylintrc`: Pylint configuration
  - Enables common good practices
  - Configures maximum line length
  - Sets up import order
  - [Documentation](https://pylint.pycqa.org/en/latest/user_guide/configuration/index.html)

- `~/.flake8`: Flake8 configuration
  - Configures maximum line length
  - Sets up import order
  - Enables common good practices
  - [Documentation](https://flake8.pycqa.org/en/latest/user/configuration.html)

- `~/.mypy.ini`: MyPy configuration
  - Enables strict type checking
  - Configures Python version
  - Sets up import settings
  - [Documentation](https://mypy.readthedocs.io/en/stable/config_file.html)

- `~/.isort.cfg`: isort configuration
  - Configures import sorting
  - Sets up line length
  - [Documentation](https://pycqa.github.io/isort/docs/configuration/config_files.html)

- `~/.pre-commit-config.yaml`: Pre-commit configuration
  - Sets up common hooks (black, isort, flake8, mypy)
  - [Documentation](https://pre-commit.com/)

- `~/.poetry/config.toml`: Poetry configuration
  - Configures virtual environment location
  - Sets up package publishing settings
  - [Documentation](https://python-poetry.org/docs/configuration/)

### Tools

- `black`: Code formatter
- `isort`: Import sorter
- `flake8`: Linter
- `mypy`: Type checker
- `pytest`: Testing framework
- `ipython`: Enhanced REPL
- `jupyter`: Notebook environment
- `poetry`: Dependency management
- `pre-commit`: Git hooks

## Node.js

### Configuration Files

- `~/.npmrc`: NPM configuration
  - Sets up registry settings
  - Configures package scope
  - [Documentation](https://docs.npmjs.com/cli/v9/configuring-npm/npmrc)

- `~/.nvmrc`: Node version manager configuration
  - Specifies Node.js version
  - [Documentation](https://github.com/nvm-sh/nvm#nvmrc)

- `~/.eslintrc`: ESLint configuration
  - Enables common rules
  - Sets up TypeScript support
  - [Documentation](https://eslint.org/docs/latest/use/configure/)

- `~/.prettierrc`: Prettier configuration
  - Configures code formatting
  - Sets up line length
  - [Documentation](https://prettier.io/docs/en/configuration.html)

- `~/.yarnrc`: Yarn configuration
  - Sets up registry settings
  - Configures package scope
  - [Documentation](https://classic.yarnpkg.com/en/docs/yarnrc/)

- `~/.pnpmrc`: PNPM configuration
  - Sets up registry settings
  - Configures package scope
  - [Documentation](https://pnpm.io/configuring)

### Tools

- `npm`: Package manager
- `yarn`: Alternative package manager
- `pnpm`: Fast, disk space efficient package manager
- `typescript`: Type system
- `ts-node`: TypeScript execution
- `nodemon`: Development server
- `eslint`: Linter
- `prettier`: Code formatter
- `@vue/cli`: Vue.js CLI
- `@angular/cli`: Angular CLI

## Ruby

### Configuration Files

- `~/.gemrc`: RubyGems configuration
  - Sets up gem sources
  - Configures installation options
  - [Documentation](https://guides.rubygems.org/command-reference/#gem-environment)

- `~/.irbrc`: IRB configuration
  - Enables tab completion
  - Sets up history file
  - [Documentation](https://github.com/ruby/irb)

- `~/.pryrc`: Pry configuration
  - Configures REPL settings
  - Sets up plugins
  - [Documentation](https://github.com/pry/pry/wiki/Customization-and-configuration)

- `~/.rubocop.yml`: RuboCop configuration
  - Enables common good practices
  - Configures maximum line length
  - [Documentation](https://docs.rubocop.org/rubocop/configuration.html)

- `~/.solargraph.yml`: Solargraph configuration
  - Sets up language server
  - Configures documentation
  - [Documentation](https://solargraph.org/guides/configuration)

### Tools

- `bundler`: Dependency management
- `solargraph`: Language server
- `rubocop`: Linter
- `rspec`: Testing framework
- `pry`: Enhanced REPL
- `yard`: Documentation generator
- `rails`: Web framework

## Go

### Configuration Files

- `~/.go/config`: Go configuration
  - Sets up GOPATH
  - Configures module settings
  - [Documentation](https://golang.org/cmd/go/#hdr-Environment_variables)

- `~/.golangci.yml`: golangci-lint configuration
  - Enables common linters
  - Sets up maximum line length
  - [Documentation](https://golangci-lint.run/usage/configuration/)

- `~/.goreleaser.yml`: GoReleaser configuration
  - Sets up build settings
  - Configures release process
  - [Documentation](https://goreleaser.com/customization/)

### Tools

- `godoc`: Documentation generator
- `dlv`: Debugger
- `air`: Live reload
- `golangci-lint`: Linter
- `go-outline`: Code outline
- `gocode`: Code completion
- `godef`: Go to definition
- `goreturns`: Code completion
- `protoc-gen-go`: Protocol Buffers
- `gox`: Cross compilation
- `goreleaser`: Release automation

## Rust

### Configuration Files

- `~/.cargo/config.toml`: Cargo configuration
  - Sets up registry settings
  - Configures build settings
  - [Documentation](https://doc.rust-lang.org/cargo/reference/config.html)

- `~/.rustfmt.toml`: Rustfmt configuration
  - Configures code formatting
  - Sets up line length
  - [Documentation](https://rust-lang.github.io/rustfmt/)

- `~/.clippy.toml`: Clippy configuration
  - Enables common lints
  - Sets up maximum line length
  - [Documentation](https://rust-lang.github.io/rust-clippy/master/index.html)

### Tools

- `cargo-edit`: Dependency management
- `cargo-watch`: File watcher
- `cargo-expand`: Macro expansion
- `cargo-udeps`: Unused dependencies
- `cargo-audit`: Security audit
- `cargo-outdated`: Dependency updates
- `cargo-tarpaulin`: Code coverage
- `cargo-asm`: Assembly view
- `cargo-bloat`: Binary size analysis
- `cargo-llvm-cov`: Code coverage
- `cargo-nextest`: Test runner
- `cargo-release`: Release automation
- `cargo-sweep`: Cleanup
- `cargo-update`: Update dependencies
- `cargo-vet`: Supply chain security
- `cargo-workspaces`: Workspace management
- `cross`: Cross compilation
- `flamegraph`: Profiling
- `rustfmt`: Code formatter
- `clippy`: Linter
- `rust-analyzer`: Language server 