defmodule Test.ExParsec.Input.MemoryInput do
    use ExUnit.Case, async: true

    alias ExParsec.Input.MemoryInput
    alias ExParsec.Input

    test "basic get" do
        value = "foo"
        input = %MemoryInput{value: value}

        assert {input, "f"} = Input.get(input)
        assert {input, "o"} = Input.get(input)
        assert {input, "o"} = Input.get(input)
        assert :eof = Input.get(input)
    end

    test "get noncharacter" do
        value = "\x{0fffe}"
        input = %MemoryInput{value: value}

        assert {:error, :noncharacter} = Input.get(input)
    end

    test "empty get" do
        value = ""
        input = %MemoryInput{value: value}

        assert :eof = Input.get(input)
    end

    test "bitstring get" do
        value = <<3>>
        input = %MemoryInput{value: value, is_string: false}

        assert {input, <<0 :: size(6)>>} = Input.get(input, [n: 6])
        assert {input, <<1 :: size(1)>>} = Input.get(input)
        assert {input, <<1 :: size(1)>>} = Input.get(input)
        assert :eof = Input.get(input)
    end

    test "term get" do
        value = [:a, :b, :c]
        input = %MemoryInput{value: value, is_string: false}

        assert {input, :a} = Input.get(input)
        assert {input, :b} = Input.get(input)
        assert {input, :c} = Input.get(input)
        assert :eof = Input.get(input)
    end

    test "codepoints get" do
        value = ["a", "b", "c"]
        input = %MemoryInput{value: value, is_string: false}

        assert {input, "a"} = Input.get(input)
        assert {input, "b"} = Input.get(input)
        assert {input, "c"} = Input.get(input)
        assert :eof = Input.get(input)
    end
end
