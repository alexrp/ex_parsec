defprotocol ExParsec.Input do
    @moduledoc """
    Represents a source of input data for parser functions.

    This protocol should be implemented for types that can be used to feed data
    (codepoints) to parser functions.

    This is a relatively low-level interface that doesn't even provide position
    tracking. In general, beyond implementing this protocol, you should not be
    using it.
    """

    @doc """
    Fetches a codepoint from the input. If there are no more codepoints in the
    input, `:eof` is returned. If an invalid codepoint is encountered, a tuple
    containing `:error` and a reason is returned. Otherwise, returns a tuple
    containing the advanced input and the codepoint.
    """
    @spec get(t()) :: {t(), String.codepoint()} | {:error, term()} | :eof
    def get(input)
end
