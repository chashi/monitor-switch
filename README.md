# monitor-switch

Switch monitor inputs on the MSI MPG 321URX OLED via DDC/CI using [m1ddc](https://github.com/waydabber/m1ddc).

## Requirements

- macOS with Apple Silicon
- [m1ddc](https://github.com/waydabber/m1ddc): `brew install m1ddc`
- DDC/CI enabled on the monitor (Settings > System > DDC/CI = ON)

## Usage

```sh
./switch-input.sh          # Switch to DisplayPort (default)
./switch-input.sh dp       # Switch to DisplayPort
./switch-input.sh usbc     # Switch to USB-C
./switch-input.sh toggle   # Toggle between USB-C and DisplayPort
./switch-input.sh status   # Show current input status
```

## Setup

Update the `DISPLAY_ID` in `switch-input.sh` with your monitor's UUID. Find it with:

```sh
m1ddc display list
```
