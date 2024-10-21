use rustler::NifResult;
use my_websocket_crate::WebSocketManager; // Import della Struct del Crate
use tokio::runtime::Runtime; // Per gestire le funzioni async
use once_cell::sync::Lazy;
use url::Url;

// Mantieni un unico `WebSocketManager` globale
static MANAGER: Lazy<WebSocketManager> = Lazy::new(|| WebSocketManager::new());

// Configura il runtime Tokio una volta sola
static TOKIO: Lazy<Runtime> = Lazy::new(|| {
    Runtime::new().expect("Failed to create Tokio runtime")
});

// NIF per la connessione
#[rustler::nif(schedule = "DirtyIo")]
fn elixir_connect(url: String) -> NifResult<String> {
    // Parsing URL
    let parsed_url = Url::parse(&url).map_err(|_| rustler::Error::Atom("invalid_url"))?;

    // Esegui la connessione asincrona utilizzando Tokio
    let id = TOKIO.block_on(async {
        MANAGER.start_connection(parsed_url).await
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

// Collegamento funzioni native Rust al modulo Elixir
rustler::init!("Elixir.ElixirClient");
