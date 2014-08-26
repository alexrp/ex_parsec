defmodule ExParsec do
    @moduledoc """
    A parser combinator library inspired by Parsec.

    This module provides convenient entry point functions for running parsers.

    This module can also be `use`d. Doing so `import`s the following modules:

    * `ExParsec`
    * `ExParsec.Base`
    * `ExParsec.Helpers`

    It will also `require` the following modules:

    * `ExParsec.Monad.Parse`

    It will also `alias` the following modules:

    * `ExParsec.Error`
    * `ExParsec.Input`
    * `ExParsec.Monad.Parse`
    * `ExParsec.Parser`
    * `ExParsec.Position`
    * `ExParsec.Reply`

    A `:mode` option can be given, indicating which module containing common
    parsers should be `import`ed. Currently, `Text` and `Binary` are valid
    values for this option. If the option isn't given, `Text` is the default.
    `nil` may be given to not `import` any module. The mode must given as a
    compile-time literal.

    Examples:

        defmodule TextParsing do
            use ExParsec

            # ...
        end

        defmodule BinaryParsing do
            use ExParsec, mode: Binary

            # ...
        end

        defmodule TokenParsing do
            use ExParsec, mode: nil

            # ...
        end
    """

    alias ExParsec.Error
    alias ExParsec.Input.FileInput
    alias ExParsec.Input.MemoryInput
    alias ExParsec.Input
    alias ExParsec.Parser
    alias ExParsec.Position
    alias ExParsec.Reply

    @doc false
    defmacro __using__(opts) do
        mod = Module.concat(ExParsec, Macro.expand(opts[:mode], __ENV__) || Text)

        quote do
            import ExParsec
            import ExParsec.Base
            import ExParsec.Helpers

            import unquote(mod)

            require ExParsec.Monad.Parse

            alias ExParsec.Error
            alias ExParsec.Input
            alias ExParsec.Monad.Parse
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
    can optionally be given to parse with user state. `position` defines the
    initial input position. By default, it's set to a default-initialized
    `ExParsec.Position` instance. It should be `nil` for non-text, non-token
    inputs.

    Returns either:

    * A tuple containing `:ok`, the final user state, and the result.
    * A tuple containing `:error` and a list of `ExParsec.Error` instances.
    """
    @spec parse(Input.t(), t(state, result), Position.t() | nil, state) ::
          {:ok, state, result} | {:error, [Error.t()]}
          when [state: var, result: var]
    def parse(input, function, state \\ nil, position \\ %Position{}) do
        parser = %Parser{input: input, position: position, state: state}
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
    Constructs an `ExParsec.Input.MemoryInput` instance with the given `value`
    (a string or list of codepoints) and forwards to `parse/4`.
    """
    @spec parse_text(String.t() | [String.codepoint()], t(state, result), state) ::
          {:ok, state, result} | {:error, [Error.t()]}
          when [state: var, result: var]
    def parse_text(value, function, state \\ nil) do
        parse(%MemoryInput{value: value}, function, state)
    end

    @doc """
    Constructs an `ExParsec.Input.MemoryInput` instance with the given `value`
    (a bitstring) and forwards to `parse/4`.
    """
    @spec parse_bitstring(bitstring(), t(state, result), state) ::
          {:ok, state, result} | {:error, [Error.t()]}
          when [state: var, result: var]
    def parse_bitstring(value, function, state \\ nil) do
        parse(%MemoryInput{value: value, is_string: false}, function, state, nil)
    end

    @doc """
    Constructs an `ExParsec.Input.MemoryInput` instance with the given `list`
    of terms (e.g. tokens) and forwards to `parse/4`.
    """
    @spec parse_terms([term()], t(state, result), state) ::
          {:ok, state, result} | {:error, [Error.t()]}
          when [state: var, result: var]
    def parse_terms(list, function, state \\ nil) do
        parse(%MemoryInput{value: list, is_string: false}, function, state, nil)
    end

    @doc """
    Constructs an `ExParsec.Input.FileInput` instance with the given `device`
    and forwards to `parse/4`.
    """
    @spec parse_file(File.io_device(), t(state, result), state) ::
          {:ok, state, result} | {:error, [Error.t()]}
          when [state: var, result: var]
    def parse_file(device, function, state \\ nil) do
        parse(%FileInput{device: device}, function, state)
    end
end
