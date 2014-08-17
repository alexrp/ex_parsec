defmodule ExParsec.Helpers do
    @moduledoc """
    Provides utility functions and macros for writing parser functions.
    """

    require ExParsec.Monad.Parse

    alias ExParsec.Error
    alias ExParsec.Monad.Parse
    alias ExParsec.Parser
    alias ExParsec.Reply

    @doc """
    Defines a parser function. This is a convenience macro that eliminates some
    very common syntax noise.

    Example:

        defparser return(value) in p do
            success(p, value)
        end

    The above is equivalent to:

        def return(value) do
            fn(p) ->
                success(p, value)
            end
        end
    """
    defmacro defparser(sig, [do: block]) do
        [call, parg] = elem(sig, 2)

        quote [location: :keep] do
            def unquote(call) do
                fn(unquote(parg)) ->
                    unquote(block)
                end
            end
        end
    end

    @doc """
    Defines a monadic parser function.

    A monadic parser function's body is defined through the
    `ExParsec.Monad.Parse.m/1` macro. Inside such a function, the `<-`
    operator can be used to bind names to parser invocations. Values
    can be returned by using the special `return` macro.

    For example, consider this parser to parse a field declaration in a
    programming language:

        use ExParsec

        defparser field() in p do
            bind(type(), fn(ty) ->
                sequence([skip_many(space),
                          char(":"),
                          skip_many(space),
                          bind(identifier(), fn(id) ->
                              return(%Field{type: ty, name: id})
                          end)])
            end)
        end

    This is quite unwieldy. Modifying this at a later point would be a rather
    complicated matter.

    We can write this in a much more readable and maintainable way with monadic
    syntax:

        use ExParsec

        defmparser field() do
            ty <- type()
            skip_many(space)
            char(":")
            skip_many(space)
            id <- identifier()
            return %Field{type: ty, name: id}
        end

    It's now very clear what the parser is doing. There is virtually no syntax
    noise. Modifying this parser later down the road would also be much easier.
    """
    defmacro defmparser(sig, [do: block]) do
        quote [location: :keep] do
            require ExParsec.Monad.Parse

            def unquote(sig) do
                Parse.m do
                    unquote(block)
                end
            end
        end
    end

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
end
