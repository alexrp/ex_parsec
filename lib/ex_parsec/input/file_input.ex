defmodule ExParsec.Input.FileInput do
    @moduledoc """
    Provides data from an I/O device in UTF-8 mode.

    * `device` is the I/O device.
    * `position` is the current position in the device.
    """

    defstruct device: nil,
              position: 0

    @typedoc """
    The type of an `ExParsec.Input.FileInput` instance.
    """
    @type t() :: %__MODULE__{device: File.io_device(),
                             position: non_neg_integer()}

    @doc """
    Checks if `value` is an `ExParsec.Input.FileInput` instance.
    """
    @spec file_input?(term()) :: boolean()
    def file_input?(value) do
        match?(%__MODULE__{}, value)
    end
end

defimpl ExParsec.Input, for: ExParsec.Input.FileInput do
    alias ExParsec.Input.FileInput

    @spec get(FileInput.t(), Keyword.t()) :: {FileInput.t(), String.codepoint()} |
                                             {:error, term()} | :eof
    def get(input, _) do
        {:ok, pos} = :file.position(input.device, input.position)

        case IO.read(input.device, 1) do
            {:error, r} -> {:error, r}
            :eof -> :eof
            cp ->
                if String.valid_character?(cp) do
                    {%FileInput{input | :position => pos + byte_size(cp)}, cp}
                else
                    {:error, :noncharacter}
                end
        end
    end
end
