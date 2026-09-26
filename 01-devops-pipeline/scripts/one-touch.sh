#!/usr/bin/env bash
# One-touch setup of the local Jenkins CI (see ../README.md).
# Run from Windows Git Bash with the Podman machine already running.
#
# HOW THIS FILE IS ORGANISED (read top to bottom, or jump to `main` at the very end)
#   1. Configuration     read the .env file, validate it, set defaults
#   2. Preflight         cheap checks that fail early, before anything is created
#   3. Stages 1-8        one function per stage; each prints its own [ OK ] lines
#   4. main              the 8 stages in order, then the summary
#
# The plumbing lives in lib/ so this file is just the automation:
#   lib/ui.sh        console lines, log file, the "@@" protocol (see its header)
#   lib/jenkins.sh   vm / jenv / wait_for / jenkins_api
#   lib/report.sh    header and summary
# The work inside the VM is done by jenkins-env.sh; this script drives it over `podman machine ssh`.
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$here/.." && pwd)          # .../01-devops-pipeline, POSIX-style
# shellcheck source=lib/ui.sh
source "$here/lib/ui.sh"          # console lines + log file
# shellcheck source=lib/jenkins.sh
source "$here/lib/jenkins.sh"     # run things in the VM, talk to Jenkins, wait_for
# shellcheck source=lib/report.sh
source "$here/lib/report.sh"      # header + closing summary

# ============================================================================================
# 1. Configuration
# ============================================================================================

# Env file: 1st argument, else $ENV_FILE, else config/.env (may live anywhere, e.g. outside the repo).
env_file=${1:-${ENV_FILE:-$repo_root/config/.env}}
[[ -f "$env_file" ]] || fail "Missing $env_file — pass its path as the 1st argument, set ENV_FILE, or copy config/.env.example to config/.env and fill it in."
set -a
# shellcheck source=/dev/null
source "$env_file"
set +a

for required in JENKINS_ADMIN_USER JENKINS_ADMIN_PASSWORD PIPELINE_REPO_URL PIPELINE_REPO_BRANCH \
    PIPELINE_REPO_GIT_USERNAME PIPELINE_REPO_GIT_TOKEN APP_REPO_URL APP_REPO_GIT_USERNAME \
    APP_REPO_GIT_TOKEN DOCKERHUB_USERNAME DOCKERHUB_TOKEN; do
    [[ -n "${!required:-}" ]] || fail "$required is not set in .env"
done
[[ ${#JENKINS_ADMIN_PASSWORD} -ge 8 ]] || fail 'JENKINS_ADMIN_PASSWORD must be at least 8 characters (Jenkins requirement).'
[[ -n "${NGROK_AUTHTOKEN:-}" ]] || fail 'NGROK_AUTHTOKEN is not set in .env (required: GitHub reaches Jenkins only through the ngrok tunnel)'
[[ -n "${NGROK_DOMAIN:-}" ]] || fail 'NGROK_DOMAIN is not set in .env (required: your ngrok Dev Domain, e.g. your-name.ngrok-free.dev)'

machine=${PODMAN_MACHINE:-podman-machine-default}   # from the env file, read after sourcing
port=${JENKINS_PORT:-8081}
job_name=${JOB_NAME:-vdx-release}
job_script_path=${JOB_SCRIPT_PATH:-01-devops-pipeline/Jenkinsfile}
pipeline_repo_cred_id=${PIPELINE_REPO_CRED_ID:-github-compvalidator-anuj-pat}
app_repo_cred_id=${APP_REPO_CRED_ID:-github-java-maven-sample-app-pat}
registry_cred_id=${REGISTRY_CRED_ID:-dockerhub-anujdocker9799}

# Where things live inside the VM. Single-quoted on purpose: the VM's shell expands $HOME.
vm_pipeline='$HOME/vdx-jenkins-pipeline-ws'            # copy of this folder
vm_state='$HOME/vdx-jenkins-pipeline-state'            # secrets + build contexts (mode 700)
vm_staging=/tmp/01-devops-pipeline-onetouch            # temporary landing spot for the copy

command -v podman >/dev/null || fail 'podman is required on the Windows host (Git Bash).'
command -v curl >/dev/null || fail 'curl is required on the Windows host (Git Bash).'

ui_init vdx-one-touch
ui_traps 'Re-run to continue (every step is idempotent).'

# ============================================================================================
# 2. Preflight
# ============================================================================================
# Fail early on problems that would otherwise surface minutes later (step 8) or as an unreadable
# ssh error. Silent when everything is fine. Also computes the values the webhook step needs.

preflight() {
    [[ $port =~ ^[0-9]+$ ]] || fail "JENKINS_PORT must be numeric (got: $port)"
    [[ -f "$repo_root/Jenkinsfile" ]] || fail "Jenkinsfile not found in $repo_root"

    trigger_token=$(grep -oE "token:\s*'[^']+'" "$repo_root/Jenkinsfile" | head -n1 | sed -E "s/.*'([^']+)'.*/\1/" || true)
    [[ -n "$trigger_token" ]] || fail "Could not read the GenericTrigger token from $repo_root/Jenkinsfile (expected: token: '…')"

    app_repo_path=${APP_REPO_URL#https://github.com/}
    [[ $app_repo_path != "$APP_REPO_URL" ]] || fail "APP_REPO_URL must look like https://github.com/<owner>/<repo>.git for webhook automation (got: $APP_REPO_URL)"
    app_repo_path=${app_repo_path%.git}
    app_repo_owner=${app_repo_path%%/*}
    app_repo_name=${app_repo_path#*/}
    [[ -n $app_repo_owner && -n $app_repo_name && $app_repo_name != "$app_repo_path" ]] \
        || fail "Could not parse owner/repo out of APP_REPO_URL: $APP_REPO_URL"
    payload_url="https://${NGROK_DOMAIN}/generic-webhook-trigger/invoke?token=${trigger_token}"

    run_vm true || fail "Podman machine '$machine' is not running or not reachable. Start it with: podman machine start $machine"

    hooks_json=$(curlj -sf -H "Authorization: token ${APP_REPO_GIT_TOKEN}" -H 'Accept: application/vnd.github+json' \
        "https://api.github.com/repos/${app_repo_owner}/${app_repo_name}/hooks") \
        || fail "Cannot list webhooks on ${app_repo_owner}/${app_repo_name}. Check APP_REPO_URL, network access to api.github.com, and that APP_REPO_GIT_TOKEN has webhook admin rights (step 8 needs it)."
}

# ============================================================================================
# 3. Stages
# ============================================================================================

stage_1_stage_files() {
    step '[1/8] Stage pipeline files'
    local mark copied local_root
    local_root=$(cd -- "$repo_root" && pwd -W)                        # Windows-style path for `podman machine cp`

    vm 'Clearing the VM staging area' "rm -rf $vm_staging"
    mark=$(log_mark)
    podman machine cp "$local_root" "$machine:$vm_staging" >> "$log_file" 2>&1 || step_failed 'Copying the pipeline folder into the VM' $?
    copied=$(log_since "$mark" | grep -c '100%' || true)
    vm 'Moving the pipeline folder into place' "rm -rf \"$vm_pipeline\" && mv $vm_staging \"$vm_pipeline\""

    if (( copied > 0 )); then
        ok "Copied $copied files into the VM native filesystem"
    else
        ok 'Copied the pipeline folder into the VM native filesystem'
    fi
}

stage_2_prepare() {
    step '[2/8] Prepare images, network and volumes'
    jenv prepare "JENKINS_PORT=$port"
}

stage_3_credentials() {
    step '[3/8] Deliver credentials'
    local credentials
    credentials=$(
        printf 'JENKINS_ADMIN_USER=%s\n' "$JENKINS_ADMIN_USER"
        printf 'JENKINS_ADMIN_PASSWORD=%s\n' "$JENKINS_ADMIN_PASSWORD"
        printf 'PIPELINE_REPO_URL=%s\n' "$PIPELINE_REPO_URL"
        printf 'PIPELINE_REPO_BRANCH=%s\n' "$PIPELINE_REPO_BRANCH"
        printf 'PIPELINE_REPO_CRED_ID=%s\n' "$pipeline_repo_cred_id"
        printf 'PIPELINE_REPO_GIT_USERNAME=%s\n' "$PIPELINE_REPO_GIT_USERNAME"
        printf 'PIPELINE_REPO_GIT_TOKEN=%s\n' "$PIPELINE_REPO_GIT_TOKEN"
        printf 'APP_REPO_CRED_ID=%s\n' "$app_repo_cred_id"
        printf 'APP_REPO_GIT_USERNAME=%s\n' "$APP_REPO_GIT_USERNAME"
        printf 'APP_REPO_GIT_TOKEN=%s\n' "$APP_REPO_GIT_TOKEN"
        printf 'REGISTRY_CRED_ID=%s\n' "$registry_cred_id"
        printf 'DOCKERHUB_USERNAME=%s\n' "$DOCKERHUB_USERNAME"
        printf 'DOCKERHUB_TOKEN=%s\n' "$DOCKERHUB_TOKEN"
        printf 'JOB_NAME=%s\n' "$job_name"
        printf 'JOB_SCRIPT_PATH=%s\n' "$job_script_path"
    )
    vm_send_state 'Sending credentials to the VM' "$credentials"
    ok 'Sent over stdin to the VM (never an argument, never in shell history)'
}

stage_4_controller() {
    step '[4/8] Start Jenkins controller'
    jenv controller

    wait_for 'controller HTTP up' 90 controller_http_ok vdx-jenkins
    ok 'HTTP endpoint responding'
    wait_for 'admin login via JCasC' 30 admin_login_ok vdx-jenkins
    ok 'JCasC admin login verified'
    wait_for "job $job_name exists" 30 job_exists vdx-jenkins
    ok "Job $job_name created by Job DSL"
}

stage_5_agent() {
    step '[5/8] Start build agent'
    jenv agent

    wait_for 'vdx-worker online' 60 worker_online vdx-worker
    ok 'Agent status: Connected'
}

stage_6_probe() {
    step '[6/8] Probe build environment'
    jenv probe
}

# Stage 7: one manual build makes Jenkins read the Jenkinsfile, which is what registers the
# GenericTrigger (it is declared inside the Jenkinsfile). NOT_BUILT or SUCCESS is healthy.
stage_7_first_build() {
    step '[7/8] First build (registers the GenericTrigger)'
    trigger_first_build
    wait_for 'first build to finish' 180 first_build_finished vdx-jenkins
    report_first_build
}

# State used by stage 7 (triggering the first build). Temp files are removed on exit.
last_build_before=0
crumb_cookie_file=$(mktemp)
trigger_body_file=$(mktemp)
trap 'rm -f "$crumb_cookie_file" "$trigger_body_file"' EXIT

trigger_first_build() {
    local json crumb_json crumb_field crumb response
    # Remember the current build number so the wait can't mistake an older build's result (rerun) for ours.
    if json=$(jenkins_api "job/${job_name}/lastBuild/api/json?tree=number,result" 2> /dev/null); then
        last_build_before=$(printf '%s' "$json" | sed -E 's/.*"number":([0-9]+).*/\1/')
    fi

    crumb_json=$(curlj -sf -c "$crumb_cookie_file" -u "${JENKINS_ADMIN_USER}:${JENKINS_ADMIN_PASSWORD}" "http://127.0.0.1:${port}/crumbIssuer/api/json") \
        || fail 'Could not fetch a CSRF crumb from the controller.'
    crumb_field=$(printf '%s' "$crumb_json" | sed -E 's/.*"crumbRequestField":"([^"]+)".*/\1/')
    crumb=$(printf '%s' "$crumb_json" | sed -E 's/.*"crumb":"([^"]+)".*/\1/')
    response=$(curlj -s -b "$crumb_cookie_file" -o "$trigger_body_file" -w '%{http_code}' \
        -u "${JENKINS_ADMIN_USER}:${JENKINS_ADMIN_PASSWORD}" -H "${crumb_field}: ${crumb}" \
        -X POST "http://127.0.0.1:${port}/job/${job_name}/build") || response=000   # 000 = no HTTP response at all
    [[ $response == 2* ]] || fail "Could not trigger a build of $job_name (HTTP $response): $(cat "$trigger_body_file" 2> /dev/null)"
}

first_build_finished() {
    local json number result
    json=$(jenkins_api "job/${job_name}/lastBuild/api/json?tree=number,result" 2> /dev/null) || return 1
    number=$(printf '%s' "$json" | sed -E 's/.*"number":([0-9]+).*/\1/')
    [[ $number =~ ^[0-9]+$ && $number -gt $last_build_before ]] || return 1
    result=$(printf '%s' "$json" | sed -E 's/.*"result":"([A-Z_]+)".*/\1/')
    [[ -n $result && $result != "$json" ]]
}

report_first_build() {
    local json result console_text reasons console_url line
    json=$(jenkins_api "job/${job_name}/lastBuild/api/json?tree=number,result") || fail 'Could not read the build result after it finished.'
    result=$(printf '%s' "$json" | sed -E 's/.*"result":"([A-Z_]+)".*/\1/')

    case $result in
        NOT_BUILT) ok 'Result: NOT_BUILT (expected: no unpublished release-*.* tag exists yet)'; return ;;
        SUCCESS) ok 'Result: SUCCESS'; return ;;
    esac

    # Anything else: find out why. Save the console (minus Jenkins' hidden console-note markers) to the log.
    console_text=$(jenkins_api "job/${job_name}/lastBuild/consoleText" 2> /dev/null | tr -d '\r' | sed 's/\x1b\[8m[^\x1b]*\x1b\[0m//g') || console_text=''
    printf '\n--- first build console ---\n%s\n' "$console_text" >> "$log_file"
    # Jenkins' "ERROR:" lines plus podman's own "Error:" lines (the real cause of "exit code 125"), shortened.
    reasons=$(printf '%s\n' "$console_text" | grep -aE '^(ERROR|Error):|^fatal:|^stderr: (remote|fatal):' | sed -E 's/^(ERROR|Error|stderr): *//' | cut -c1-140 | awk '!seen[$0]++' | head -n 4) || reasons=''
    console_url="http://127.0.0.1:${port}/job/${job_name}/lastBuild/console"

    if [[ $console_text == *'[Pipeline] Start of Pipeline'* ]]; then
        # The Jenkinsfile was loaded, so the trigger IS registered; a later stage failed
        # (e.g. an unpublished release-* tag exists and its release build broke).
        warn "Result: $result (the Jenkinsfile ran, so the GenericTrigger is registered)"
        while IFS= read -r line; do [[ -z $line ]] || info "$line"; done <<< "$reasons"
        info "Console: $console_url"
        return
    fi

    # The Jenkinsfile never loaded (usually the SCM checkout): the trigger is NOT registered.
    printf '  %s[FAIL]%s  Result: %s. Jenkins could not load the Jenkinsfile, so the GenericTrigger is NOT registered\n' "$c_fail" "$c_off" "$result" >&2
    printf '            and the webhook would do nothing.\n' >&2
    while IFS= read -r line; do [[ -z $line ]] || printf '            %s\n' "$line" >&2; done <<< "$reasons"
    if [[ $console_text == *'Authentication failed'* || $console_text == *'Invalid username or token'* ]]; then
        printf '            GitHub rejected the credentials: PIPELINE_REPO_GIT_TOKEN / PIPELINE_REPO_GIT_USERNAME in .env are wrong or expired.\n' >&2
    fi
    printf '            Check PIPELINE_REPO_URL, PIPELINE_REPO_BRANCH and JOB_SCRIPT_PATH in .env: the branch must exist on the\n' >&2
    printf '            remote, contain %s, and the PAT must be able to read it.\n' "$job_script_path" >&2
    printf '            Console: %s\n' "$console_url" >&2
    printf '            The environment is still up; fix .env and re-run (idempotent), or tear it down.\n' >&2
    printf '\n  Full log: %s\n' "$log_file" >&2
    exit 1
}

stage_8_webhook_and_tunnel() {
    local code message
    step '[8/8] Webhook and tunnel'
    # app_repo_owner/name, payload_url and hooks_json come from the preflight.

    if printf '%s' "$hooks_json" | grep -qF "$payload_url"; then
        ok "Webhook already exists on ${app_repo_owner}/${app_repo_name} for this payload URL (left as-is)"
    else
        code=$(curlj -s -X POST -H "Authorization: token ${APP_REPO_GIT_TOKEN}" -H 'Accept: application/vnd.github+json' \
            "https://api.github.com/repos/${app_repo_owner}/${app_repo_name}/hooks" \
            -d "{\"name\":\"web\",\"active\":true,\"events\":[\"create\"],\"config\":{\"url\":\"${payload_url}\",\"content_type\":\"json\"}}" \
            -o "$trigger_body_file" -w '%{http_code}') || code=000
        if [[ $code != 2* ]]; then
            message=$(sed -n 's/.*"message": *"\([^"]*\)".*/\1/p' "$trigger_body_file" | head -n 1)
            printf '\n--- webhook create response (HTTP %s) ---\n' "$code" >> "$log_file"
            cat "$trigger_body_file" >> "$log_file" 2> /dev/null || true
            fail "Could not create the webhook on ${app_repo_owner}/${app_repo_name} (HTTP ${code}${message:+: $message}). 403/404 usually means APP_REPO_GIT_TOKEN lacks webhook write access (classic PAT: admin:repo_hook or repo; fine-grained: Webhooks read+write); 422 means a webhook for this URL already exists or GitHub rejected the URL."
        fi
        ok "Webhook created on ${app_repo_owner}/${app_repo_name} (branch/tag creation events)"
    fi

    vm_send_state 'Sending the ngrok credentials to the VM' "$(printf 'NGROK_AUTHTOKEN=%s\nNGROK_DOMAIN=%s\n' "$NGROK_AUTHTOKEN" "$NGROK_DOMAIN")"
    jenv tunnel-up
    wait_for 'ngrok tunnel up' 30 tunnel_ok vdx-ngrok
    ok 'Tunnel up'
    info "Public URL     https://${NGROK_DOMAIN}"
    info 'Forwarding to  vdx-jenkins:8080'
    info 'Inspector      http://localhost:4041'
    info "Payload URL    ${payload_url}"
}

# ============================================================================================
# 4. main
# ============================================================================================

main() {
    print_header
    preflight
    stage_1_stage_files
    stage_2_prepare
    stage_3_credentials
    stage_4_controller
    stage_5_agent
    stage_6_probe
    stage_7_first_build
    stage_8_webhook_and_tunnel
    print_summary
}

main
