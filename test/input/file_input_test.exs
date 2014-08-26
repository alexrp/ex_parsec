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

            assert {input, "f"} = Input.get(input)
            assert {input, "o"} = Input.get(input)
            assert {input, "o"} = Input.get(input)
            assert {input, "\n"} = Input.get(input)
            assert :eof = Input.get(input)
        end)
    end

    test "get noncharacter" do
        File.open!(@nonchar_txt, [:read, :utf8], fn(dev) ->
            input = %FileInput{device: dev}

            assert {:error, :noncharacter} = Input.get(input)
        end)
    end

    test "empty get" do
        File.open!(@empty_txt, [:read, :utf8], fn(dev) ->
            input = %FileInput{device: dev}

            assert :eof = Input.get(input)
        end)
    end
end
