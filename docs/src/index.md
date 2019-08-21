# Chess.jl

A Julia chess programming library.

## Introduction

This package contains various utilities for computer chess programming. There
are functions for creating and manipulating chess games, chess positions and
sets of squares on the board, for reading and writing chess games in the popular
PGN format (including support for comments and variations), and for interacting
with [UCI chess engines](http://wbec-ridderkerk.nl/html/UCIProtocol.html).

The library was designed for the purpose of doing machine learning experiments
in computer chess, but it should also be suitable for many other types of
computer chess software.


## Installation

`Chess` is a registered package and can be installed via

```julia
Pkg.add("Chess")
```

## Usage

### Games

### Boards

### PGN Import and Export

### Interacting with UCI Chess Engines

TBD

```@index
```

```@autodocs
Modules = [Chess, Chess.PGN, Chess.UCI]
```
