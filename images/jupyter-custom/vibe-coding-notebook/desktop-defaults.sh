#!/bin/bash
# Per-user desktop defaults for the vibe-coding notebook image.
#
# This runs at container start (start-notebook.d) and again when the XFCE session starts
# (autostart), because in Coder ${HOME} is usually a persistent volume mounted *over* the
# home directory baked into the image, so anything configured at build time is invisible to
# an existing workspace. Both invocations are idempotent and only add keys/files that are
# missing, so a choice the user made by hand is never overwritten.
#
# 1. GNOME Keyring. There is no PAM login in a container, so the daemon has no password to
#    unlock the Login keyring with and no keyring to reuse. The first app that tries to
#    store a secret (Chrome, OpenCode, VS Code, the Copilot app) therefore D-Bus-activates
#    gcr-prompter and blocks on a "choose a password for your keyring" dialog that nobody
#    knows the answer to. Writing the keyring with an empty password makes the daemon unlock
#    it silently; secrets then persist in ~/.local/share/keyrings/login.keyring as plaintext,
#    which is the right trade in a single-user teaching container.
# 2. GNOME Terminal as XFCE's preferred terminal emulator (Thunar's "Open Terminal Here",
#    the desktop's "Open Terminal", the XFCE menu). The *Dismissed keys also stop
#    xfce4-session from asking "a new preferred application was detected, use it?".

set -u

# start-notebook.d runs as whoever started the container, which is root when the Coder
# template asks docker-stacks to refit the user, so resolve the notebook user's home
# explicitly instead of trusting $HOME.
if [ "$(id -u)" -eq 0 ]; then
    home="$(getent passwd "${NB_USER:-jovyan}" | cut -d: -f6)"
else
    home="${HOME:-/home/${NB_USER:-jovyan}}"
fi
[ -n "$home" ] && [ -d "$home" ] && [ -w "$home" ] || exit 0

# --- 1. empty-password Login keyring -------------------------------------------------------
keyrings="$home/.local/share/keyrings"
login_keyring="$keyrings/login.keyring"
# A keyring this script wrote always starts with the [keyring] section header. Anything else
# is encrypted with a password nobody has (typically because the prompt above was answered
# once), so move it aside rather than leaving the user stuck on it.
if [ ! -f "$login_keyring" ] || [ "$(head -n 1 "$login_keyring" 2>/dev/null)" != "[keyring]" ]; then
    [ -f "$login_keyring" ] && mv "$login_keyring" "$login_keyring.bak"
    mkdir -p "$keyrings"
    chmod 700 "$keyrings"
    printf '[keyring]\ndisplay-name=Login\nctime=%s\nmtime=0\nlock-on-idle=false\nlock-after=false\n' \
        "$(date +%s)" >"$login_keyring"
    chmod 600 "$login_keyring"
fi

# --- 2. preferred applications -------------------------------------------------------------
helpers="$home/.config/xfce4/helpers.rc"
mkdir -p "$(dirname "$helpers")"
if [ ! -f "$helpers" ] || ! head -n 1 "$helpers" | grep -q '^\[Preferred Applications\]'; then
    printf '[Preferred Applications]\n' >"$helpers.tmp"
    [ -f "$helpers" ] && cat "$helpers" >>"$helpers.tmp"
    mv "$helpers.tmp" "$helpers"
fi
for setting in \
    TerminalEmulator=gnome-terminal \
    TerminalEmulatorDismissed=true \
    WebBrowser=firefox \
    WebBrowserDismissed=true; do
    key="${setting%%=*}"
    grep -q "^${key}=" "$helpers" || printf '%s\n' "$setting" >>"$helpers"
done

# When this ran as root (start-notebook.d in a refit container) the files it created belong
# to root and the notebook user could not replace them later. Touch only the paths this
# script owns -- never the whole ~/.config tree, which can be a large mounted volume.
if [ "$(id -u)" -eq 0 ]; then
    chown -R --reference="$home" "$keyrings" 2>/dev/null || true
    chown --reference="$home" "$(dirname "$helpers")" "$helpers" 2>/dev/null || true
fi

exit 0
