# [nofs](https://github.com/ysmood/nofs)

## Overview

`nofs` extends Node's native `fs` module with some useful methods. It tries
to make your functional programming experience better. It's one of the core
lib of [nokit][].

[![NPM version](https://badge.fury.io/js/nofs.svg)](http://badge.fury.io/js/nofs) [![Build Status](https://travis-ci.org/ysmood/nofs.svg)](https://travis-ci.org/ysmood/nofs) [![Build status](https://ci.appveyor.com/api/projects/status/github/ysmood/nofs?svg=true)](https://ci.appveyor.com/project/ysmood/nofs)
 [![Deps Up to Date](https://david-dm.org/ysmood/nofs.svg?style=flat)](https://david-dm.org/ysmood/nofs)

## Features

- Introduce `map` and `reduce` to folders.
- Recursive `glob`, `move`, `copy`, `remove`, etc.
- **Promise** by default.
- Unified intuitive API. Supports both **Promise**, **Sync** and **Callback** paradigms.
- Very light weight. Only depends on `yaku` and `minimath`.

## Install

```shell
npm install nofs
```

## API Convention

### Path & Pattern

Only functions like `readFile` which may confuse the user don't support pattern.

### Promise & Callback

If you call an async function without callback, it will return a promise.
For example the `nofs.remove('dir', () => 'done!')` are the same with
`nofs.remove('dir').then(() => 'done!')`.

### [eachDir](#eachDir)

It is the core function for directory manipulation. Other abstract functions
like `mapDir`, `reduceDir`, `glob` are built on top of it. You can play
with it if you don't like other functions.

### nofs & Node Native fs

Only the callback of `nofs.exists`
is slightly different, it will also gets two arguments `(err, exists)`.

`nofs` only extends the native module, no pollution will be found. You can
still require the native `fs`, and call `fs.exists` as easy as pie.

### Inheritance of Options

A Function's options may inherit other function's, especially the functions it calls internally. Such as the `glob` extends the `eachDir`'s
option, therefore `glob` also has a `filter` option.

## Quick Start

```js
// You can replace "require('fs')" with "require('nofs')"
let fs = require('nofs');

/*
 * Callback
 */
fs.outputFile('x.txt', 'test', (err) => {
    console.log('done');
});


/*
 * Sync
 */
fs.readFileSync('x.txt');
fs.copySync('dir/a', 'dir/b');


/*
 * Promise & async/await
 */
(async () => {
    await fs.mkdirs('deep/dir/path');
    await fs.outputFile('a.txt', 'hello world');
    await fs.move('dir/path', 'other');
    await fs.copy('one/**/*.js', 'two');

    // Get all files, except js files.
    let list = await fs.glob(['deep/**', '!**/*.js']);
    console.log(list);

    // Remove only js files.
    await fs.remove('deep/**/*.js');
})();


/*
 * Concat all css files.
 */
fs.reduceDir('dir/**/*.css', {
    init: '/* Concated by nofs */\n',
    iter (sum, { path }) {
        return fs.readFile(path).then(str =>
            sum += str + '\n'
        );
    }
}).then(concated =>
    console.log(concated)
);



/*
 * Play with the low level api.
 * Filter all the ignored files with high performance.
 */
let patterns = fs.readFileSync('.gitignore', 'utf8').split('\n');

let filter = ({ path }) => {
    for (let p of patterns) {
        // This is only a demo, not full git syntax.
        if (path.indexOf(p) === 0)
            return false;
    }
    return true;
}

fs.eachDir('.', {
    searchFilter: filter, // Ensure subdirectory won't be searched.
    filter: filter,
    iter: (info) => info  // Directly return the file info object.
}).then((tree) =>
    // Instead a list as usual,
    // here we get a file tree for further usage.
    console.log(tree)
);
```


## Changelog

Goto [changelog](doc/changelog.md)

## Function Name Alias

For some naming convention reasons, `nofs` also uses some common alias for fucntion names. See [src/alias.js](src/alias.js).

## FAQ

- `Error: EMFILE`?

  > This is due to system's default file descriptor number settings for one process.
  > Latest node will increase the value automatically.
  > See the [issue list](https://github.com/joyent/node/search?q=EMFILE&type=Issues&utf8=%E2%9C%93) of `node`.

## API

__No native `fs` funtion will be listed.__

<%= doc['src/main.js-toc'] %>

<%= doc['src/main.js'] %>

## Benckmark

See the `benchmark` folder.

```
Node v0.10, Intel Core i7 2.3GHz SSD, find 91,852 js files in 191,585 files:

node-glob: 9939ms
nofs-glob: 8787ms
```

Nofs is slightly faster.

## Lisence

MIT


[nokit]: https://github.com/ysmood/nokit