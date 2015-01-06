# nofs

## Overview

Any function that has a `Sync` version will has a promise version that ends with `P`,
for example `fs.readFileSync` will have a `fs.readFileP`.

[![NPM version](https://badge.fury.io/js/nofs.svg)](http://badge.fury.io/js/nofs) [![Build Status](https://travis-ci.org/ysmood/nofs.svg)](https://travis-ci.org/ysmood/nofs) [![Build status](https://ci.appveyor.com/api/projects/status/11ddy1j4wofdhal7?svg=true)](https://ci.appveyor.com/project/ysmood/nofs)
 [![Deps Up to Date](https://david-dm.org/ysmood/nofs.svg?style=flat)](https://david-dm.org/ysmood/nofs)

## Install

```shell
npm install nofs
```

## Quick Start

```coffee
fs = require 'nofs'

# Callback
fs.outputFile 'x.txt', 'test', (err) ->
    console.log 'done'

# Sync
fs.outputFileSync 'x.txt', 'test'

# Promise
fs.mkdirsP 'deep/dir/path'
.then ->
    fs.outputFileP 'a.txt', 'hello world'
.then ->
    fs.moveP 'a.txt', 'b.txt'
.then ->
    fs.copyP 'b.txt', 'c.js'
.then ->
    # Get all folders.
    fs.readdirsP 'deep', { filter: /\/$/ }
.then (list) ->
    console.log list
.then ->
    fs.removeP 'deep'
```

## Changelog

Goto [changelog](doc/changelog.md)

## API

<%= api %>

## Lisence

MIT