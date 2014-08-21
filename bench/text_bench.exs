Code.require_file(Path.join("bench", "bench.exs"))

defmodule Bench.ExParsec.Text do
    use Bench.ExParsec, mode: Text

    @chars "sdfgjakghvnlkasjlghavsdjlkfhgvaskljmtvmslkdgfdaskl"

    bench_text "many any_char", @chars do
        many(any_char())
    end
end
