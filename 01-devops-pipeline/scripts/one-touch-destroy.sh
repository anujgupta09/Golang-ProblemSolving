#!/usr/bin/env bash
# One-touch teardown for everything one-touch.sh creates (see ../README.md).
# Run from Windows Git Bash with the Podman machine already running.
# Unlike `jenkins-env.sh reset` alone, this also removes the two resources that
# script deliberately leaves behind: the GitHub webhook and the built
# worker/controller images and copied pipeline directory in the VM.
# Best-effort: anything missing/unreachable is reported and skipped, and cleanup carries on.
#
# Output: one status line per check; raw tool output goes to a log file (path printed
# in the header and footer). VERBOSE=1 also streams it live. Same conventions as
# one-touch.sh; jenkins-env.sh reports results as "@@ OK|WARN|INFO <text>" lines.
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$here/.." && pwd)          # .../01-devops-pipeline, POSIX-style
# shellcheck source=lib/ui.sh
source "$here/lib/ui.sh"
# Env file: 1st argument, else $ENV_FILE, else config/.env (may live anywhere, e.g. outside the repo).
env_file=${1:-${ENV_FILE:-$repo_root/config/.env}}
pipeline_dir='$HOME/vdx-jenkins-pipeline-ws'
state_dir='$HOME/vdx-jenkins-pipeline-state'
pipeline_show=${pipeline_dir/'$HOME'/'~'}
state_show=${state_dir/'$HOME'/'~'}
worker_image=localhost/vdx-jenkins-worker:local
controller_image=localhost/vdx-jenkins-controller:local

[[ -f "$env_file" ]] || fail "Missing $env_file — pass its path as the 1st argument or set ENV_FILE (needed for APP_REPO_URL/NGROK_DOMAIN)."
set -a
# shellcheck source=/dev/null
source "$env_file"
set +a

machine=${PODMAN_MACHINE:-podman-machine-default}   # from the env file, read after sourcing
port=${JENKINS_PORT:-8081}

command -v podman >/dev/null || fail 'podman is required on the Windows host (Git Bash).'
command -v curl >/dev/null || fail 'curl is required on the Windows host (Git Bash).'

ui_init vdx-one-touch-destroy
ui_traps 'Cleanup may be incomplete — re-run this script.'

# vm_step <what> <command>: best-effort — a failure becomes a warning (with the last ERROR line), cleanup carries on.
vm_step() {
    local mark rc=0 reason
    mark=$(log_mark)
    run_vm "$2" || rc=$?
    render_notes "$mark"
    if (( rc != 0 )); then
        warn "$1 failed (exit $rc) — see the log"
        reason=$(log_since "$mark" | sed -n 's/^ERROR: //p' | tail -n 1)
        [[ -z $reason ]] || info "$reason"
    fi
}

# probe_vm <command>: sets probe_rc = 0 (exists), 1 (absent) or 2 (could not tell: ssh/podman itself failed).
probe_rc=0
probe_vm() {
    local rc=0
    run_vm "$1" || rc=$?
    case $rc in
        0 | 1) probe_rc=$rc ;;
        *) probe_rc=2 ;;
    esac
}

# report <ok message> <what is left> <leftovers> <unverified>: one Verify line.
report() {
    if [[ -n $3 ]]; then
        bad "$2 still exist(s):$3"
    elif [[ -n $4 ]]; then
        warn "Could not verify (VM query failed):$4"
    else
        ok "$1"
    fi
}

remove_image() {
    probe_vm "podman image exists $1"
    case $probe_rc in
        0)
            if run_vm "podman rmi -f $1"; then
                ok "Image $1 removed"
            else
                warn "Could not remove image $1 — see the log"
            fi
            ;;
        1) ok "Image $1 not present" ;;
        *) warn "Could not check image $1 (VM query failed) — see the log" ;;
    esac
}

vm_up=1
run_vm true || vm_up=0

app_repo_display=''
if [[ -n "${APP_REPO_URL:-}" ]]; then
    app_repo_display=${APP_REPO_URL#https://github.com/}
    app_repo_display=${app_repo_display%.git}
fi

printf '\nvdx one-touch teardown  |  local Jenkins CI on Podman\n'
rule '='
kv 'Podman machine' "$machine"
kv 'App repo' "${app_repo_display:-not set}"
kv 'Removes' "$pipeline_show, $state_show (VM)"
kv 'Log' "$log_file"
rule '='

payload_url=''
step '[1/4] Remove GitHub webhook'
if [[ -n "${NGROK_DOMAIN:-}" && -n "${APP_REPO_URL:-}" && -n "${APP_REPO_GIT_TOKEN:-}" ]]; then
    trigger_token=$(grep -oE "token:\s*'[^']+'" "$repo_root/Jenkinsfile" | head -n1 | sed -E "s/.*'([^']+)'.*/\1/" || true)
    app_repo_path=${APP_REPO_URL#https://github.com/}
    app_repo_path=${app_repo_path%.git}
    app_repo_owner=${app_repo_path%%/*}
    app_repo_name=${app_repo_path#*/}

    if [[ -z "$trigger_token" ]]; then
        warn "Could not read the GenericTrigger token from $repo_root/Jenkinsfile — skipping webhook deletion."
    elif [[ $app_repo_path == "${APP_REPO_URL}" ]]; then
        warn "APP_REPO_URL must look like https://github.com/<owner>/<repo>.git (got: $APP_REPO_URL) — skipping webhook deletion."
    else
        payload_url="https://${NGROK_DOMAIN}/generic-webhook-trigger/invoke?token=${trigger_token}"
        if hooks_json=$(curlj -sf -H "Authorization: token ${APP_REPO_GIT_TOKEN}" -H 'Accept: application/vnd.github+json' \
            "https://api.github.com/repos/${app_repo_owner}/${app_repo_name}/hooks"); then
            # GitHub returns pretty-printed JSON; flatten it, split top-level "}, {" onto
            # their own lines (whitespace-tolerant), then isolate the matching object.
            hook_id=$(printf '%s' "$hooks_json" | tr -d '\r\n' \
                | sed -E 's/\}[[:space:]]*,[[:space:]]*\{/}\n{/g' \
                | { grep -F "$payload_url" || true; } | head -n1 | sed -E 's/.*"id":[[:space:]]*([0-9]+).*/\1/')   # no match must not trip set -e/pipefail
            if [[ -z "$hook_id" || ! $hook_id =~ ^[0-9]+$ ]]; then
                ok 'No matching webhook found (already removed or never created)'
            elif curlj -sf -X DELETE -H "Authorization: token ${APP_REPO_GIT_TOKEN}" -H 'Accept: application/vnd.github+json' \
                "https://api.github.com/repos/${app_repo_owner}/${app_repo_name}/hooks/${hook_id}"; then
                ok "Webhook $hook_id deleted on ${app_repo_owner}/${app_repo_name}"
            else
                warn "Could not delete webhook $hook_id on ${app_repo_owner}/${app_repo_name}."
            fi
        else
            warn "Could not list webhooks on ${app_repo_owner}/${app_repo_name} — skipping webhook deletion."
            payload_url=''
        fi
    fi
else
    info 'Skipped (NGROK_DOMAIN/APP_REPO_URL/APP_REPO_GIT_TOKEN not all set in .env)'
fi

step '[2/4] Remove containers, volumes and network'
if (( vm_up )); then
    if run_vm "test -f $pipeline_dir/scripts/jenkins-env.sh"; then
        vm_step 'jenkins-env.sh reset' "bash $pipeline_dir/scripts/jenkins-env.sh reset"
    else
        ok "Nothing to reset (no pipeline copy at $pipeline_show in the VM)"
    fi
else
    warn "Podman machine '$machine' is not running/reachable — VM cleanup skipped (podman machine start $machine, then re-run)."
fi

step '[3/4] Remove built images'
if (( vm_up )); then
    remove_image "$worker_image"
    remove_image "$controller_image"
else
    info 'Skipped (Podman machine not running)'
fi

step '[4/4] Remove pipeline and state directories'
if (( vm_up )); then
    vm_step 'Removing the directories' "rm -rf $pipeline_dir $state_dir /tmp/01-devops-pipeline-onetouch"
    ok "Removed $pipeline_show and $state_show"
else
    info 'Skipped (Podman machine not running)'
fi

step 'Verify'
if (( vm_up )); then
    leftovers='' unverified=''
    for resource in vdx-jenkins vdx-worker vdx-ngrok; do
        probe_vm "podman container exists $resource"
        case $probe_rc in 0) leftovers+=" $resource" ;; 2) unverified+=" $resource" ;; esac
    done
    report 'No vdx containers remain' 'Containers' "$leftovers" "$unverified"

    leftovers='' unverified=''
    for resource in vdx-jenkins-home vdx-workspace vdx-maven-cache; do
        probe_vm "podman volume exists $resource"
        case $probe_rc in 0) leftovers+=" $resource" ;; 2) unverified+=" $resource" ;; esac
    done
    report 'No vdx volumes remain' 'Volumes' "$leftovers" "$unverified"

    leftovers='' unverified=''
    probe_vm 'podman network exists vdx-ci'
    case $probe_rc in 0) leftovers=' vdx-ci' ;; 2) unverified=' vdx-ci' ;; esac
    report 'Network vdx-ci is gone' 'Network' "$leftovers" "$unverified"

    leftovers='' unverified=''
    for resource in "$worker_image" "$controller_image"; do
        probe_vm "podman image exists $resource"
        case $probe_rc in 0) leftovers+=" $resource" ;; 2) unverified+=" $resource" ;; esac
    done
    report 'Worker and controller images are gone' 'Images' "$leftovers" "$unverified"

    leftovers='' unverified=''
    probe_vm "test -e $pipeline_dir"
    case $probe_rc in 0) leftovers+=" $pipeline_show" ;; 2) unverified+=" $pipeline_show" ;; esac
    probe_vm "test -e $state_dir"
    case $probe_rc in 0) leftovers+=" $state_show" ;; 2) unverified+=" $state_show" ;; esac
    report 'Pipeline and state directories are gone' 'Directories' "$leftovers" "$unverified"
else
    info 'VM checks skipped (Podman machine not running)'
fi

if curlj -sf -o /dev/null "http://127.0.0.1:${port}/login" 2>/dev/null; then
    bad "Something is still answering on http://127.0.0.1:${port}"
else
    ok "Nothing answering on http://127.0.0.1:${port}"
fi

if [[ -n "$payload_url" ]]; then
    hooks_json_after=$(curlj -sf -H "Authorization: token ${APP_REPO_GIT_TOKEN}" -H 'Accept: application/vnd.github+json' \
        "https://api.github.com/repos/${app_repo_owner}/${app_repo_name}/hooks" 2>/dev/null) || hooks_json_after=''
    if printf '%s' "$hooks_json_after" | grep -qF "$payload_url"; then
        bad "Webhook still present on ${app_repo_owner}/${app_repo_name}"
    else
        ok "Webhook no longer present on ${app_repo_owner}/${app_repo_name}"
    fi
fi

printf '\n'
rule '='
if (( n_bad > 0 )); then
    printf '  %sINCOMPLETE%s  (%s OK, %s failed, %s warning(s))\n' "$c_fail" "$c_off" "$n_ok" "$n_bad" "$n_warn"
elif (( n_warn > 0 )); then
    printf '  %sDONE WITH WARNINGS%s  (%s OK, %s warning(s))\n' "$c_warn" "$c_off" "$n_ok" "$n_warn"
else
    printf '  %sCLEAN%s  (%s OK)\n' "$c_ok" "$c_off" "$n_ok"
fi
rule '='
printf '  %-10s %s\n' 'Log' "$log_file"
if (( n_bad > 0 || n_warn > 0 )); then
    printf '  %-10s %s\n' 'Next' 'fix the cause above, then re-run this script'
    rule '='
    exit 1
fi
printf '  %-10s %s\n' 'Next' 'bash scripts/one-touch.sh to set up again'
rule '='
