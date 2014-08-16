defmodule Test.ExParsec.Input.FileInput do
    use ExUnit.Case, async: true

    alias ExParsec.Input.FileInput
    alias ExParsec.Input

    @data_dir Path.join("test", "data")
    @foo_txt Path.join(@data_dir, "foo.txt")
    @nonchar_txt Path.join(@data_dir, "nonchar.txt")
    @empty_txt Path.join(@data_dir, "empty.txt")

    test "basic get" do
        File.open!(@foo_txt, [:read, :utf8], fn(dev) ->
            input = %FileInput{device: dev}

            {input, cp1} = Input.get(input)
            {input, cp2} = Input.get(input)
            {input, cp3} = Input.get(input)
            {input, cp4} = Input.get(input)
            eof = Input.get(input)

            assert cp1 == "f"
            assert cp2 == "o"
            assert cp3 == "o"
            assert cp4 == "\n"
            assert eof == :eof
        end)
    end

    test "get noncharacter" do
        File.open!(@nonchar_txt, [:read, :utf8], fn(dev) ->
            input = %FileInput{device: dev}
            result = Input.get(input)

            assert result == {:error, :noncharacter}
        end)
    end

    test "empty get" do
        File.open!(@empty_txt, [:read, :utf8], fn(dev) ->
            input = %FileInput{device: dev}
            result = Input.get(input)

            assert result == :eof
        end)
    end
end
