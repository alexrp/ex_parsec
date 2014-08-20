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
    Parses `n` bytes of data.
    """
    @spec bytes(non_neg_integer()) :: ExParsec.t(term(), binary())
    defparser bytes(n) in p do
        case Parser.get(p, [n: n * 8]) do
            {:error, r} -> failure([error(p, :io, "encountered I/O error: #{inspect(r)}")])
            :eof -> failure([error(p, :eof, "expected #{n} bytes but encountered end of file")])
            {p, bytes} -> success(p, bytes)
        end
    end

    @doc """
    Parses an unsigned `n`-bit integer encoded with the given `endianness`.
    """
    @spec uint(pos_integer(), :be | :le) ::
          ExParsec.t(term(), non_neg_integer())
    defparser uint(n, endianness) in p do
        map(bits(n), fn(bin) ->
            case endianness do
                :be -> <<b :: size(n)>> = bin
                :le -> <<b :: size(n)-little>> = bin
            end

            b
        end).(p)
    end

    @doc """
    Parses a signed `n`-bit integer encoded with the given `endianness`.
    """
    @spec sint(pos_integer(), :be | :le) ::
          ExParsec.t(term(), integer())
    defparser sint(n, endianness) in p do
        map(bits(n), fn(bin) ->
            case endianness do
                :be -> <<b :: signed-size(n)>> = bin
                :le -> <<b :: signed-size(n)-little>> = bin
            end

            b
        end).(p)
    end

    @doc """
    Parses an `n`-bit floating point value.
    """
    @spec float(32 | 64) :: ExParsec.t(term(), float())
    defparser float(n) in p do
        map(bits(n), fn(<<b :: float-size(n)>>) -> b end).(p)
    end
end
