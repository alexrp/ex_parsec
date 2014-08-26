defmodule ExParsec.Input.MemoryInput do
    @moduledoc """
    Provides data from an in-memory UTF-8 string, a list of tokens, a list of
    any arbitrary term type, or from a bitstring.

    * `value` is the binary containing the encoded string, list of terms, or
      bitstring.
    * `is_string` indicates whether `value` is a string or something else. This
      is needed to disambiguate since strings and bitstrings are the same type.
      This should be `false` if `value` is not a bitstring.
    """

    defstruct value: nil,
              is_string: true

    @typedoc """
    The type of an `ExParsec.Input.MemoryInput` instance.
    """
    @type t() :: %__MODULE__{value: bitstring() | [term()],
                             is_string: boolean()}

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

    @spec get(MemoryInput.t(), Keyword.t()) :: {MemoryInput.t(), term()} |
                                               {:error, term()} | :eof
    def get(input, opts) do
        cond do
            is_list(input.value) ->
                case input.value do
                    [h | t] -> {%MemoryInput{input | :value => t}, h}
                    [] -> :eof
                end
            input.is_string ->
                case String.next_codepoint(input.value) do
                    {cp, r} ->
                        if String.valid_character?(cp) do
                            {%MemoryInput{input | :value => r}, cp}
                        else
                            {:error, :noncharacter}
                        end
                    nil -> :eof
                end
            true ->
                n = opts[:n] || 1

                case input.value do
                    <<b :: bitstring-size(n), r :: bitstring>> ->
                        {%MemoryInput{input | :value => r}, b}
                    _ -> :eof
                end
        end
    end
end
