defmodule ElixirClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_client,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      rustler_crates: rustler_crates() # Qui includiamo la chiamata a rustler_crates +++
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end


  # RUSTLER_CONFIG: BLOCCO di BINDING tra ELIXIR-RUST +++
  defp rustler_crates do
    [
      elixirclient: [
        path: "native/elixirclient",
        mode: if(Mix.env() == :prod, do: :release, else: :debug)
      ]
    ]
  end

   # BLOCCO DIPENDENZE
  defp deps do
    [
      {:jason, "~> 1.4.4"},
      {:toml, "~> 0.7"},

      # AGGIUNTA RUSTLER +++
      {:rustler, "~> 0.34"} 
    ]
  end

end
