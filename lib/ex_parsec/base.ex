defmodule ExParsec.Base do
    @moduledoc """
    Provides fundamental combinators and parsers.
    """

    import ExParsec.Macro

    alias ExParsec.Error
    alias ExParsec.Input
    alias ExParsec.Parser
    alias ExParsec.Position
    alias ExParsec.Reply

    # Helpers

    @doc """
    Constructs a successful `ExParsec.Reply` with `result` as the result value.
    `errors` can optionally be used to propagate error messages, if any.
    """
    @spec success(Parser.t(state), result, [Error.t()]) ::
          Reply.t(state, result) when [state: var, result: var]
    def success(parser, result, errors \\ []) do
        %Reply{parser: parser,
               errors: errors,
               result: result}
    end

    @doc """
    Constructs an unsuccessful `ExParsec.Reply` with `status` (either `:error`
    or `:fatal`) as the error kind and `errors` as the list of errors.
    """
    @spec failure(:error | :fatal, [Error.t()]) ::
          Reply.t(term(), nil) when [state: var, result: var]
    def failure(status \\ :error, errors) do
        %Reply{status: status,
               errors: errors}
    end

    @doc """
    Constructs an `ExParsec.Error` with the given `message` and the current
    position from `parser`.
    """
    @spec error(Parser.t(term()), String.t()) :: Error.t() when [state: var]
    def error(parser, message) do
        %Error{message: message,
               position: parser.position}
    end

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
        if Input.get(p.input) == :eof do
            success(p, nil)
        else
            failure([error(p, "expected end of file")])
        end
    end

    # Combinators

    @doc """
    Applies `parser` if possible. Returns a tuple containing `:ok` and the
    result, or `nil` if `parser` could not be applied.
    """
    @spec optional(ExParsec.t(state, result)) :: ExParsec.t(state, {:ok, result} | nil)
          when [state: var, result: var]
    defparser optional(parser) in p do
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
    Applies each parser in 	`parsers`. Passes all result values in a list to
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
    Applies `parser1` and `parser2` in sequence. Returns the result of
    `parser1`.
    """
    @spec pair_left(ExParsec.t(state, result), ExParsec.t(state, term())) ::
          ExParsec.t(state, result) when [state: var, result: var]
    defparser pair_left(parser1, parser2) in p do
        r = sequence([parser1, parser2]).(p)

        if r.status == :ok do
            %Reply{r | :result => hd(r.result)}
        else
            r
        end
    end

    @doc """
    Applies `parser1` and `parser2` in sequence. Returns the result of
    `parser2`.
    """
    @spec pair_right(ExParsec.t(state, term()), ExParsec.t(state, result)) ::
          ExParsec.t(state, result) when [state: var, result: var]
    defparser pair_right(parser1, parser2) in p do
        r = sequence([parser1, parser2]).(p)

        if r.status == :ok do
            %Reply{r | :result => hd(tl(r.result))}
        else
            r
        end
    end

    @doc """
    Applies `parser1`, `parser2`, and `parser3` in sequence. Returns the result
    of `parser2`.
    """
    @spec between(ExParsec.t(state, term()), ExParsec.t(state, result),
                  ExParsec.t(state, term())) :: ExParsec.t(state, result)
          when [state: var, result: var]
    defparser between(parser1, parser2, parser3) in p do
        r = sequence([parser1, parser2, parser3]).(p)

        if r.status == :ok do
            %Reply{r | :result => hd(tl(r.result))}
        else
            r
        end
    end

    @doc """
    Applies `parser1` and `parser2` in sequence. Returns the result of
    both parsers as a tuple.
    """
    @spec pair_both(ExParsec.t(state, result1), ExParsec.t(state, result2)) ::
          ExParsec.t(state, {result1, result2})
          when [state: var, result1: var, result2: var]
    defparser pair_both(parser1, parser2) in p do
        r = sequence([parser1, parser2]).(p)

        if r.status == :ok do
            %Reply{r | :result => List.to_tuple(r.result)}
        else
            r
        end
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
            r = parser.(p)
            errs = List.flatten([r.errors | errs])

            case r.status do
                :ok -> loop.(loop, r.parser, Enum.reverse([r.result | ress]), errs)
                :error -> success(p, ress, errs)
                :fatal -> %Reply{r | :errors => errs}
            end
        end

        loop.(loop, p, [], [])
    end

    # Parsers
end