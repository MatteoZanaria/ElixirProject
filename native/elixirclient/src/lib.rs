use rustler::{Env, Term, NifResult, Encoder};
use client_crate::{connect, disconnect};  // Importa le funzioni dal tuo crate

#[rustler::nif]
fn elixir_connect(url: String) -> NifResult<String> {
    let id = connect(url);  // Chiama la funzione dal crate lib.rs
    Ok(id)
}

#[rustler::nif]
fn elixir_disconnect(id: String) -> NifResult<()> {
    disconnect(id);  // Chiama la funzione dal crate lib.rs
    Ok(())
}

rustler::init!("Elixir.ElixirClient", [elixir_connect, elixir_disconnect]);