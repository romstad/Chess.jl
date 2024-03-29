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

Chess.jl can be installed from the package manager at Julia's REPL:

```
(@v1.6) pkg> add Chess
```
