defprotocol ExParsec.Input do
    @moduledoc """
    Represents a source of input data for parser functions.

    This protocol should be implemented for types that can be used to feed data
    (codepoints or tokens) to parser functions. Note that an implementation
    must only emit one kind of input data, not both.

    This is a relatively low-level interface that doesn't even provide position
    tracking. In general, beyond implementing this protocol, you should not be
    using it.
    """

    alias ExParsec.Token

    @doc """
    Fetches a codepoint or token from the input. If no more data is available,
    `:eof` is returned. If an invalid codepoint or token is encountered, a
    tuple containing `:error` and a reason is returned. Otherwise, returns a
    tuple containing the advanced input and the codepoint/token.
    """
    @spec get(t()) :: {t(), String.codepoint() | Token.t()} | {:error, term()} | :eof
    def get(input)
end
