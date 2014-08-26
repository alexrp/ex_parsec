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
end
