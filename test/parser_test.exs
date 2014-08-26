defmodule Test.ExParsec.Parser do
    use ExUnit.Case, async: true

    alias ExParsec.Input.MemoryInput
    alias ExParsec.Parser
    alias ExParsec.Position
    alias ExParsec.Token

    test "basic get" do
        value = "foo"
        input = %MemoryInput{value: value}
        parser = %Parser{input: input}

        assert {parser, "f"} = Parser.get(parser)
        assert {parser, "o"} = Parser.get(parser)
        assert {parser, "o"} = Parser.get(parser)
        assert :eof = Parser.get(parser)
    end

    test "get noncharacter" do
        value = "\x{0fffe}"
        input = %MemoryInput{value: value}
        parser = %Parser{input: input}

        assert {:error, :noncharacter} = Parser.get(parser)
    end

    test "empty get" do
        value = ""
        input = %MemoryInput{value: value}
        parser = %Parser{input: input}

        assert :eof = Parser.get(parser)
    end

    test "text position tracking" do
        value = "fo\no"
        input = %MemoryInput{value: value}
        parser = %Parser{input: input, position: %Position{}}

        assert %Position{index: 0, line: 1, column: 1} = parser.position
        assert {parser = %Parser{position: %Position{index: 1, line: 1, column: 2}}, "f"} = Parser.get(parser)
        assert {parser = %Parser{position: %Position{index: 2, line: 1, column: 3}}, "o"} = Parser.get(parser)
        assert {parser = %Parser{position: %Position{index: 3, line: 2, column: 1}}, "\n"} = Parser.get(parser)
        assert {%Parser{position: %Position{index: 4, line: 2, column: 2}}, "o"} = Parser.get(parser)
    end

    test "token position tracking" do
        value = [%Token{position: %Position{index: 3, line: 5, column: 32}},
                 %Token{position: %Position{index: 47, line: 9, column: 6}}]
        input = %MemoryInput{value: value}
        parser = %Parser{input: input}

        assert {parser = %Parser{position: %Position{index: 3, line: 5, column: 32}}, _} = Parser.get(parser)
        assert {%Parser{position: %Position{index: 47, line: 9, column: 6}}, _} = Parser.get(parser)
    end

    test "no position tracking" do
        value = [:a, :b, :c]
        input = %MemoryInput{value: value}
        parser = %Parser{input: input}

        assert {parser = %Parser{position: nil}, :a} = Parser.get(parser)
        assert {parser = %Parser{position: nil}, :b} = Parser.get(parser)
        assert {%Parser{position: nil}, :c} = Parser.get(parser)
    end

    test "option passing" do
        value = <<3, 2, 1, 0>>
        input = %MemoryInput{value: value}
        parser = %Parser{input: input}

        assert {_, <<3>>} = Parser.get(parser, [n: 8])
    end

    test "state propagation" do
        value = "x"
        input = %MemoryInput{value: value}
        state = :foo
        parser = %Parser{input: input, state: state}

        assert {%Parser{state: :foo}, _} = Parser.get(parser)
    end
end
