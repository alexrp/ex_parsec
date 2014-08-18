defmodule ExParsec.Parser do
    @moduledoc """
    Represents the state of an executing parse session.

    * `input` is the input data.
    * `position` is the current position in the input data. This is `nil` if
      the input data does not support text position tracking.
    * `state` is the current user state.
    """

    alias ExParsec.Input
    alias ExParsec.Position
    alias ExParsec.Token

    defstruct input: nil,
              position: nil,
              state: nil

    @typedoc """
    The type of an `ExParsec.Parser` instance.
    """
    @type t(state) :: %__MODULE__{input: Input.t(),
                                  position: Position.t() | nil,
                                  state: state}

    @doc """
    Checks if `value` is an `ExParsec.Parser` instance.
    """
    @spec parser?(term()) :: boolean()
    def parser?(value) do
        match?(%__MODULE__{}, value)
    end

    @doc """
    Fetches data from the input. If no more data is available, `:eof` is
    returned. If invalid input data is encountered, a tuple containing `:error`
    and a reason is returned. Otherwise, returns a tuple containing the
    advanced parser and the fetched data.

    This function is a wrapper on top of `ExParsec.Input.get/1`, adding
    position tracking (codepoint index and line/column numbers) for input data
    that supports it. Position information can be found on the `position` field
    of `ExParsec.Parser`.
    """
    @spec get(t(state)) :: {t(state), String.codepoint() | Token.t()} |
                           {:error, term()} | :eof when [state: var]
    def get(parser) do
        case Input.get(parser.input) do
            e = {:error, _} -> e
            :eof -> :eof
            {inp, data} ->
                pos = cond do
                    is_binary(data) ->
                        pos = parser.position || %Position{}
                        pos = %Position{pos | :index => pos.index + 1}

                        if data == "\n" do
                            %Position{pos | :line => pos.line + 1, :column => 1}
                        else
                            %Position{pos | :column => pos.column + 1}
                        end
                    Token.token?(data) -> data.position
                    true -> nil
                end

                {%__MODULE__{input: inp, position: pos}, data}
        end
    end
end
