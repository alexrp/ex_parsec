defmodule ExParsec.Binary do
    @moduledoc """
    Provides common parsers that operate on binary data.

    These parsers all require that the input is bitstring data. They also
    assume that the `ExParsec.Input.get/2` implementation supports an `:n`
    option specifying how many bits to fetch.
    """

    import ExParsec.Base
    import ExParsec.Helpers

    alias ExParsec.Parser

    @doc """
    Parses `n` bits of data.
    """
    @spec bits(non_neg_integer()) :: ExParsec.t(term(), bitstring())
    defparser bits(n) in p do
        case Parser.get(p, [n: n]) do
            {:error, r} -> failure([error(p, :io, "encountered I/O error: #{inspect(r)}")])
            :eof -> failure([error(p, :eof, "expected #{n} bits but encountered end of file")])
            {p, bits} -> success(p, bits)
        end
    end

    @doc """
    Parses an unsigned 8-bit integer.
    """
    @spec uint8() :: ExParsec.t(term(), 0 .. 255)
    defparser uint8() in p do
        map(bits(8), fn(<<b>>) -> b end).(p)
    end

    @doc """
    Parses a signed 8-bit integer.
    """
    @spec sint8() :: ExParsec.t(term(), -128 .. 127)
    defparser sint8() in p do
        map(bits(8), fn(<<b :: signed>>) -> b end).(p)
    end

    @doc """
    Parses an unsigned 16-bit integer.
    """
    @spec uint16() :: ExParsec.t(term(), 0 .. 65535)
    defparser uint16() in p do
        map(bits(16), fn(<<b :: size(16)>>) -> b end).(p)
    end

    @doc """
    Parses a signed 16-bit integer.
    """
    @spec sint16() :: ExParsec.t(term(), -32768 .. 32767)
    defparser sint16() in p do
        map(bits(16), fn(<<b :: signed-size(16)>>) -> b end).(p)
    end

    @doc """
    Parses an unsigned 32-bit integer.
    """
    @spec uint32() :: ExParsec.t(term(), 0 .. 4294967295)
    defparser uint32() in p do
        map(bits(32), fn(<<b :: size(32)>>) -> b end).(p)
    end

    @doc """
    Parses a signed 32-bit integer.
    """
    @spec sint32() :: ExParsec.t(term(), -2147483648 .. 2147483647)
    defparser sint32() in p do
        map(bits(32), fn(<<b :: signed-size(32)>>) -> b end).(p)
    end

    @doc """
    Parses an unsigned 64-bit integer.
    """
    @spec uint64() :: ExParsec.t(term(), 0 .. 18446744073709551615)
    defparser uint64() in p do
        map(bits(64), fn(<<b :: size(64)>>) -> b end).(p)
    end

    @doc """
    Parses a signed 64-bit integer.
    """
    @spec sint64() :: ExParsec.t(term(), -9223372036854775808 .. 9223372036854775807)
    defparser sint64() in p do
        map(bits(64), fn(<<b :: signed-size(64)>>) -> b end).(p)
    end

    @doc """
    Parses a 32-bit floating point value.
    """
    @spec float32() :: ExParsec.t(term(), float())
    defparser float32() in p do
        map(bits(32), fn(<<b :: float-size(32)>>) -> b end).(p)
    end

    @doc """
    Parses a 64-bit floating point value.
    """
    @spec float64() :: ExParsec.t(term(), float())
    defparser float64() in p do
        map(bits(64), fn(<<b :: float>>) -> b end).(p)
    end
end
