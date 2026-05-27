Pull Requests
-------------
Here are some reasons why a pull request may not be merged:

1. It hasn’t been reviewed.
2. It doesn’t include specs for new functionality.
3. It doesn’t include documentation for new functionality.
4. It changes behavior without changing the relevant documentation, comments, or specs.
5. It changes behavior of an existing public API, breaking backward compatibility.
6. It breaks the tests on a supported platform.
7. It doesn’t merge cleanly (requiring Git rebasing and conflict resolution).

If you would like to help in this process, you can start by evaluating open pull requests against the criteria above. For example, if a pull request does not include specs for new functionality, you can add a comment like: “If you would like this feature to be added to Thor, please add specs to ensure that it does not break in the future.” This will help move a pull request closer to being merged.

Include this emoji in the top of your ticket to signal to us that you read this file: 🌈

Specs
-----

Ensure that all specs and code linting checks pass before submitting a pull request.

To execute the specs locally, run:

```bash
bundle exec rspec
```

Linting checks are done with RuboCop. To run the linter, use:

```bash
bundle exec rubocop
```
