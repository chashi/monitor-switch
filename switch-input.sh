#!/bin/bash
#
# MSI MPG 321URX OLED - Input Switcher
#
# Toggles between USB-C and DisplayPort inputs using DDC/CI via m1ddc.
#
# IMPORTANT: This monitor requires the display UUID (not the display number)
# for m1ddc commands to work correctly.
#
# MSI MPG 321URX OLED DDC/CI input values (standard MCCS):
#   DisplayPort 1 = 15 (0x0F)
#   DisplayPort 2 = 16 (0x10)  - USB-C in DP Alt Mode
#   HDMI 1        = 17 (0x11)
#   HDMI 2        = 18 (0x12)
#   USB-C         = 27 (0x18)  - may also work
#
# Usage:
#   ./switch-input.sh          - Switch to DisplayPort (from USB-C)
#   ./switch-input.sh dp       - Switch to DisplayPort
#   ./switch-input.sh usbc     - Switch to USB-C
#   ./switch-input.sh toggle   - Toggle between USB-C and DisplayPort
#   ./switch-input.sh status   - Show current input status
#

set -euo pipefail

# --- Configuration ---
# MSI MPG 321URX OLED - must use UUID for reliable DDC/CI communication.
# Find yours with: m1ddc display list
DISPLAY_ID="C85F15D4-1755-408A-A7A6-E183AAA7D23C"

INPUT_DP=15                        # DisplayPort 1 (0x0F)
INPUT_USB_C=16                     # USB-C / Type-C (0x10, DP Alt Mode = "DisplayPort 2")
INPUT_HDMI1=17                     # HDMI 1 (0x11)
INPUT_HDMI2=18                     # HDMI 2 (0x12)
# Note: value 27 (0x1B) is the generic USB-C code but 16 works for this monitor

STATE_FILE="$HOME/.monitor-input-state"

# --- Helpers ---
check_m1ddc() {
    if ! command -v m1ddc &>/dev/null; then
        echo "ERROR: m1ddc is not installed."
        echo "Install it with: brew install m1ddc"
        exit 1
    fi
}

get_current_input() {
    local val
    val=$(m1ddc display "$DISPLAY_ID" get input 2>/dev/null || echo "error")
    echo "$val"
}

set_input() {
    local target_val="$1"
    local target_name="$2"

    echo "Switching to $target_name (input value: $target_val)..."
    m1ddc display "$DISPLAY_ID" set input "$target_val" 2>&1
    local rc=$?

    if [ $rc -eq 0 ]; then
        echo "SUCCESS: Switched to $target_name"
        # Save state for toggle (since 'get input' may not work reliably)
        echo "$target_val" > "$STATE_FILE"
    else
        echo "FAILED: Could not switch input (exit code: $rc)"
        echo ""
        echo "Troubleshooting tips:"
        echo "  - Make sure the monitor has DDC/CI enabled in its OSD settings"
        echo "  - (Settings > System > DDC/CI = ON)"
        echo "  - Try running: m1ddc display list"
        echo "  - The display UUID may have changed - update DISPLAY_ID in this script"
    fi
    return $rc
}

switch_to_dp() {
    set_input "$INPUT_DP" "DisplayPort"
}

switch_to_usbc() {
    set_input "$INPUT_USB_C" "USB-C"
}

toggle_input() {
    # Try reading current input from monitor
    local current
    current=$(get_current_input)

    # If monitor reports 0 or error, fall back to state file
    if [ "$current" = "0" ] || [ "$current" = "error" ]; then  
        if [ -f "$STATE_FILE" ]; then
            current=$(cat "$STATE_FILE")
            echo "(Using saved state: $current)"
        else   
            echo "(Cannot read current input; assuming USB-C since you're connected)"
            current="$INPUT_USB_C"
        fi
    fi

    echo "Current input value: $current"

    if [ "$current" = "$INPUT_USB_C" ] || [ "$current" = "16" ]; then
        switch_to_dp
    elif [ "$current" = "$INPUT_DP" ] || [ "$current" = "15" ]; then
        switch_to_usbc
    else 
        echo "Unknown current input value ($current). Defaulting to switch to DisplayPort."
        switch_to_dp
    fi
}

show_status() {
    echo "=== Monitor Input Status ==="
    echo "Display: $(m1ddc display list 2>/dev/null | head -1)"
    echo "Display UUID: $DISPLAY_ID"
    local current
    current=$(get_current_input)
    echo "Current input value (from DDC): $current"
    if [ -f "$STATE_FILE" ]; then
        echo "Saved state: $(cat "$STATE_FILE")"
    fi
    echo ""
    echo "Input values (MSI MPG 321URX OLED):"
    echo "  15 = DisplayPort"
    echo "  16 = USB-C (Type-C / DP Alt Mode)"
    echo "  17 = HDMI 1"
    echo "  18 = HDMI 2"
}

# --- Main ---
check_m1ddc

case "${1:-}" in
    dp|displayport|DP)
        switch_to_dp
        ;;
    usbc|usb-c|typec|type-c|USB-C)
        switch_to_usbc
        ;;
    toggle)
        toggle_input
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        echo "Usage: $0 [dp|usbc|toggle|probe|status|help]"
        echo ""
        echo "  dp      - Switch to DisplayPort"
        echo "  usbc    - Switch to USB-C"
        echo "  toggle  - Toggle between USB-C and DisplayPort"
        echo "  status  - Show current input status"
        echo "  help    - Show this help"
        echo ""
        echo "If no argument is given, defaults to switching to DisplayPort."
        ;;
    "")
        # Default: switch to DP (most common use case - you're on USB-C and want to switch)
        switch_to_dp
        ;;
    *)
        echo "Unknown option: $1"
        echo "Run '$0 help' for usage."
        exit 1
        ;;
esac