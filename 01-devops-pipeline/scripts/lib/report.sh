#!/usr/bin/env bash
# The header and the closing summary printed by one-touch.sh.
# Source it (`source "$here/lib/report.sh"`); do not run it.
# Needs lib/ui.sh, plus machine, port, vm_pipeline, vm_state, job_name, log_file, APP_REPO_URL,
# JENKINS_ADMIN_USER (all set by one-touch.sh before these functions are called).

print_header() {
    local repo=${APP_REPO_URL#https://github.com/} pipeline_show=${vm_pipeline/'$HOME'/'~'} state_show=${vm_state/'$HOME'/'~'}
    repo=${repo%.git}
    printf '\nvdx one-touch  |  local Jenkins CI on Podman\n'
    rule '='
    kv 'Podman machine' "$machine"
    kv 'Jenkins' "http://127.0.0.1:${port}"
    kv 'App repo' "$repo"
    kv 'Pipeline dir' "$pipeline_show      (VM)"
    kv 'State dir' "$state_show   (VM, mode 700)"
    kv 'Log' "$log_file"
    rule '='
}

print_summary() {
    printf '\n'
    rule '='
    if (( n_warn == 0 )); then
        printf '  %sREADY%s  (%s OK)\n' "$c_ok" "$c_off" "$n_ok"
    else
        printf '  %sREADY%s  (%s OK, %s warning%s)\n' "$c_ok" "$c_off" "$n_ok" "$n_warn" "$([[ $n_warn == 1 ]] || printf s)"
    fi
    rule '='
    printf '  %-10s %-28s %s\n' 'Jenkins' "http://localhost:${port}" "user: ${JENKINS_ADMIN_USER}"
    printf '  %-10s %-28s %s\n' 'Agent' 'vdx-worker' 'connected'
    printf '  %-10s %-28s %s\n' 'Job' "$job_name" 'present'
    printf '  %-10s %s\n' 'Tunnel' 'up'
    printf '  %-10s %s\n' 'Log' "$log_file"
    printf '\n'
    printf '  %-10s %s\n' 'Next' 'push a release-X.Y.Z tag to trigger a build'
    printf '  %-10s %s\n' 'Tear down' 'bash scripts/one-touch-destroy.sh'
    rule '='
}
