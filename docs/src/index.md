# Chess.jl

A Julia chess programming library.

## Introduction

This package contains various utilities for computer chess programming. There
are functions for creating and manipulating chess games, chess positions and
sets of squares on the board, for reading and writing chess games in the popular
PGN format (including support for comments and variations), for creating opening
trees, and for interacting with
[UCI chess engines](http://wbec-ridderkerk.nl/html/UCIProtocol.html).

The library was designed for the purpose of doing machine learning experiments
in computer chess, but it should also be suitable for most other types of chess
software.

## Installation

`Chess` is not yet a registered package and needs to be installed via its GitHub
URL:

```
(v1.2) pkg> add https://github.com/romstad/Chess.jl
```
