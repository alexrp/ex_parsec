defprotocol ExParsec.Input do
    @moduledoc """
    Represents a source of input data for parser functions.

    This protocol should be implemented for types that can be used to feed data
    (codepoints, tokens, etc) to parser functions. Note that an implementation
    must only emit one kind of input data, not several.

    This is a relatively low-level interface that doesn't even provide position
    tracking. In general, beyond implementing this protocol, you should not be
    using it.
    """

    @doc """
    Fetches data from the input. If no more data is available, `:eof` is
    returned. If invalid input data is encountered, a tuple containing `:error`
    and a reason is returned. Otherwise, returns a tuple containing the
    advanced input and the fetched data.

    `opts` can be used for implementation-specific options.
    """
    @spec get(t()) :: {t(), term()} | {:error, term()} | :eof
    def get(input, opts \\ [])
end
