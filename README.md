# ExParsec

[![Build Status](https://travis-ci.org/alexrp/ex_parsec.png?branch=master)](https://travis-ci.org/alexrp/ex_parsec)

A parser combinator library inspired by Parsec.

## Usage

Add ExParsec as a dependency in your `mix.exs` file:

```elixir
def deps do
  [ {:ex_parsec, "~> 0.0.0"} ]
end
```

After you are done, run `mix deps.get` in your shell to fetch and compile
ExParsec. Start an interactive Elixir shell with `iex -S mix`.

```iex
iex> import ExParsec.Base
nil
iex> ExParsec.parse_value "foo", many(any_char())
{:ok, nil, ["f", "o", "o"]}
iex> ExParsec.parse_value "[x]", between(char("["), char("x"), char("]"))
{:ok, nil, "x"}
iex> ExParsec.parse_value "  spa ces  ",
                          sequence([skip(spaces),
                                    times(any_char(), 3),
                                    skip(space),
                                    times(any_char(), 3),
                                    skip(spaces),
                                    eof])
{:ok, nil, [nil, ["s", "p", "a"], nil, ["c", "e", "s"], nil, nil]}
```

## Features

* Can parse context-sensitive grammars.
* High-quality error messages readable by humans.
* Full UTF-8 string support.
* Non-text input can be parsed (e.g. tokens).
* Support for theoretically infinitely large files.
* Monadic parse blocks based on Elixir macros.
* Simple, extensible API surface.

## Examples
