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

- Run `mix format` to format the code.
- Run `mix credo` to run the linter.

## CI/CD

We use CircleCI to:

- Run the code_analysis (format/credo)
- Check for vulnerabilities
- Run the tests

See the `.circleci/config.yml` file for more details.
