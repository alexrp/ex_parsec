defmodule ExParsec.Mixfile do
    use Mix.Project

    def project() do
        [name: "ExParsec",
         description: "A parser combinator library inspired by Parsec.",
         app: :ex_parsec,
         version: "0.0.0",
         elixir: "~> 0.15.1",
         source_url: "https://github.com/alexrp/ex_parsec",
         homepage_url: "https://hex.pm/packages/ex_parsec",
         deps: deps(),
         docs: docs(),
         package: package(),
         aliases: aliases(),
         test_coverage: coverage()]
    end

    def application() do
        [applications: [:monad]]
    end

    defp deps() do
        [{:coverex, "~> 0.0.7", only: [:test]},
         {:dialyze, "~> 0.1.2", only: [:dev]},
         {:earmark, "~> 0.1.10", only: [:dev]},
         {:ex_doc, "~> 0.5.2", only: [:dev]},
         {:monad, "~> 1.0.3"}]
    end

    defp docs() do
        {ref, 0} = System.cmd("git", ["rev-parse", "--verify", "--quiet", "HEAD"])

        [main: "README",
         readme: true,
         source_ref: ref]
    end

    defp package() do
        [contributors: ["Alex Rønne Petersen"],
         licenses: ["MIT"],
         links: %{"GitHub" => "https://github.com/alexrp/ex_parsec",
                  "Documentation" => "http://alexrp.com/ex_parsec"}]
    end

    defp aliases() do
        [make: ["deps.get", "deps.compile", "docs"],
         test: "test --trace --cover"]
    end

    defp coverage() do
        [tool: Coverex.Task]
    end
end
