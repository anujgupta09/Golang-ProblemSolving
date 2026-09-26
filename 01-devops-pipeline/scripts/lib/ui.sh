#!/usr/bin/env bash
# Shared console + logging helpers for one-touch.sh and one-touch-destroy.sh.
# Source it (`source "$here/lib/ui.sh"`); do not run it.
#
# WHAT THE USER SEES
#   A header, then titled steps, then ONE line per check:  [ OK ]  [WARN]  [FAIL]
#   Everything the tools print (podman pulls, builds, curl, ...) goes to a log file instead.
#
# THE "@@" PROTOCOL (how VM-side results reach the screen)
#   jenkins-env.sh runs inside the Podman VM, so its output only reaches us through the log.
#   It marks the lines that matter with a prefix:
#       @@ OK <text>      -> [ OK ]  <text>
#       @@ WARN <text>    -> [WARN]  <text>
#       @@ INFO <text>    ->         <text>   (indented detail under the previous line)
#   render_notes prints those lines and ignores the rest.
#
# HOW TO USE
#   1. source this file            4. run_vm / render_notes to run things in the VM
#   2. set `machine`               5. fail "msg" for a fatal, explained exit
#   3. ui_init <log-prefix>        6. ui_traps "<hint>" to catch unexpected errors + Ctrl-C
#
# Environment knobs:  VERBOSE=1 (also stream raw output)  NO_COLOR=1  ONETOUCH_LOG=<path>

verbose=${VERBOSE:-0}
log_file=''
n_ok=0
n_warn=0
n_bad=0

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    c_ok=$'\033[32m' c_warn=$'\033[33m' c_fail=$'\033[31m' c_bold=$'\033[1m' c_off=$'\033[0m'
else
    c_ok='' c_warn='' c_fail='' c_bold='' c_off=''
fi

# --- Screen output ----------------------------------------------------------------------

rule() { printf '%*s\n' 80 '' | tr ' ' "$1"; }                       # rule '=' -> a full-width line
step() { printf '\n%s%s%s\n' "$c_bold" "$1" "$c_off"; }              # step '[2/8] Title'
kv() { printf '  %-15s %s\n' "$1" "$2"; }                            # aligned "label   value" line
info() { printf '            %s\n' "$*"; }                           # detail under the previous line
ok() { printf '  %s[ OK ]%s  %s\n' "$c_ok" "$c_off" "$*"; n_ok=$((n_ok + 1)); }
warn() { printf '  %s[WARN]%s  %s\n' "$c_warn" "$c_off" "$*"; n_warn=$((n_warn + 1)); }
bad() { printf '  %s[FAIL]%s  %s\n' "$c_fail" "$c_off" "$*"; n_bad=$((n_bad + 1)); }   # a failed check; the script goes on

# fail <message>: fatal. Explain, point to the log, exit 1.
fail() {
    printf '  %s[FAIL]%s  %s\n' "$c_fail" "$c_off" "$*" >&2
    if [[ -s "$log_file" ]]; then
        printf '\n  Full log: %s\n' "$log_file" >&2
    fi
    exit 1
}

# --- Log file ---------------------------------------------------------------------------

# ui_init <name-prefix>: create the log file (default ${TMPDIR:-/tmp}/<prefix>-<timestamp>.log).
ui_init() {
    log_file=${ONETOUCH_LOG:-${TMPDIR:-/tmp}/$1-$(date +%Y%m%d-%H%M%S).log}
    : > "$log_file"
}

log_mark() { wc -l < "$log_file"; }                                  # remember "where the log ends now"
log_since() { tail -n +"$(($1 + 1))" "$log_file" | tr -d '\r'; }     # log lines added after a mark

# --- Safety nets ------------------------------------------------------------------------

# ui_traps <hint>: an unexpected failure or Ctrl-C still ends with a clear message + log path.
# The failing command is deliberately not echoed: it could carry credentials.
ui_traps() {
    ui_hint=$1
    set -E                                                            # so the ERR trap also fires inside functions
    trap 'ui_on_error $? $LINENO' ERR
    trap 'ui_on_interrupt' INT TERM
}
ui_on_error() {
    printf '\n  %s[FAIL]%s  Unexpected error (exit %s) near line %s. %s\n' "$c_fail" "$c_off" "$1" "$2" "$ui_hint" >&2
    printf '  Full log: %s\n' "$log_file" >&2
    exit "$1"
}
ui_on_interrupt() {
    printf '\n  %s[FAIL]%s  Interrupted. %s\n  Full log: %s\n' "$c_fail" "$c_off" "$ui_hint" "$log_file" >&2
    exit 130
}

# curl with timeouts, so an unreachable host can never hang a script.
curlj() { curl --connect-timeout 5 --max-time 30 "$@"; }

# --- Running things in the Podman VM ----------------------------------------------------

# run_vm <command>: run in the VM (needs $machine). Raw output -> log (and screen if VERBOSE=1).
# Returns the command's exit code; callers decide whether that is fatal.
run_vm() {
    local rc=0
    if (( verbose )); then
        MSYS_NO_PATHCONV=1 podman machine ssh "$machine" -- "$1" 2>&1 | tee -a "$log_file" || rc=$?
    else
        MSYS_NO_PATHCONV=1 podman machine ssh "$machine" -- "$1" >> "$log_file" 2>&1 || rc=$?
    fi
    return "$rc"
}

# render_notes <mark>: turn the "@@ ..." lines written to the log since <mark> into screen lines.
render_notes() {
    local line kind text
    while IFS= read -r line; do
        kind=${line%% *}
        text=${line#* }
        case $kind in
            OK) ok "$text" ;;
            WARN) warn "$text" ;;
            INFO) info "$text" ;;
        esac
    done < <(log_since "$1" | sed -n 's/^@@ //p')
}

# step_failed <what> <exit code>: fatal, with the last log lines on screen.
step_failed() {
    printf '  %s[FAIL]%s  %s (exit %s)\n' "$c_fail" "$c_off" "$1" "$2" >&2
    printf '\n  Last lines of the log:\n' >&2
    tail -n 25 "$log_file" | tr -d '\r' | sed 's/^/    | /' >&2
    printf '\n  Full log: %s\n' "$log_file" >&2
    exit 1
}
