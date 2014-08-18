defmodule ExParsec.Text do
    @moduledoc """
    Provides common parsers that operate on text.
    """

    import ExParsec.Base
    import ExParsec.Helpers

    alias ExParsec.Parser

    @doc """
    Parses a codepoint. Returns the codepoint as result.
    """
    @spec any_char() :: ExParsec.t(term(), String.codepoint())
    defparser any_char() in p do
        case Parser.get(p) do
            {:error, r} -> failure([error(p, :io, "encountered I/O error: #{inspect(r)}")])
            :eof -> failure([error(p, :eof, "expected a character but encountered end of file")])
            {p, cp} -> success(p, cp)
        end
    end

    @doc """
    Expects and parses a codepoint that satisfies the criteria required by
    `function`. `name` is used for error message generation.
    """
    @spec satisfy(String.t(), ((String.codepoint()) -> boolean())) ::
          ExParsec.t(term(), String.codepoint())
    defparser satisfy(name, function) in p do
        r = any_char().(p)

        if r.status == :ok do
            cp = r.result

            if function.(cp) do
                r
            else
                failure([error(p, :expected_char, "expected #{name} but found #{inspect(cp)}")])
            end
        else
            r
        end
    end

    @doc """
    Expects and parses the given `codepoint`. On success, returns the codepoint
    as result.
    """
    @spec char(String.codepoint()) :: ExParsec.t(term(), String.codepoint())
    defparser char(codepoint) in p do
        satisfy(inspect(codepoint), fn(c) -> c == codepoint end).(p)
    end

    @doc """
    Expects and parses a codepoint that's present in `codepoints`, which can
    either be a list of codepoints, or a string that's converted to a list of
    codepoints.
    """
    @spec one_of([String.codepoint()] | String.t()) ::
          ExParsec.t(term(), String.codepoint())
    defparser one_of(codepoints) in p do
        if is_binary(codepoints) do
            codepoints = String.codepoints(codepoints)
        end

        name = codepoints |>
               Enum.map(&inspect/1) |>
               Enum.join(", ")

        satisfy(name, fn(c) -> c in codepoints end).(p)
    end

    @doc """
    The opposite of `one_of/1`: Expects a codepoint that's *not* in
    `codepoints`. Otherwise, works like `one_of/1`.
    """
    @spec none_of([String.codepoint()] | String.t()) ::
          ExParsec.t(term(), String.codepoint())
    defparser none_of(codepoints) in p do
        if is_binary(codepoints) do
            codepoints = String.codepoints(codepoints)
        end

        name = codepoints |>
               Enum.map(&inspect/1) |>
               Enum.join(", ")

        satisfy(name, fn(c) -> !(c in codepoints) end).(p)
    end

    @doc """
    Expects and parses any white space character.
    """
    @spec space() :: ExParsec.t(term(), String.codepoint())
    defparser space() in p do
        satisfy("any white space character", fn(c) -> String.strip(c) == "" end).(p)
    end

    @doc """
    Expects and parses a tab (`"\t"`) character.
    """
    @spec tab() :: ExParsec.t(term(), String.codepoint())
    defparser tab() in p do
        satisfy(inspect("\t"), fn(c) -> c == "\t" end).(p)
    end

    @doc """
    Expects and parses a newline sequence. This can either be a `"\n"` or a
    `"\r"` followed by `"\n"`. Either way, returns `"\n"` as result.
    """
    @spec newline() :: ExParsec.t(term(), String.codepoint())
    defparser newline() in p do
        bind(option(char("\r")), fn(_) -> char("\n") end).(p)
    end

    @doc """
    Expects and parses any letter in `?a .. ?z`.
    """
    @spec lower() :: ExParsec.t(term(), String.codepoint())
    defparser lower() in p do
        satisfy("any lower case letter", fn(<<c :: utf8>>) ->
            c in ?a .. ?z
        end).(p)
    end

    @doc """
    Expects and parses any letter in `?A .. ?Z`.
    """
    @spec upper() :: ExParsec.t(term(), String.codepoint())
    defparser upper() in p do
        satisfy("any upper case letter", fn(<<c :: utf8>>) ->
            c in ?A .. ?Z
        end).(p)
    end

    @doc """
    Expects and parses any letter in `?A .. ?Z` and `?a .. ?z`.
    """
    @spec letter() :: ExParsec.t(term(), String.codepoint())
    defparser letter() in p do
        either(lower(), upper()).(p)
    end

    @doc """
    Expects and parses any digit in `?0 .. ?1`.
    """
    @spec bin_digit() :: ExParsec.t(term(), String.codepoint())
    defparser bin_digit() in p do
        satisfy("any binary digit", fn(<<c :: utf8>>) ->
            c in ?0 .. ?1
        end).(p)
    end

    @doc """
    Expects and parses any digit in `?0 .. ?7`.
    """
    @spec oct_digit() :: ExParsec.t(term(), String.codepoint())
    defparser oct_digit() in p do
        satisfy("any octal digit", fn(<<c :: utf8>>) ->
            c in ?0 .. ?7
        end).(p)
    end

    @doc """
    Expects and parses any digit in `?0 .. ?9`.
    """
    @spec digit() :: ExParsec.t(term(), String.codepoint())
    defparser digit() in p do
        satisfy("any decimal digit", fn(<<c :: utf8>>) ->
            c in ?0 .. ?9
        end).(p)
    end

    @doc """
    Expects and parses any digit in `?0 .. ?9`, `?A .. ?F`, and `?a .. ?f`.
    """
    @spec hex_digit() :: ExParsec.t(term(), String.codepoint())
    defparser hex_digit() in p do
        satisfy("any hexadecimal digit", fn(<<c :: utf8>>) ->
            c in ?0 .. ?9 || c in ?A .. ?F || c in ?a .. ?f
        end).(p)
    end

    @doc """
    Expects and parses any alphanumeric character (i.e. `?A .. ?Z`, `?a .. ?z`,
    and `?0 .. ?9`).
    """
    defparser alphanumeric() in p do
        either(letter(), digit()).(p)
    end

    @doc """
    Expects and parses the given `string`. On success, returns the string as
    result.
    """
    @spec string(String.t()) :: ExParsec.t(term(), String.t())
    defparser string(string) in p do
        sz = length(String.codepoints(string))

        loop = fn(loop, accp, acc) ->
            cond do
                acc == string -> success(accp, acc)
                length(String.codepoints(acc)) >= sz ->
                    failure([error(p, :expected_string, "expected #{inspect(string)} but found #{inspect(acc)}")])
                true ->
                    case Parser.get(accp) do
                        {:error, r} ->
                            failure([error(accp, :io, "Encountered I/O error: #{inspect(r)}")])
                        :eof ->
                            failure([error(accp, :eof, "expected #{inspect(string)} but encountered end of file")])
                        {accp, cp} -> loop.(loop, accp, acc <> cp)
                    end
            end
        end

        loop.(loop, p, "")
    end

    @doc """
    Parses as many white space characters as possible.
    """
    @spec spaces() :: ExParsec.t(term(), [String.codepoint()])
    defparser spaces() in p do
        many(space()).(p)
    end
end
