# 0005 — Meshnet de Nord para el tramo Mac→Debian (solución 2)

- Date: 2026-10-05 · Status: **done (verified 2026-10-05, both directions)**
- Context: NordVPN siempre activo en la Mac rompe todo TCP Tailscale
  originado en ella (ver `docs/nordvpn-tailscale.md`). La app de Nord en
  macOS no tiene split tunneling, y reconfigurar a cliente manual (opción 1)
  se pospone. Meshnet vive dentro de la propia app de Nord: compatibilidad
  garantizada por construcción.
- Decision: usar **Meshnet solo para Mac→Debian**. Nada cambia en el resto:
  Mac→VPS por SSH a internet (`recoVPS`), VPS→Debian por tailnet
  (`100.84.216.84`, ya verificado). Tailscale se conserva.
- Consequences:
  - Dos meshes que mantener (tailnet + Meshnet); alias separado
    `mesh-debian` para no mezclar caminos.
  - Requiere cliente `nordvpn` en Debian (sudo humano) + login + `set
    meshnet on`, y activar Meshnet en la app de la Mac (clic humano).
  - Pendiente verificar: tramo Meshnet **con y sin** VPN conectado.
  - Si algún día se adopta la opción 1 (cliente manual con rangos
    excluidos), esta decisión se revierte y `ai-debian` vuelve a ser camino
    único.
