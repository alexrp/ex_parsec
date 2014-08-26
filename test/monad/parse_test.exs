defmodule Test.ExParsec.Monad.Parse do
    use ExUnit.Case, async: true

    import ExParsec.Text

    require ExParsec.Monad.Parse

    alias ExParsec.Input.MemoryInput
    alias ExParsec.Monad.Parse
    alias ExParsec.Parser
    alias ExParsec.Reply

    test "successful binding" do
        value = "x"
        input = %MemoryInput{value: value}
        parser = %Parser{input: input}

        p = Parse.m do
            x <- any_char()
            return x
        end

        assert %Reply{status: :ok} = p.(parser)
    end

    test "successful let binding" do
        value = ""
        input = %MemoryInput{value: value}
        parser = %Parser{input: input}

        p = Parse.m do
            let x = "foo"
            let do
                y = "bar"
                z = "baz"
            end
            return x <> y <> z
        end

        assert %Reply{status: :ok} = p.(parser)
    end

    test "unsuccessful binding" do
        value = "xz"
        input = %MemoryInput{value: value}
        parser = %Parser{input: input}

        p = Parse.m do
            x <- char("x")
            y <- char("y")
            return x <> y
        end

        assert %Reply{status: :error} = p.(parser)
    end
end
