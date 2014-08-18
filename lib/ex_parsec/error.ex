defmodule ExParsec.Error do
    @moduledoc """
    Represents a parse error encountered when executing a parser function.

    * `message` is the error message.
    * `kind` is the error kind. `nil` if the error doesn't fit into the list
      of standard error kinds.
    * `position` is the position in the input data where the error occurred.
      Can be `nil` if the input doesn't support position tracking.
    """

    alias ExParsec.Position

    defstruct message: nil,
              kind: nil,
              position: nil

    @typedoc """
    The type of an `ExParsec.Error` instance.
    """
    @type t() :: %__MODULE__{message: String.t(),
                             kind: kind(),
                             position: Position.t() | nil}

    @typedoc """
    The various error kinds.
    """
    @type kind() :: nil |
                    :io |
                    :expected |
                    :expected_eof |
                    :expected_char |
                    :expected_string

    @doc """
    Checks if `value` is an `ExParsec.Error` instance.
    """
    @spec error?(term()) :: boolean()
    def error?(value) do
        match?(%__MODULE__{}, value)
    end
end
