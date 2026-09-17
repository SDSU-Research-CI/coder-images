#!/bin/bash
# Per-user desktop defaults for the vibe-coding notebook image.
#
# This runs at container start (start-notebook.d) and once at build time, because in Coder
# ${HOME} is usually a persistent volume mounted *over* the home directory baked into the
# image, so anything configured at build time is invisible to an existing workspace. Both
# invocations are idempotent and only add files and keys that are missing, so a choice the
# user made by hand is never overwritten.
#
# Everything is written as the notebook user, never as root. That matters: xfconfd creates
# ~/.config/xfce4/xfconf/xfce-perchannel-xml/ when the session starts, and if that directory
# belongs to root the daemon dies, xfce4-session cannot reach it over D-Bus, and the desktop
# opens on "Unable to load a failsafe session" instead of a panel.
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

# Directories that must belong to the notebook user for the desktop to come up. A previous
# build of this image created some of them as root, which is what broke the session.
repair_paths=(.config .config/xfce4 .config/xfce4/xfconf .config/xfce4/helpers.rc \
    .local .local/share .local/share/keyrings)

# start-notebook.d runs as whoever started the container, which is root whenever the Coder
# template asks docker-stacks to refit the user. Repair the ownership of the directories above,
# then redo this script as the notebook user so nothing is created as root in the first place.
if [ "$(id -u)" -eq 0 ]; then
    user="${NB_USER:-jovyan}"
    volume_home="$(getent passwd "$user" | cut -d: -f6)"
    volume_uid="$(id -u "$user" 2>/dev/null)" || exit 0
    volume_gid="$(id -g "$user" 2>/dev/null)" || exit 0
    if [ -n "$volume_home" ] && [ -d "$volume_home" ]; then
        for path in "${repair_paths[@]}"; do
            if [ -e "$volume_home/$path" ] && [ "$(stat -c %u "$volume_home/$path")" != "$volume_uid" ]; then
                chown -R "$volume_uid:$volume_gid" "$volume_home/$path" 2>/dev/null || true
            fi
        done
    fi
    exec su -s /bin/bash "$user" -c 'exec /usr/local/bin/vibe-desktop-defaults.sh'
fi

home="${HOME:-/home/${NB_USER:-jovyan}}"
[ -d "$home" ] && [ -w "$home" ] || exit 0

# Unprivileged, so the repair above was skipped. docker-stacks gives the notebook user
# passwordless sudo, which is the only way to heal a home an older build already made unusable
# when the container itself starts as that user.
if command -v sudo >/dev/null 2>&1; then
    for path in "${repair_paths[@]}"; do
        if [ -e "$home/$path" ] && [ ! -w "$home/$path" ]; then
            sudo -n chown -R "$(id -u):$(id -g)" "$home/$path" 2>/dev/null || true
        fi
    done
fi

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

exit 0
