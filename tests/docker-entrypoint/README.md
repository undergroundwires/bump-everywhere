# [docker-entrypoint](./../../docker-entrypoint.sh) tests

It's a simple environment to manually and locally test the changes in [docker-entrypoint.sh](./../../docker-entrypoint.sh).

## Run tests

- Update [middleman.sh](./middleman.sh) to reflect changes in  [docker-entrypoint.sh](./../../docker-entrypoint.sh)
- Run `./tests/docker-entrypoint/caller.sh` and ensure it prints the parameters in expected way.

## Files

### [`script.sh`](./script.sh)

- Represents [`bump-everywhere.sh`](./../../scripts/bump-everywhere.sh) with same parameter parsing logic but just echoes the parameters
- The test should assert that it takes and echoes the parameters in right way.

### [middleman.sh](./middleman.sh)

- Represents [docker-entrypoint.sh](./../../docker-entrypoint.sh) that that's supposed to take the parameters from the caller and translates them into expanded parameters as the script would expect.
- This is the **system under test** so update it to reflect changes in [docker-entrypoint.sh](./../../docker-entrypoint.sh)

### [caller.sh](./caller.sh)

- The entrypoint to run the test.
- It calls the [middleman](./middleman.sh) as both:
  - A user
    - Where parameter and values are sent in an expected way
    - E.g. `--parameter value --parameter2 value2`
  - [As GitHub actions](./../../action.yml)
    - Each parameter name and value is double quoted together.
    - E.g. `"--parameter value" "--parameter2 value2"`
