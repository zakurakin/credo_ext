defmodule CredoExt.MixProject do
  use Mix.Project

  def project do
    [
      app: :credo_ext,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      deps: deps(),
      description: "Custom Credo checks for function formatting consistency",
      package: package()
    ]
  end

  defp deps do
    [
      {:excoveralls, "~> 0.18", only: [:dev, :test]},
      {:credo, "~> 1.7", runtime: false},
      {:ex_doc, "~> 0.32", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "credo_ext",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/edenlabllc/credo_ext"}
    ]
  end
end
