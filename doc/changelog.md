# Changelog

- v0.4.5

  - Fix a race condition issue.

- v0.4.4

  - **API CHANGE** `watchDir`'s option `pattern` renamed to `patterns`.
  - Fix a nagate pattern issue.

- v0.4.3

  - **BIG API CHANGE!** Now all iterator arguments are unified into the `opts`,
    including the watch handlers.
  - **API CHANGE** The `path` now reflects what sep style nofs is using.
  - Fix a delimiter issue on Windows.
  - Fix the path behavior on different systems.

- v0.3.4

  - Now `glob` array works as sequence, rather than running parallel.
  - Now `glob` can use patterns to exclude files.
  - Better posix path handling.

- v0.3.1

  - Now pattern path is supported by almost every function.
  - Fix a `mapDir` pattern issue.
  - Update deps.

- v0.2.8

  - Fix filter behavior of `copy`.
  - Add `isFnFileOnly` option to `eachDir`.

- v0.2.6

  - **API CHANGE** `watchDir`.
  - Fix a memory leak issue of `watchDir`.
  - **API CHANGE** `readDirs` removed.

- v0.2.5

  - Fix the async exists bug of `mkDirs`.
  - Fix a bug when move a single file to a non-exists deep path.
  - Optimize the default `all` value.

- v0.2.0

  - Add all basic Promise functions.
