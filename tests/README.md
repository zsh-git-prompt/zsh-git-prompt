# Testing

Testing is done by creating a local test git repository, modifying the state of it, and testing the raw output of the status line against the themed expectations.


# Running tests

`make test`

OR

`./tests/run_tests.sh`


# Adding a new test case
Create a new file in [`tests/test_cases/`](./test_cases) with your script. The repository is recreated between test cases so feel free to modify it's state. Do not alter files outside of the repository if at all possible however!


## Available functions
- `assert_equal` - sets an error code if expected input does not match actual input
- `run_super_status` - runs the `zsh-git-prompt` script and captures the output


## Notes

### Themes
As this tests the default configuration, with colored themes, it can be a bit difficult to debug new test cases sometimes due to the printed output's color codes being parse by your local terminal. If you see output that looks identical, colors and all, a `reset_color` was probably missed - look for "empty" sets of braces that might need to look like `%{${reset_color}%}`

See `run_tests.sh` for implementation details
