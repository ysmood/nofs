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
- Unified intuitive API. Supports both **Promise**, **Sync** and **Callback** paradigms.
- Very light weight.

## Install

```shell
npm install nofs
```

## API Convention

### Path & Pattern

Any path that can be a pattern it will do.

### Unix Path Separator

When the system is Windows and `process.env.forceUnixSep != 'off'`, nofs will force all the path separators to `/`, such as `C:\a\b` will be transformed to `C:/a/b`.

### Promise & Callback

If you call an async function without callback, it will return a promise.
For example the `nofs.remove('dir', -> 'done!' )` are the same with
`nofs.remove('dir').then -> 'done!'`.

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
fs.mkdirs 'deep/dir/path'
.then ->
    fs.outputFile 'a.txt', 'hello world'
.then ->
    fs.move 'dir/path', 'other'
.then ->
    fs.copy 'one/**/*.js', 'two'
.then ->
    # Get all files, except js files.
    fs.glob ['deep/**', '!**/*.js']
.then (list) ->
    console.log list
.then ->
    # Remove only js files.
    fs.remove 'deep/**/*.js'


###
# Concat all css files.
###
fs.reduceDir 'dir/**/*.css', {
    init: '/* Concated by nofs */\n'
    iter: (sum, { path }) ->
        fs.readFile(path).then (str) ->
            sum += str + '\n'
}
.then (concated) ->
    console.log concated



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

fs.eachDir('.', {
    searchFilter: filter # Ensure subdirectory won't be searched.
    filter: filter
    iter: (info) -> info  # Directly return the file info object.
}).then (tree) ->
    # Instead a list as usual,
    # here we get a file tree for further usage.
    console.log tree
```


## Works like Gulp

For more information see project [nokit][].

```coffee
fs = require 'nofs'

# coffee plugin
coffee = (path) ->
    fs.readFile path, 'utf8'
    .then (coffee) ->
        # Unlike pipe, you can still control all the details esaily.
        '/* Add Lisence Info */\n\n' + coffee

# writer plugin: A simple curried function.
writer = (path) -> (js) ->
    fs.outputFile path, js

# minify plugin
minify = (js) ->
    uglify = require 'uglify-js'
    uglify.minify js, { fromString: true }

# Use the plugins.
jsTask = ->
    # All files will be compiled concurrently.
    fs.mapDir 'src/**/*.coffee', 'dist', {
        iter: (src, dest) ->
            # Here's the work flow, simple yet readable.
            coffee src
            .then minify
            .then writer(dest)
    }

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

## `graceful-fs`

You can use `process.env.gracefulFs == 'off'` to disable it.

## Benckmark

[`nofs.copy` vs `ncp`](benchmark/ncp.coffee)

## Lisence

MIT


[nokit]: https://github.com/ysmood/nokit