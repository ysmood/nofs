# [nofs](https://github.com/ysmood/nofs)

## Overview

`nofs` extends Node's native `fs` module with some useful methods. It tries
to make your functional programming experience better. It's one of the core
lib of [nokit][].

[![NPM version](https://badge.fury.io/js/nofs.svg)](http://badge.fury.io/js/nofs) [![Build Status](https://travis-ci.org/ysmood/nofs.svg)](https://travis-ci.org/ysmood/nofs) [![Build status](https://ci.appveyor.com/api/projects/status/11ddy1j4wofdhal7?svg=true)](https://ci.appveyor.com/project/ysmood/nofs)
 [![Deps Up to Date](https://david-dm.org/ysmood/nofs.svg?style=flat)](https://david-dm.org/ysmood/nofs)

## Features

- Introduce `map` and `reduce` to folders.
- Recursive `glob`, `move`, `copy`, `remove`, etc.
- **Promise** by default.
- Unified intuitive API. Support **Promise**, **Sync** and **Callback**paradigms.
- Much lighter than [gulp](https://github.com/gulpjs/gulp), but much more flexible.

## Install

```shell
npm install nofs
```

## API Convention

### Path & Pattern

Any path that can be a pattern it will do.

### Unix Path Separator

When the system is Windows and `process.env.force_unix_sep != 'off'`, nofs  will force all the path separator to `/`, such as `C:\a\b` will be transformed to `C:/a/b`.

### Promise, Sync and Callback

Any function that has a `Sync` version will has a promise version that ends with `P`.
For example the `fs.remove` will have `fs.removeSync` for sync IO, and `fs.removeP` for Promise.

### [eachDir](#eachDirP)

It is the core function for directory manipulation. Other abstract functions
like `mapDir`, `reduceDir`, `glob` are built on top of it. You can play
with it if you don't like other functions.

### nofs & Node Native fs

`nofs` only extends the native module, no pollution will be found. You can
still call `nofs.readFile` as easy as pie.

### Inheritance of Options

A Function's options may inherit other function's, especially the functions it calls internally. Such as the `glob` extends the `eachDir`'s
option, therefore `glob` also has a `filter` option.

## Quick Start

```coffee
# You can replace "require('fs')" with "require('nofs')"
fs = require 'nofs'


###
# Callback
###
fs.outputFile 'x.txt', 'test', (err) ->
    console.log 'done'


###
# Sync
###
fs.readFileSync 'x.txt'
fs.copySync 'dir/a', 'dir/b'


###
# Promise
###
fs.mkdirsP 'deep/dir/path'
.then ->
    fs.outputFileP 'a.txt', 'hello world'
.then ->
    fs.moveP 'dir/path', 'other'
.then ->
    fs.copyP 'one/**/*.js', 'two'
.then ->
    # Get all files, except js files.
    fs.globP ['deep/**', '!**/*.js']
.then (list) ->
    console.log list
.then ->
    # Remove only js files.
    fs.removeP 'deep/**/*.js'


###
# Concat all css files.
###
fs.reduceDirP 'dir/**/*.css', {
    init: '/* Concated by nofs */\n'
}, (sum, { path }) ->
    fs.readFileP(path).then (str) ->
        sum += str + '\n'
.then (concated) ->
    console.log concated


###
# Compile files from one place to another.
###
fs.mapDirP 'from', 'to', (src, dest) ->
    fs.readFileP(src, 'utf8').then (str) ->
        compiled = '/* Compiled by nofs */\n' + str
        fs.outputFileP dest, compiled



###
# Play with the low level api.
# Filter all the ignored files with high performance.
###
patterns = fs.readFileSync('.gitignore', 'utf8').split '\n'

filter = ({ path }) ->
    for ptn in patterns
        if fs.pmatch.minimath path, ptn
            return false
    return true

fs.eachDirP('.', {
    searchFilter: filter # Ensure subdirectory won't be searched.
    filter: filter
}, (info) ->
    info  # Directly return the file info object.
).then (tree) ->
    # Instead a list as usual,
    # here we get a file tree for further usage.
    console.log tree
```


## VS Gulp

- If you know Promise, no learning curve.
- If you use it with [nokit][] `spawn`, you can esaily take advantage of multi-core cpu, and compile much faster.
- Error handling is more unified and flexible, since it is just Promise.
- Async sequence chainning is also more unified and flexible.
- Will works great with ES7 `async / await`.

For more information see project [nokit][].

```coffee
fs = require 'nofs'

# coffee plugin
coffee = (path) ->
    fs.readFileP path, 'utf8'
    .then (coffee) ->
        # Unlike pipe, you can still control all the details esaily.
        '/* Add Lisence Info */\n\n' + coffee

# writer plugin: A simple curried function.
writer = (path) -> (js) ->
    fs.outputFileP path, js

# minify plugin
minify = (js) ->
    uglify = require 'uglify-js'
    uglify.minify js, { fromString: true }

# Use the plugins.
jsTask = ->
    # All files will be compiled concurrently.
    fs.mapDirP 'src/**/*.coffee', 'dist', (src, dest) ->
        # Here's the work flow, simple yet readable.
        coffee src
        .then minify
        .then writer(dest)

cssTask = -> # ...

cleanTask = -> # ...

# Run all tasks concurrently, and sequence groups.
compileGroup = [jsTask(), cssTask()]
fs.Promise.all compileGroup
.then cleanTask # The clean will work after all compilers are settled.
.then ->
    console.log 'All Done!'
```

## Changelog

Goto [changelog](doc/changelog.md)

## Function Alias

For some naming convention reasons, `nofs` also uses some common alias for fucntions. See [src/alias.coffee](src/alias.coffee).

## API

__No native `fs` funtion will be listed.__

<%= api %>

## Benckmark

[`nofs.copy` vs `ncp`](benchmark/ncp.coffee)

## Lisence

MIT


[nokit]: https://github.com/ysmood/nokit