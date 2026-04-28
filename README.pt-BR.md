# Predator Helios Neo 16 AI — Fix de Performance no Linux

> Desbloqueia o TGP completo da GPU (115W) e controle das ventoinhas no modo turbo no Acer Predator Helios Neo 16 AI no Linux.

**[Read in English](README.md)**

---

## O Problema

No Ubuntu (e outras distros Linux), a RTX 5070 Laptop fica limitada a **80W de TGP**. No Windows, o PredatorSense ativa o modo Turbo e a GPU opera com **115W**. As ventoinhas também não atingem a velocidade máxima.

| | Linux (antes) | Linux (depois) | Windows |
|---|---|---|---|
| Limite de potência da GPU | 80W | **115W** | 115W |
| GPU sob carga | ~80W | **~97W** (Dynamic Boost) | ~115W |
| Ventoinhas turbo | ✗ | ✓ | ✓ |
| Botão físico | ✗ | ✓ | ✓ |

---

## Hardware

| Componente | Especificação |
|---|---|
| Notebook | Acer Predator Helios Neo 16 AI |
| GPU | NVIDIA GeForce RTX 5070 Laptop |
| CPU | Intel Core Ultra 9 275HX |
| Kernel testado | 6.17.0-22-generic |
| Driver testado | NVIDIA 590.48.01 |
| OS testado | Ubuntu 24.04 |

---

## Causa Raiz

Dois problemas foram identificados:

1. **nvidia-powerd não instalado como serviço** — O daemon Dynamic Boost 2.0 da NVIDIA está presente no pacote `nvidia-kernel-common-*-server`, mas sua unit systemd não é instalada automaticamente. Sem ele, o driver usa TGP conservador de 80W.

2. **Sem driver WMI para o GUID gaming** — O GUID WMI gaming `7A4DDFE7-5B5D-40B4-8595-4408E0CC7F56` (ACPI object_id `BH`) não tem driver no Linux. Porém, chamadas ACPI diretas via `acpi_call` funcionam e controlam corretamente a velocidade das ventoinhas e o LED.

---

## Instalação Rápida

```bash
git clone https://github.com/vieiraEverton/predator-helios-neo-16-linux.git
cd predator-helios-neo-16-linux
sudo bash install.sh
```

> **Secure Boot:** Se o Secure Boot estiver ativado, o módulo `acpi_call` precisa ter sua chave de assinatura registrada no banco MOK do firmware. O pacote `acpi-call-dkms` do Ubuntu assina o módulo automaticamente, mas o registro da chave exige uma confirmação única na tela "MOK Manager" durante o reboot. Se o instalador avisar que o `acpi_call` falhou ao carregar, consulte [Solução de Problemas](docs/troubleshooting.md).

---

## O Que é Instalado

| Arquivo | Local | Função |
|---|---|---|
| `predator-mode` | `/usr/local/bin/` | Script de gerenciamento de modos |
| `predator-button.py` | `/usr/local/lib/predator/` | Daemon do botão físico |
| `predator-button.service` | `/etc/systemd/system/` | Unit systemd (inicia no boot) |
| `nvidia-powerd.service` | `/etc/systemd/system/` | Serviço Dynamic Boost |
| `nvidia-powerd.conf` | `/etc/dbus-1/system.d/` | Política D-Bus |
| `acpi-call.conf` | `/etc/modules-load.d/` | Carrega acpi_call no boot |

---

## Uso

```bash
sudo predator-mode turbo      # GPU 115W + ventoinhas máximas + LED roxo
sudo predator-mode balanced   # GPU 80W + ventoinhas normais + LED azul
sudo predator-mode toggle     # alterna entre os modos
sudo predator-mode status     # exibe modo atual e potência da GPU
```

O **botão PredatorSense** (o que abre o PredatorSense no Windows) também alterna entre os modos.

---

## Comportamento no Boot

A BIOS sempre reinicia no modo balanced. O sistema leva isso em conta:

| Evento | Estado |
|---|---|
| Boot | Modo balanced, GPU 80W |
| Serviço `predator-button` inicia | Grava `balanced` no state file |
| 1º aperto do botão | → Turbo: GPU 115W, ventoinhas máximas |
| 2º aperto | → Balanced: GPU 80W, ventoinhas normais |

---

## Como Funciona

### Potência da GPU (nvidia-powerd)

O `nvidia-powerd` é o daemon Dynamic Boost 2.0 da NVIDIA. Ele redistribui o envelope de energia compartilhado entre CPU e GPU em tempo real. Sem ele, o driver usa TGP estático conservador de 80W.

- **Modo turbo** → `systemctl start nvidia-powerd` → limite da GPU sobe para 115W
- **Modo balanced** → `systemctl stop nvidia-powerd` → limite volta para 80W

> O `nvidia-powerd` **não** é habilitado no boot. É iniciado/parado pelo `predator-mode` para garantir que a GPU só opere a 115W com as ventoinhas no máximo.

### Controle de Ventoinhas e LED (ACPI/WMI)

A velocidade das ventoinhas e a cor do LED são controladas via chamadas ACPI diretas usando o método WMI gaming `\_SB_.PC00.WMID.WMBH`:

| Byte do modo | Efeito |
|---|---|
| `0x01` | Balanced — LED azul, ventoinhas silenciosas |
| `0x05` | Turbo — LED roxo, ventoinhas máximas |

### Botão Físico

O botão PredatorSense gera o evento `EV_KEY` código **425** (`KEY_PRESENTATION`, scan `0xF5`) no teclado PS/2 interno (`bustype 0x11`, `AT Translated Set 2 keyboard`).

O daemon `predator-button.py` detecta o dispositivo por bus type + nome (e não pelo número `/dev/input/eventN`, que pode mudar com dispositivos USB conectados).

---

## Após Atualizar o Driver NVIDIA

Após atualizar o driver, verifique se o caminho do arquivo de serviço mudou:

```bash
find /usr/share/doc -name "nvidia-powerd.service"
```

Se o número de versão mudou (ex: `590` → `600`), execute o instalador novamente:

```bash
sudo bash install.sh
```

---

## Desinstalar

```bash
sudo bash uninstall.sh
```

---

## Solução de Problemas

Veja [docs/troubleshooting.md](docs/troubleshooting.md).

---

## Referência Técnica

Veja [docs/technical-reference.md](docs/technical-reference.md).

---

## Contribuindo

Issues e PRs são bem-vindos. Se você tem um modelo diferente do Predator e os caminhos WMI são diferentes, abra uma issue com a saída de:

```bash
sudo modprobe acpi_call
sudo bash -c 'printf "\_SB_.PC00.WMID.WMBH 0x01 0x16 {0x0B,0x05,0x00,0x00,0x00,0x00,0x00,0x00}\n" > /proc/acpi/call && cat /proc/acpi/call'
```

---

## Licença

MIT
