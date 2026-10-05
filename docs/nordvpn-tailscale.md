# NordVPN (siempre activo) vs. Tailscale — problema y solución

> Nota de estudio. Diagnóstico verificado el 2026-10-05. Decisiones
> relacionadas: `decisions/0002-tailscale-overlay.md`,
> `decisions/0003-ssh-aliases.md`, `decisions/0005-meshnet-mac-debian.md`.

## El problema en una frase

La Mac lleva NordVPN siempre activo, y **todo el tráfico Tailscale que nace
en la Mac muere** (timeouts TCP), mientras que el SSH normal a internet
funciona sin problema.

## Por qué el VPS sí funcionaba y la laptop no

No era que "el VPS fuera compatible con el VPN y la laptop no". Había **dos
clases de tráfico distintas**:

| Destino | Camino real usado | Relación con NordVPN | Resultado (VPN activo) |
|---|---|---|---|
| `ssh recoVPS` (VPS por internet) | TCP normal a IP pública | Viaja *dentro* del túnel como una web más | ✅ funciona |
| `ssh ai-vps` (VPS por tailnet `100.x`) | Interfaz virtual Tailscale | El demonio lo encapsula en UDP y Nord lo rompe | ❌ timeout |
| `ssh ai-debian` (laptop por tailnet) | Igual que arriba | Igual que arriba | ❌ timeout |

El tailnet fallaba hacia **ambos** destinos. El VPS "funcionaba" solo porque
además tiene IP pública y se llegaba por el camino normal de internet. La
laptop no tiene plan B: sin IP pública, sus únicos caminos son la LAN (solo
en casa) y el tailnet.

## Por qué la laptop no tiene IP pública

```text
laptop (192.168.1.120) ─┐
móvil                   ──┼─► router ──► UNA IP pública ──► internet
Mac                     ──┘     ↑                ↑
                       IPs privadas    la IP es del router,
                       (solo existen   no de tus equipos
                        en tu casa)
```

1. El ISP da **una sola IP pública al router**; dentro de casa todo es
   `192.168.1.x` (rango privado, repetido en millones de hogares).
2. El router **descarta visitas inesperadas**: un paquete de fuera hacia tu
   IP pública no sabe a qué dispositivo dirigirlo → se tira. Verificado:
   desde el VPS, 100% de pérdida hacia la LAN.
3. Posible **CGNAT**: muchos ISPs hacen un segundo NAT en su red, con lo que
   ni abriendo puertos en el router funcionaría.
4. El VPS vive en un datacenter con **IP pública directa en su interfaz**,
   sin NAT: cualquiera puede abrirle conexión al puerto 22.

Conclusión: la laptop nunca puede "recibir"; solo puede "llamar hacia
fuera" (como al navegar). Por eso las soluciones válidas son overlays donde
Debian mantiene un túnel saliente (Tailscale, Meshnet), jamás port-forward.

## Evidencia del diagnóstico (2026-10-05)

- `tailscale ping` Mac→Debian iba por **DERP(Madrid)** (~280 ms) en vez de
  directo: el UDP de descubrimiento se perdía dentro del túnel Nord.
- `tailscale ping` Mac→VPS iba directo por UDP, **pero el TCP igual moría**:
  el daño está en el TCP sobre doble túnel, no solo en el relay.
- VPS→Debian por tailnet: banner SSH 3/3 — el tailnet en sí estaba sano.
- Ruta por defecto de la Mac apuntando a `utun7` (NordVPN, `10.5.0.2`) con
  MTU 1420 → doble encapsulación = agujero negro de MTU para TCP.
- Al pausar NordVPN 5 min: ambos tramos pasaron a **directo** (Debian por
  LAN en 25 ms) y el SSH funcionó. Claves de host del tailnet verificadas
  por huella contra las ya confiables antes de fijarlas.

## Opciones evaluadas

1. **NordVPN manual (WireGuard/OpenVPN) excluyendo `100.64.0.0/10` y
   `fd7a:115c:a1e0::/48`** — definitiva, un solo mesh, VPN siempre. Requiere
   configurar el cliente manual (~30 min).
2. **Meshnet de Nord solo para Mac→Debian** — elegida (decisión 0005). Cero
   cambios de hábitos, 10 min.
3. **Todo a Meshnet, abandonar Tailscale** — descarta lo construido y ata la
   flota a un proveedor.
4. **Pausar el VPN para trabajar** — funciona pero es lo más inseguro justo
   de viaje.

Nota: la app de NordVPN en macOS **no tiene split tunneling** (limitación
del framework de red de Apple desde Big Sur); por eso la opción 1 exige
cliente manual y no un clic.

## Topología resultante (solución 2)

```text
Mac ──Meshnet (Nord)──► Debian     (funciona con o sin VPN: verificar ambos)
Mac ──internet SSH───► VPS        (recoVPS, funciona siempre)
VPS ──tailnet──────────► Debian    (100.84.216.84, verificado 3/3)
```

Aliases locales: `ai-vps`/`ai-debian` = tailnet; `mesh-debian` = Meshnet
(tramo Mac→Debian con VPN activo).

## Comandos de referencia

```sh
# Ver estado meshnet en Debian
nordvpn set meshnet on
nordvpn meshnet peer list

# Verificar tramo Mac -> Debian por Meshnet (VPN ACTIVO)
ssh mesh-debian 'hostname; whoami'

# Verificar que VPS -> Debian por tailnet sigue vivo
ssh ai-vps 'nc -w5 100.84.216.84 22 </dev/null | head -1'

# Chequeos rutinarios (L0, sin cambios)
scripts/health/check-vps.sh
scripts/health/check-debian.sh
```
