defmodule ExParsec.Token do
    @moduledoc """
    Represents an input token.

    * `position` is the token's position in the source text.
    * `data` is any data associated with the token.

    Tokens are commonly emitted by an initial lexing/tokenization pass and then
    consumed by the actual parsing pass.
    """

    alias ExParsec.Position

    defstruct position: nil,
              data: nil

    @typedoc """
    The type of an `ExParsec.Token` instance.
    """
    @type t(data) :: %__MODULE__{position: Position.t(),
                                 data: data}

    @doc """
    Checks if `value` is an `ExParsec.Token` instance.
    """
    @spec token?(term()) :: boolean()
    def token?(value) do
        match?(%__MODULE__{}, value)
    end
end
