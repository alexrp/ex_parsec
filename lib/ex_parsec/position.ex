defmodule ExParsec.Position do
    @moduledoc """
    Represents a position in source code text.

    * `index` is the zero-based index into the file.
    * `line` is the one-based line number.
    * `column` is the one-based column number.

    Position tracking is done at the granularity of UTF-8 codepoints.
    """

    defstruct index: 0,
              line: 1,
              column: 1

    @typedoc """
    The type of an `ExParsec.Position` instance.
    """
    @type t() :: %__MODULE__{index: non_neg_integer(),
                             line: pos_integer(),
                             column: pos_integer()}

    @doc """
    Checks if `value` is an `ExParsec.Position` instance.
    """
    @spec position?(term()) :: boolean()
    def position?(value) do
        match?(%__MODULE__{}, value)
    end
end
