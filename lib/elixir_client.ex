defmodule ElixirClient do
  use Rustler, otp_app: :elixir_client, crate: "elixirclient"

  # Funzioni NIF esposte da Rust
  def elixir_connect(_url), do: :erlang.nif_error(:nif_not_loaded)
  def elixir_disconnect(_id), do: :erlang.nif_error(:nif_not_loaded)


  # Funzione per creare 5 connessioni WebSocket parallele
  def create_connections_parallel(url \\ "ws://127.0.0.1:8080", num_connections \\ 5) do

    #crea lista di TASK (uno per ciascuna connessione)
    tasks = for i <- 1..num_connections do
      Task.async(fn ->

        case elixir_connect(url) do
          id when is_binary(id) ->
            IO.puts("Connessione #{i} aperta, ID: #{id}")

            Process.sleep(5000)

            case elixir_disconnect(id) do
              {} ->
                IO.puts("Connessione #{i} chiusa, ID: #{id}")
              {:error, :already_closed} ->
                IO.puts("Connessione #{i} era già chiusa, ID: #{id}")
              _ ->
                IO.puts("Errore durante la chiusura della connessione #{i}, ID: #{id}")
            end

          error ->
            IO.puts("Errore nell'aprire la connessione #{i}: #{inspect(error)}")
        end
      end)
    end

    Enum.each(tasks, &Task.await(&1))
    IO.puts("Tutte le connessioni sono state chiuse.")
  end
end
