defmodule ExParsec.Input.BinaryInput do
    @moduledoc """
    Provides data from an in-memory bitstring.

    * `value` is the input bitstring.
    """

    defstruct value: nil

    @typedoc """
    The type of an `ExParsec.Input.BinaryInput` instance.
    """
    @type t() :: %__MODULE__{value: bitstring()}

    @doc """
    Checks if `value` is an `ExParsec.Input.BinaryInput` instance.
    """
    @spec binary_input?(term()) :: boolean()
    def binary_input?(value) do
        match?(%__MODULE__{}, value)
    end
end

defimpl ExParsec.Input, for: ExParsec.Input.BinaryInput do
    alias ExParsec.Input.BinaryInput

    @spec get(BinaryInput.t(), Keyword.t()) :: {BinaryInput.t(), bitstring()} | :eof
    def get(input, opts) do
        n = opts[:n] || 1

        case input.value do
            <<b :: bitstring-size(n), r :: bitstring>> ->
                {%BinaryInput{value: r}, b}
            _ -> :eof
        end
    end
end
