defmodule ElixirClient do
  use Rustler, otp_app: :elixir_client, crate: "elixirclient"

  # Funzioni NIF esposte da Rust
  def elixir_connect(_url, _callback_pid), do: :erlang.nif_error(:nif_not_loaded)
  def elixir_disconnect(_id), do: :erlang.nif_error(:nif_not_loaded)

  # Funzione di callback per stampare i messaggi ricevuti dal WebSocket
  def print_message(msg) do
    IO.puts("(CB) ***** Messaggio ricevuto: #{msg} *****")
  end

  # Funzione per creare un processo ricevitore di messaggi (Passerò alla NIF il PID di questo processo)
  def message_receiver do
    spawn(fn ->
      receive_messages()
    end)
  end

  # Funzione ricorsiva per ricevere messaggi
  defp receive_messages do
    receive do
      msg ->
        print_message(msg)
        receive_messages()
    end
  end

  # Funzione per creare 5 connessioni WebSocket parallele con callback
  def create_connections_parallel(url \\ "ws://127.0.0.1:8080", num_connections \\ 5) do
    # Crea un processo ricevitore di messaggi e ottieni il suo PID
    callback_pid = message_receiver()

    # Crea lista di TASK (uno per ciascuna connessione)
    tasks = for i <- 1..num_connections do
      Task.async(fn ->
        # Passa il PID del processo ricevitore come callback
        case elixir_connect(url, callback_pid) do
          id when is_binary(id) ->
            IO.puts("(ClientElixir) Connessione #{i} aperta, ID: #{id}")

            Process.sleep(5000) # Simulazione di attività connesse alla connessione



            case elixir_disconnect(id) do
              {} ->
                IO.puts("(ClientElixir) Connessione #{i} chiusa con successo, ID: #{id}")
              {:error, :already_closed} ->
                IO.puts("(ClientElixir) Connessione #{i} era già chiusa, ID: #{id}")
              {:error, reason} ->
                IO.puts("(ClientElixir) Errore durante la chiusura della connessione #{i}, ID: #{id}, Errore: #{reason}")
              unexpected ->
                IO.puts("(ClientElixir) Risultato inaspettato durante la chiusura della connessione #{i}, ID: #{id}, Errore: #{inspect(unexpected)}")
            end

          error ->
            IO.puts("(ClientElixir) Errore nell'aprire la connessione #{i}: #{inspect(error)}")
        end
      end)
    end

    Enum.each(tasks, fn task ->
      case Task.await(task, 10000) do
        :ok -> :ok
        {:error, reason} ->
          IO.puts("(ClientElixir) Errore durante l'attesa della connessione: #{inspect(reason)}")
        _ ->
          IO.puts("(ClientElixir) Timeout durante la chiusura della connessione.")
      end
    end)
    IO.puts("Tutte le connessioni sono state chiuse.")
  end
end
