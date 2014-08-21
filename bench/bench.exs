defmodule Bench.ExParsec do
    defmacro __using__(opts) do
        quote do
            use ExParsec, unquote(opts)

            require Benchfella

            import unquote(__MODULE__)
        end
    end

    defmacro bench_text(name, value, [do: block]) do
        quote do
            Benchfella.bench unquote(name) do
                ExParsec.parse_value(unquote(value), unquote(block))
            end
        end
    end

    defmacro bench_binary(name, value, [do: block]) do
        quote do
            Benchfella.bench unquote(name) do
                ExParsec.parse_binary(unquote(value), unquote(block))
            end
        end
    end
end
