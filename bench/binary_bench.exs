Code.require_file(Path.join("bench", "bench.exs"))

defmodule Bench.ExParsec.Binary do
    use Bench.ExParsec, mode: Binary

    @bytes <<43, 63, 54, 134, 43, 64, 78, 43, 254, 65, 124, 186, 43, 56>>

    bench_binary "many bits", @bytes do
        many(bits(1))
    end
end
