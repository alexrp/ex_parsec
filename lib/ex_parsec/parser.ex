defmodule ExParsec.Parser do
    @moduledoc """
    Represents the state of an executing parse session.

    * `input` is the input data.
    * `position` is the current position in the input data.
    * `state` is the current user state.
    """

    alias ExParsec.Input
    alias ExParsec.Position

    defstruct input: nil,
              position: %Position{},
              state: nil

    @typedoc """
    The type of an `ExParsec.Parser` instance.
    """
    @type t(state) :: %__MODULE__{input: Input.t(),
                                  position: Position.t(),
                                  state: state}

    @doc """
    Checks if `value` is an `ExParsec.Parser` instance.
    """
    @spec parser?(term()) :: boolean()
    def parser?(value) do
        match?(%__MODULE__{}, value)
    end

    @doc """
    Fetches a codepoint from the input. If there are no more codepoints in the
    input, `:eof` is returned. If an invalid codepoint is encountered, a tuple
    containing `:error` and a reason is returned. Otherwise, returns a tuple
    containing the advanced parser and the codepoint.

    This function is a wrapper on top of `ExParsec.Input.get`, adding position
    tracking (codepoint index and line/column numbers). Position information
    can be found on the `position` field of `ExParsec.Parser`.
    """
    @spec get(t(state)) :: {t(state), String.codepoint()} | {:error, term()} | :eof
          when [state: var]
    def get(parser) do
        case Input.get(parser.input) do
            {inp, cp} ->
                pos = parser.position
                pos = %Position{pos | :index => pos.index + 1}

                pos = if cp == "\n" do
                    %Position{pos | :line => pos.line + 1, :column => 1}
                else
                    %Position{pos | :column => pos.column + 1}
                end

                {%__MODULE__{input: inp, position: pos}, cp}
            e -> e
        end
    end
end
