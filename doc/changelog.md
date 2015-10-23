# Changelog

- v0.10.9

  - fix: a copy self bug
  - upd: deps
  - fix: a watch stats bug

- v0.10.3

  - upd: deps

- v0.9.9

  - opt: #9 more intuitive api, never override user settings completely
  - upd: deps

- v0.9.4

  - upd: deps

- v0.9.0

   - **API CHANGE** `watchDir`'s handler now use `stats` to detect if the
     path is a directory.

- v0.8.3

  - **API CHANGE** The `promisify` is now available with `nofs.PromiseUtils.promisify`,
    thus you can access all the helpers of `yaku/lib/utils` now.
  - upd: deps

- v0.7.0

  - fix: ensureFile shouldn't change atime and mtime
  - upd: deps

- v0.6.6

  - opt: the osx open file number issue

- v0.6.3

 - **BIG CHANGE** Now use `yaku` instead of `bluebird`.

- v0.5.9

  - fix: a bug when glob match multiple patterns
  - upd deps

- v0.5.7

  - Add 'stats' to `watchDir`'s handler.

- v0.5.6

  - Fix `./dir/path` and `dir/path` issue
  - Optimize remove pattern.
  - Fix an error handler issue.
  - Fix a `writeFile` promise issue.

- v0.5.2

  - Optimize the `remove`'s default behavior when hanlding symbol links.
  - Fix a `baseDir` issue.

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
