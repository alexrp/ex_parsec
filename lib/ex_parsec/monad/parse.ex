defmodule ExParsec.Monad.Parse do
    @moduledoc """
    Provides monadic syntax for writing parsers.
    """

    use Monad

    alias ExParsec.Base

    @doc false
    @spec bind(ExParsec.t(state, result1),
               ((result1) -> ExParsec.t(state, result2))) ::
          ExParsec.t(state, result2)
          when [state: var, result1: var, result2: var]
    def bind(p, f) do
        Base.bind(p, f)
    end

    @doc false
    @spec return(result) :: ExParsec.t(term(), result) when [result: var]
    def return(x) do
        Base.return(x)
    end
end
