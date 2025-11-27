use once_cell::sync::Lazy;
use url::Url;
use rustler::{NifResult, Term, LocalPid};

// importa il tuo manager(del CRATE Rust) nel progetto Rust in ELixir (o percorso)
use crate::websocket_manager::WebSocketManager;

static TOKIO: Lazy<tokio::runtime::Runtime> = Lazy::new(|| {
    tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .expect("Failed to build Tokio runtime")
});

static MANAGER: Lazy<WebSocketManager> = Lazy::new(WebSocketManager::new);

#[rustler::nif(schedule = "DirtyIo")]
fn elixir_connect(url: String, callback: Term) -> NifResult<String> {
    // 1) Parsing URL
    let parsed_url =
        Url::parse(&url).map_err(|_| rustler::Error::Atom("invalid_url"))?;

    // 2) Decodifica immediata del PID
    let pid: LocalPid = callback.decode()
        .map_err(|_| rustler::Error::Atom("invalid_pid"))?;

    // 3) Chiamata ASYNC 
    let id = TOKIO.block_on(MANAGER.start_connection(parsed_url, pid))
        .map_err(|e| rustler::Error::Term(Box::new(e)))?;

    // 4) Return Id ricevuto ad Elixir
    Ok(id)
}

#[rustler::nif(schedule = "DirtyIo")]
fn elixir_disconnect(id: String) -> NifResult<()> {
    TOKIO
        .block_on(MANAGER.stop_connection(&id))
        .map_err(|e| rustler::Error::Term(Box::new(e)))?;

    Ok(())
}

#[rustler::nif(schedule = "DirtyIo")]
fn elixir_send_message(id: String, msg: String) -> NifResult<()> {
    TOKIO
        .block_on(MANAGER.send_message(&id, msg))
        .map_err(|e| rustler::Error::Term(Box::new(e)))?;

    Ok(())
}
