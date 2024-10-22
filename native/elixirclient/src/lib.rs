use rustler::{NifResult, Env, Term, Encoder};
use my_websocket_crate::WebSocketManager;
use tokio::runtime::Runtime;
use once_cell::sync::Lazy;
use url::Url;

static MANAGER: Lazy<WebSocketManager> = Lazy::new(|| WebSocketManager::new());
static TOKIO: Lazy<Runtime> = Lazy::new(|| {
    Runtime::new().expect("Failed to create Tokio runtime")
});

// NIF per la connessione con callback
#[rustler::nif(schedule = "DirtyIo")]
fn elixir_connect<'a>(env: Env<'a>, url: String, callback: Term<'a>) -> NifResult<String> {
    let parsed_url = Url::parse(&url).map_err(|_| rustler::Error::Atom("invalid_url"))?;

    let id = TOKIO.block_on(async {
        let result = MANAGER.start_connection(env, parsed_url, callback).await;
        match result {
            Ok(connection_id) => {
                //println!("Connessione stabilita con ID: {}", connection_id);
                Ok(connection_id)
            }
            Err(e) => Err(e.to_string()),
        }
    }).map_err(|e| rustler::Error::Term(Box::new(e)))?;

    Ok(id)
}

// NIF per la disconnessione
#[rustler::nif(schedule = "DirtyIo")]
fn elixir_disconnect(id: String) -> NifResult<()> {
    // Esegui la disconnessione asincrona
    TOKIO.block_on(async {
        MANAGER.stop_connection(&id).await
    }).map_err(|e| rustler::Error::Term(Box::new(e)))?;

    Ok(())
}

// Collegamento delle funzioni NIF al modulo Elixir
rustler::init!("Elixir.ElixirClient");
