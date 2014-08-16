defmodule ExParsec.Error do
    @moduledoc """
    Represents a parse error encountered when executing a parser function.

    * `message` is the error message.
    * `position` is the position in the input data where the error occurred.
    """

    alias ExParsec.Position

    defstruct message: nil,
              position: nil

    @typedoc """
    The type of an `ExParsec.Error` instance.
    """
    @type t() :: %__MODULE__{message: String.t(),
                             position: Position.t()}

    @doc """
    Checks if `value` is an `ExParsec.Error` instance.
    """
    @spec error?(term()) :: boolean()
    def error?(value) do
        match?(%__MODULE__{}, value)
    end
end
