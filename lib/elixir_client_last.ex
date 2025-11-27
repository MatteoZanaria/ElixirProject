defmodule ElixirClient do
      use Rustler, otp_app: :elixir_client, crate: "elixirclient"
    
      # NIFs esposte utilizzabili
      def elixir_connect(_url, _callback_pid), do: :erlang.nif_error(:nif_not_loaded)
      def elixir_disconnect(_id), do: :erlang.nif_error(:nif_not_loaded)
      def elixir_send_message(_id, _message), do: :erlang.nif_error(:nif_not_loaded)
    
      # Processo che riceve i messaggi inoltrati dal Crate Rust
      def message_receiver do
        spawn(fn -> receive_messages() end)
      end

      defp receive_messages do
        receive do
          {id, msg} ->
            print_message(id, msg)
            receive_messages()
        end
      end

      def print_message(id, msg) do
        IO.puts("Messaggio ricevuto | Id: #{id} | Msg: #{msg}")
      end  
    
      # FN che genera 5 connessioni WebSocket parallele
      def create_connections_parallel(url \\ "ws://127.0.0.1:8080", num_connections \\ 5) do
        # Crea un istanza di processo ricevitore e salva il suo PID
        callback_pid = message_receiver()
    
        # Crea lista di TASK (uno per ciascuna connessione)
        tasks =
          for i <- 1..num_connections do
            Task.async(fn ->
              # Passa il PID del processo ricevitore
              case elixir_connect(url, callback_pid) do
                id when is_binary(id) ->
                  IO.puts("(ClientElixir) Connessione #{i} aperta, ID: #{id}")
    
                  Process.sleep(5000) # Simulazione di attività connesse alla connessione
    
                  case elixir_disconnect(id) do
                      {} ->
                        IO.puts("Connessione #{i} chiusa con successo, ID: #{id}")
                    
                      {:error, :already_closed} ->
                        IO.puts("Connessione #{i} era già chiusa, ID: #{id}")
                    
                      other ->
                        IO.puts("Errore chiusura connessione #{i}, ID: #{id}, risposta: #{inspect(other)}")
                 end
    
                error ->
                  IO.puts("(ClientElixir) Errore nell'aprire la connessione #{i}: #{inspect(error)}")
              end
            end)
          end
    
        # Attendo la conclusione dei TASK
        Enum.each(tasks, fn task ->
          case Task.await(task, 10_000) do
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
