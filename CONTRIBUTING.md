# Contributing

## Install

If you are not using `asdf`, you will need to manually install the program versions listed in `.tool-versions`.
Otherwise, simply run `asdf install` and then:

```shell
mix deps.get
mix deps.compile
mix compile
```

## Run tests

Before running `mix test`, ensure you have setup your environment variables.
Look at the `.env.example` file for the required variables.
Then run `mix test` to run the tests.

## Quality

Run `mix quality` to run the full set of quality checks (hex.audit, format,
credo --strict, sobelow, dialyzer, test --cover) in one command, or run
them individually:

- Run `mix format` to format the code.
- Run `mix credo` to run the linter.

## CI/CD

We use GitHub Actions to:

- Run the test suite across a matrix of Elixir/OTP versions
- Run format/credo --strict
- Check for vulnerabilities (sobelow/hex.audit)
- Run dialyzer
- Enforce conventional commits on PRs
- Cut releases and publish to Hex.pm via release-please

See the `.github/workflows/` directory for more details.
