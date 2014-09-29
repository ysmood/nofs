## Overview

Any function that has a `Sync` version will has a promise version end with `P`,
for example `fs.readFile`, `fs.readFileSync`, `fs.readFileP`.

For normal api see [fs-extra][0].

## Extra helpers

* fs.fileExists(path)
* fs.fileExistsSync(path)
* fs.fileExistsP(path)
* fs.dirExists(path)
* fs.dirExistsSync(path)
* fs.dirExistsP(path)

[0]: https://github.com/jprichardson/node-fs-extra