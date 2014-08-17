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
         aliases: aliases()]
    end

    defp deps() do
        [{:dialyze, "~> 0.1", only: [:dev]},
         {:ex_doc, "~> 0.5", only: [:dev]}]
    end

    defp docs() do
        [main: "README",
         readme: true]
    end

    defp package() do
        [contributors: ["Alex Rønne Petersen"],
         licenses: ["MIT"],
         links: %{"GitHub" => "https://github.com/alexrp/ex_parsec"}]
    end

    defp aliases() do
        [test: "test --trace"]
    end
end
