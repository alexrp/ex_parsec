defmodule ExParsec do
    @moduledoc """
    A parser combinator library inspired by Parsec.

    This module provides convenient entry point functions for running parsers.

    This module can also be `use`d. Doing so `import`s the following modules:

    * `ExParsec`
    * `ExParsec.Base`
    * `ExParsec.Macro`

    It will also `alias` the following modules:

    * `ExParsec.Error`
    * `ExParsec.Input`
    * `ExParsec.Parser`
    * `ExParsec.Position`
    * `ExParsec.Reply`
    """

    alias ExParsec.Error
    alias ExParsec.Input.FileInput
    alias ExParsec.Input.MemoryInput
    alias ExParsec.Input
    alias ExParsec.Parser
    alias ExParsec.Reply

    @doc false
    defmacro __using__(_) do
        quote do
            import ExParsec
            import ExParsec.Base
            import ExParsec.Macro

            alias ExParsec.Error
            alias ExParsec.Input
            alias ExParsec.Parser
            alias ExParsec.Position
            alias ExParsec.Reply
        end
    end

    @typedoc """
    The type of a parser function.

    A parser function receives the `ExParsec.Parser` instance as its first and
    only argument. It is expected to return an `ExParsec.Reply` instance that
    describes the result of applying the function.
    """
    @type t(state, result) :: ((Parser.t(state)) -> {Reply.t(state, result)})

    @doc """
    Parses the given `input` by applying the parser `function` to it. `state`
    can optionally be given to parse with user state.

    Returns either:

    * A tuple containing `:ok`, the final user state, and the result.
    * A tuple containing `:error` and a list of `ExParsec.Error` instances.
    """
    @spec parse(t(state, result), Input.t(), state) ::
          {:ok, state, result} | {:error, [Error.t()]}
          when [state: var, result: var]
    def parse(function, input, state \\ nil) do
        parser = %Parser{input: input, state: state}
        reply = function.(parser)

        case reply.status do
            :ok -> {:ok, reply.parser.state, reply.result}
            _ ->
                {:error,
                 reply.errors |>
                 Enum.uniq() |>
                 Enum.sort(&(&1.message < &2.message))}
        end
    end

    @doc """
    Constructs an `ExParsec.Input.MemoryInput` instance with the given `string`
    and forwards to `parse/3`.
    """
    @spec parse_string(t(state, result), String.t(), state) ::
          {:ok, state, result} | {:error, [Error.t()]}
          when [state: var, result: var]
    def parse_string(function, string, state \\ nil) do
        parse(function, %MemoryInput{value: string}, state)
    end

    @doc """
    Constructs an `ExParsec.Input.FileInput` instance with the given `device`
    and forwards to `parse/3`.
    """
    @spec parse_file(t(state, result), File.io_device(), state) ::
          {:ok, state, result} | {:error, [Error.t()]}
          when [state: var, result: var]
    def parse_file(function, device, state \\ nil) do
        parse(function, %FileInput{device: device}, state)
    end
end