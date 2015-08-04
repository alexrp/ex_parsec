defmodule Bench.ExParsec.Binary do
    use ExParsec, mode: Binary
    use Benchfella

    @bytes <<43, 63, 54, 134, 43, 64, 78, 43, 254, 65, 124, 186, 43, 56>>

    bench "many bits" do
        ExParsec.parse_bitstring(@bytes, many(bits(1)))
    end
end
