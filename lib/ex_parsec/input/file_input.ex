defmodule ExParsec.Input.FileInput do
    @moduledoc """
    Provides data from an I/O device in UTF-8 mode.

    * `device` is the I/O device.
    """

    defstruct device: nil

    @typedoc """
    The type of an `ExParsec.Input.FileInput` instance.
    """
    @type t() :: %__MODULE__{device: File.io_device()}

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

    @spec get(FileInput.t()) :: {FileInput.t(), String.codepoint()} | {:error, term()} | :eof
    def get(input) do
        case IO.read(input.device, 1) do
            {:error, r} -> {:error, r}
            :eof -> :eof
            cp ->
                if String.valid_character?(cp) do
                    {input, cp}
                else
                    {:error, :noncharacter}
                end
        end
    end
end
