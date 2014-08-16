defmodule ExParsec.Input.MemoryInput do
    @moduledoc """
    Provides data from an in-memory UTF-8 string.

    * `value` is the binary containing the encoded string.
    """

    defstruct value: nil

    @typedoc """
    The type of an `ExParsec.Input.MemoryInput` instance.
    """
    @type t() :: %__MODULE__{value: String.t()}

    @doc """
    Checks if `value` is an `ExParsec.Input.MemoryInput` instance.
    """
    @spec memory_input?(term()) :: boolean()
    def memory_input?(value) do
        match?(%__MODULE__{}, value)
    end
end

defimpl ExParsec.Input, for: ExParsec.Input.MemoryInput do
    alias ExParsec.Input.MemoryInput

    @spec get(MemoryInput.t()) :: {MemoryInput.t(), String.codepoint()} | {:error, term()} | :eof
    def get(input) do
        case String.next_codepoint(input.value) do
            {cp, r} ->
                if String.valid_character?(cp) do
                    {%MemoryInput{value: r}, cp}
                else
                    {:error, :noncharacter}
                end
            nil -> :eof
        end
    end
end
