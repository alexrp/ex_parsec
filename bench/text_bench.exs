defmodule Bench.ExParsec.Text do
    use ExParsec, mode: Text
    use Benchfella

    @chars "sdfgjakghvnlkasjlghavsdjlkfhgvaskljmtvmslkdgfdaskl"

    bench "many any_char" do
        ExParsec.parse_text(@chars, many(any_char()))
    end
end
