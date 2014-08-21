defmodule ExParsec.Operators do
    @moduledoc """
    Provides operators that make using common combinators easier.
    """

    import ExParsec.Base

    @doc """
    Equivalent to `ExParsec.Base.bind/2`.
    """
    defmacro parser ~>> function do
        quote do: bind(unquote(parser), unquote(function))
    end

    @doc """
    Equivalent to `ExParsec.Base.pair_right/2`.
    """
    defmacro parser1 ~> parser2 do
        quote do: pair_right(unquote(parser1), unquote(parser2))
    end

    @doc """
    Equivalent to `ExParsec.Base.pair_left/2`.
    """
    defmacro parser1 <~ parser2 do
        quote do: pair_left(unquote(parser1), unquote(parser2))
    end

    @doc """
    Equivalent to `ExParsec.Base.pair_both/2`.
    """
    defmacro parser1 <~> parser2 do
        quote do: pair_both(unquote(parser1), unquote(parser2))
    end

    @doc """
    Equivalent to `ExParsec.Base.map/2`.
    """
    defmacro parser1 |~> function do
        quote do: map(unquote(parser1), unquote(function))
    end

    @doc """
    Equivalent to `ExParsec.Base.either/2`.
    """
    defmacro parser1 <|> parser2 do
        quote do: either(unquote(parser1), unquote(parser2))
    end
end
