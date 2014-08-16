defmodule ExParsec.Macro do
    @moduledoc """
    Provides macros that make writing parsers and combinators easier.
    """

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
end
