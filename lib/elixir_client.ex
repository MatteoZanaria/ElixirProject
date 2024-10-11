defmodule ElixirClient do
  use Rustler, otp_app: :elixir_client, crate: "elixirclient"

  # Funzioni NIF esposte da Rust
  def elixir_connect(url), do: :erlang.nif_error(:nif_not_loaded)
  def elixir_disconnect(id), do: :erlang.nif_error(:nif_not_loaded)

  # Funzione per simulare connessioni WebSocket parallele
  def create_connections_parallel(url, num_connections \\ 10) do
    # Creiamo una lista di task, uno per ciascuna connessione
    tasks = for i <- 1..num_connections do
      Task.async(fn ->
        # Avvia la connessione
        id = elixir_connect(url)
        IO.puts("Connessione #{i} aperta, ID: #{id}")

        # Simula un'attività di lettura/scrittura per 5 secondi
        Process.sleep(5000)

        # Chiude la connessione
        elixir_disconnect(id)
        IO.puts("Connessione #{i} chiusa, ID: #{id}")
      end)
    end

    # Aspetta che tutte le connessioni siano state gestite
    Enum.each(tasks, &Task.await(&1))
    IO.puts("Tutte le connessioni sono state chiuse.")
  end
end
