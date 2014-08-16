defmodule Test.ExParsec.Input.MemoryInput do
    use ExUnit.Case, async: true

    alias ExParsec.Input.MemoryInput
    alias ExParsec.Input

    test "basic get" do
        value = "foo"
        input = %MemoryInput{value: value}

        {input, cp1} = Input.get(input)
        {input, cp2} = Input.get(input)
        {input, cp3} = Input.get(input)
        eof = Input.get(input)

        assert cp1 == "f"
        assert cp2 == "o"
        assert cp3 == "o"
        assert eof == :eof
    end

    test "get noncharacter" do
        value = "\x{0fffe}"
        input = %MemoryInput{value: value}
        result = Input.get(input)

        assert result == {:error, :noncharacter}
    end

    test "empty get" do
        value = ""
        input = %MemoryInput{value: value}
        result = Input.get(input)

        assert result == :eof
    end
end
