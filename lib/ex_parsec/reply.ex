defmodule ExParsec.Reply do
    @moduledoc """
    Represents the result of executing a parser function.

    * `parser` is the advanced `ExParsec.Parser` instance. If `status` is not
      `:ok`, this field must be `nil`.
    * `status` is either `:ok` for a successful parse, `:error` for an
      unsuccessful parse, or `:fatal` for an unrecoverable parse error.
    * `errors` is the list of `ExParsec.Error` instances representing any
      errors encountered when running the parser function. This list can
      contain duplicate entries.
    * `result` is whatever result data the parser function returned. If
      `status` is not `:ok`, this field must be `nil`.

    If a parser function returns a `status` value of `:fatal`, the calling
    function must propagate this value further up the call stack such that the
    entire parse operation fails.
    """

    alias ExParsec.Error
    alias ExParsec.Parser

    defstruct parser: nil,
              status: :ok,
              errors: [],
              result: nil

    @typedoc """
    The type of an `ExParsec.Reply` instance.
    """
    @type t(state, result) :: %__MODULE__{parser: Parser.t(state) | nil,
                                          status: :ok | :error | :fatal,
                                          errors: [Error.t()],
                                          result: result}

    @doc """
    Checks if `value` is an `ExParsec.Reply` instance.
    """
    @spec reply?(term()) :: boolean()
    def reply?(value) do
        match?(%__MODULE__{}, value)
    end
end
