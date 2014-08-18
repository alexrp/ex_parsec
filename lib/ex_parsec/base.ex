defmodule ExParsec.Base do
    @moduledoc """
    Provides fundamental combinators and parsers.
    """

    import ExParsec.Helpers

    alias ExParsec.Input
    alias ExParsec.Parser
    alias ExParsec.Position
    alias ExParsec.Reply

    # State

    @doc """
    Returns the user state as result.
    """
    @spec get_state() :: ExParsec.t(term(), term())
    defparser get_state() in p do
        success(p, p.state)
    end

    @doc """
    Sets the user state to `state`.
    """
    @spec set_state(state) :: ExParsec.t(state, nil) when [state: var]
    defparser set_state(state) in p do
        success(%Parser{p | :state => state}, nil)
    end

    @doc """
    Updates the user state by applying `updater` to it.
    """
    @spec update_state(((state) -> state)) :: ExParsec.t(state, nil) when [state: var]
    defparser update_state(updater) in p do
        success(%Parser{p | :state => updater.(p.state)}, nil)
    end

    @doc """
    Returns the current position as result.
    """
    @spec get_position() :: ExParsec.t(term(), Position.t())
    defparser get_position() in p do
        success(p, p.position)
    end

    # Primitives

    @doc """
    Returns `value` as result.
    """
    @spec return(value) :: ExParsec.t(term(), value) when [value: var]
    defparser return(value) in p do
        success(p, value)
    end

    @doc """
    Fails without an error message.
    """
    @spec zero() :: ExParsec.t(term(), nil)
    defparser zero() in _ do
        failure([])
    end

    @doc """
    Fails with the given error `message`.
    """
    @spec fail(String.t()) :: ExParsec.t(term(), nil)
    defparser fail(message) in p do
        failure([error(p, message)])
    end

    @doc """
    Fails fatally with the given error `message`.
    """
    @spec fail_fatal(String.t()) :: ExParsec.t(term(), nil)
    defparser fail_fatal(message) in p do
        failure(:fatal, [error(p, message)])
    end

    @doc """
    Only succeeds at the end of the input data.
    """
    @spec eof() :: ExParsec.t(term(), nil)
    defparser eof() in p do
        # We can skip `ExParsec.Parser.get/1` since we just need to check for
        # EOF - we don't care about position info.
        if Input.get(p.input) == :eof do
            success(p, nil)
        else
            failure([error(p, :expected_eof, "expected end of file")])
        end
    end

    # Combinators

    @doc """
    Applies `parser` and passes its result to `function`. `function`'s return
    value is returned as the result.
    """
    @spec map(ExParsec.t(state, result1), ((result1) -> result2)) ::
          ExParsec.t(state, result2)
          when [state: var, result1: var, result2: var]
    defparser map(parser, function) in p do
        pipe([parser], fn([r]) -> function.(r) end).(p)
    end

    @doc """
    Applies `parser` and discards its result.
    """
    @spec ignore(ExParsec.t(state, term())) :: ExParsec.t(state, nil)
          when [state: var]
    defparser ignore(parser) in p do
        map(parser, fn(_) -> nil end).(p)
    end

    @doc """
    Applies `parser` and passes its result as the only argument to `function`.
    `function` is expected to return a parser. That parser is then applied and
    its result is returned.
    """
    @spec bind(ExParsec.t(state, result1), ((result1) -> ExParsec.t(state, result2))) ::
          ExParsec.t(state, result2) when [state: var, result1: var, result2: var]
    defparser bind(parser, function) in p do
        r1 = parser.(p)

        if r1.status == :ok do
            parser2 = function.(r1.result)
            r2 = parser2.(r1.parser)
            errs = List.flatten([r2.errors | r1.errors])

            %Reply{r2 | :errors => errs}
        else
            r1
        end
    end

    @doc """
    Applies `parser` if possible. Returns a tuple containing `:ok` and the
    result, or `nil` if `parser` could not be applied.
    """
    @spec option(ExParsec.t(state, result)) :: ExParsec.t(state, {:ok, result} | nil)
          when [state: var, result: var]
    defparser option(parser) in p do
        r = parser.(p)

        case r.status do
            :ok -> %Reply{r | :result => {:ok, r.result}}
            :error -> success(p, nil, r.errors)
            :fatal -> r
        end
    end

    @doc """
    Identical to applying `parser` normally, except that if applying `parser`
    results in a fatal error, it will be turned into a regular error.
    """
    @spec attempt(ExParsec.t(state, result)) :: ExParsec.t(state, result)
          when [state: var, result: var]
    defparser attempt(parser) in p do
        r = parser.(p)

        if r.status == :ok do
            r
        else
            failure(r.errors)
        end
    end

    @doc """
    First tries to apply `parser1`. If that fails, tries to apply `parser2`. If
    that fails, this combinator fails. Otherwise, returns the first successful
    result value obtained.
    """
    @spec either(ExParsec.t(state, term()), ExParsec.t(state, term())) ::
          ExParsec.t(state, term()) when [state: var]
    defparser either(parser1, parser2) in p do
        choice([parser1, parser2]).(p)
    end

    @doc """
    Tries to apply each parser in `parsers` until one succeeds. This is a
    variant of `either/2` generalized for any number of parsers.
    """
    @spec choice([ExParsec.t(state, term()), ...]) ::
          ExParsec.t(state, term()) when [state: var]
    defparser choice(parsers) in p do
        try do
            errs = Enum.reduce(parsers, [], fn(parser, errs) ->
                r = parser.(p)
                errs = List.flatten([r.errors | errs])

                if r.status in [:ok, :fatal] do
                    throw(%Reply{r | :errors => errs})
                end

                errs
            end)

            failure(errs)
        catch
            :throw, r -> r
        end
    end

    @doc """
    Applies each parser in `parsers`. Passes all result values in a list to
    `function`. `function`'s return value is returned as the result.
    """
    @spec pipe([ExParsec.t(state, term())], (([term()]) -> result)) ::
          ExParsec.t(state, result) when [state: var, result: var]
    defparser pipe(parsers, function) in p do
        try do
            {p, errs, ress} = Enum.reduce(parsers, {p, [], []}, fn(parser, acc) ->
                {p, errs, ress} = acc

                r = parser.(p)
                errs = List.flatten([r.errors | errs])

                if r.status != :ok do
                    throw(%Reply{r | :errors => errs})
                end

                {r.parser, errs, [r.result | ress]}
            end)

            res = function.(Enum.reverse(ress))

            success(p, res, errs)
        catch
            :throw, r -> r
        end
    end

    @doc """
    Applies each parser in `parsers`. Returns all results in a list.
    """
    @spec sequence([ExParsec.t(state, term())]) :: ExParsec.t(state, term())
          when [state: var]
    defparser sequence(parsers) in p do
        pipe(parsers, fn(list) -> list end).(p)
    end

    @doc """
    Applies `parser1` and `parser2` in sequence. Passes the result values as
    two arguments to `function`. `function`'s return value is returned as the
    result.
    """
    @spec both(ExParsec.t(state, result1), ExParsec.t(state, result2),
               ((result1, result2) -> result3)) :: ExParsec.t(state, result3)
          when [state: var, result1: var, result2: var, result3: var]
    defparser both(parser1, parser2, function) in p do
        pipe([parser1, parser2], fn([a, b]) -> function.(a, b) end).(p)
    end

    @doc """
    Applies `parser1` and `parser2` in sequence. Returns the result of
    `parser1`.
    """
    @spec pair_left(ExParsec.t(state, result), ExParsec.t(state, term())) ::
          ExParsec.t(state, result) when [state: var, result: var]
    defparser pair_left(parser1, parser2) in p do
        both(parser1, parser2, fn(a, _) -> a end).(p)
    end

    @doc """
    Applies `parser1` and `parser2` in sequence. Returns the result of
    `parser2`.
    """
    @spec pair_right(ExParsec.t(state, term()), ExParsec.t(state, result)) ::
          ExParsec.t(state, result) when [state: var, result: var]
    defparser pair_right(parser1, parser2) in p do
        both(parser1, parser2, fn(_, b) -> b end).(p)
    end

    @doc """
    Applies `parser1` and `parser2` in sequence. Returns the result of
    both parsers as a tuple.
    """
    @spec pair_both(ExParsec.t(state, result1), ExParsec.t(state, result2)) ::
          ExParsec.t(state, {result1, result2})
          when [state: var, result1: var, result2: var]
    defparser pair_both(parser1, parser2) in p do
        both(parser1, parser2, fn(a, b) -> {a, b} end).(p)
    end

    @doc """
    Applies `parser1`, `parser2`, and `parser3` in sequence. Returns the result
    of `parser2`.
    """
    @spec between(ExParsec.t(state, term()), ExParsec.t(state, result),
                  ExParsec.t(state, term())) :: ExParsec.t(state, result)
          when [state: var, result: var]
    defparser between(parser1, parser2, parser3) in p do
        pipe([parser1, parser2, parser3], fn([_, b, _]) -> b end).(p)
    end

    @doc """
    Applies `parser` to the input data `n` times. Returns results in a list.
    """
    @spec times(ExParsec.t(state, result), non_neg_integer()) ::
          ExParsec.t(state, [result]) when [state: var, result: var]
    defparser times(parser, n) in p do
        if n == 0 do
            success(p, [])
        else
            try do
                {p, errs, ress} = Enum.reduce(1 .. n, {p, [], []}, fn(_, acc) ->
                    {p, errs, ress} = acc

                    r = parser.(p)
                    errs = List.flatten([r.errors | errs])

                    if r.status != :ok do
                        throw(%Reply{r | :errors => errs})
                    end

                    {r.parser, errs, [r.result | ress]}
                end)

                success(p, Enum.reverse(ress), errs)
            catch
                :throw, r -> r
            end
        end
    end

    @doc """
    Applies `parser` as many times as possible. Returns all results in a list.
    """
    @spec many(ExParsec.t(state, result)) :: ExParsec.t(state, [result])
          when [state: var, result: var]
    defparser many(parser) in p do
        loop = fn(loop, p, ress, errs) ->
            # We can skip `ExParsec.Parser.get/1` since we just need to check for
            # EOF - we don't care about position info.
            if Input.get(p.input) == :eof do
                success(p, Enum.reverse(ress), errs)
            else
                r = parser.(p)
                errs = List.flatten([r.errors | errs])

                case r.status do
                    :ok -> loop.(loop, r.parser, [r.result | ress], errs)
                    :error -> success(p, Enum.reverse(ress), errs)
                    :fatal -> %Reply{r | :errors => errs}
                end
            end
        end

        loop.(loop, p, [], [])
    end

    @doc """
    Applies `parser` if possible. Discards the result.
    """
    @spec skip(ExParsec.t(state, term())) :: ExParsec.t(state, nil)
          when [state: var]
    defparser skip(parser) in p do
        # TODO: Optimize this so we don't build up a ton of data.
        ignore(option(parser)).(p)
    end

    @doc """
    Applies `parser` as many times as possible. Discards the results.
    """
    @spec skip_many(ExParsec.t(state, term())) :: ExParsec.t(state, nil)
          when [state: var]
    defparser skip_many(parser) in p do
        # TODO: Optimize this so we don't build up a ton of data.
        ignore(many(parser)).(p)
    end

    # Parsers

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
    Expects and parses any letter in `?A .. ?Z` or `?a .. ?z`.
    """
    @spec letter() :: ExParsec.t(term(), String.codepoint())
    defparser letter() in p do
        either(lower(), upper()).(p)
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
