use std::path::PathBuf;

use anyhow::{Context, Error};
use clap::{ArgGroup, Parser};

use dfx_core::{
    interface::builder::{IdentityPicker, NetworkPicker},
    DfxInterface,
};

/// Pings an Internet Computer network and returns its status.
#[derive(Parser)]
#[clap(group(ArgGroup::new("network-select").multiple(false)))]
struct Cli {
    /// Network to attempt to connect to
    #[arg(long, group = "network-select")]
    network: Option<String>,

    /// Shorthand for --network=ic.
    #[clap(long, group = "network-select")]
    ic: bool,

    /// Path to dfx cache
    #[arg(long("dfx-cache-path"), env = "DFX_CACHE_PATH")]
    cache: Option<PathBuf>,
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    let cli = Cli::parse();

    let id = IdentityPicker::Anonymous;

    let nw = (|| {
        if cli.ic {
            return NetworkPicker::Mainnet;
        }

        if let Some(name) = cli.network {
            return NetworkPicker::Named(name);
        }

        NetworkPicker::Local
    })();

    let ifc = DfxInterface::builder()
        .with_identity(id)
        .with_network(nw)
        .build()
        .await
        .context("failed to create interface")?;

    if !ifc.network_descriptor().is_ic {
        ifc.agent()
            .fetch_root_key()
            .await
            .context("failed to fetch root key")?;
    }

    let s = ifc
        .agent()
        .status()
        .await
        .context("failed to ping network")?;

    println!("{s:?}");

    Ok(())
}
