set -eu
umask 077
test "$#" -eq 1
case "$1" in ''|*[!0-9]*) exit 92;; esac
test "$(getprop init.svc.console)" = running
test -x /system/bin/toybox && test -x /system/bin/logcat
mkdir /data/local/tmp/lumo-runtime-0f5db71dd3eb2366ebcc19cf1a2ddf0a
exec > /data/local/tmp/lumo-runtime-0f5db71dd3eb2366ebcc19cf1a2ddf0a/launch.stdout 2> /data/local/tmp/lumo-runtime-0f5db71dd3eb2366ebcc19cf1a2ddf0a/launch.stderr
printf '%s\n' "$1" > /data/local/tmp/lumo-runtime-0f5db71dd3eb2366ebcc19cf1a2ddf0a/console.pid
cat > /data/local/tmp/lumo-runtime-0f5db71dd3eb2366ebcc19cf1a2ddf0a/run.sh <<'LUMO_LOGGER_SOURCE'
#!/system/bin/sh
set -u
umask 077
unset ANDROID_LOG_TAGS
cd /data/local/tmp/lumo-runtime-0f5db71dd3eb2366ebcc19cf1a2ddf0a || exit 91
printf '%s\n' "$$" > session.pid
: > wait.stderr
/system/bin/logcat -b all -v threadtime > logcat.stdout 2> logcat.stderr &
logger=$!
printf '%s\n' "$logger" > logger.pid
attempt=0
while [ ! -s logcat.stdout ] && [ "$attempt" -lt 50 ]; do
  sleep 0.1
  attempt=$((attempt + 1))
done
if [ -s logcat.stdout ]; then printf 'ready\n' > ready; fi
wait "$logger" 2> wait.stderr
result=$?
printf '%s\n' "$result" > logger.exit
exit "$result"
LUMO_LOGGER_SOURCE
/system/bin/toybox nohup /system/bin/toybox setsid /system/bin/sh /data/local/tmp/lumo-runtime-0f5db71dd3eb2366ebcc19cf1a2ddf0a/run.sh > /data/local/tmp/lumo-runtime-0f5db71dd3eb2366ebcc19cf1a2ddf0a/session.stdout 2> /data/local/tmp/lumo-runtime-0f5db71dd3eb2366ebcc19cf1a2ddf0a/session.stderr < /dev/null &
attempt=0
while [ ! -s /data/local/tmp/lumo-runtime-0f5db71dd3eb2366ebcc19cf1a2ddf0a/ready ] && [ "$attempt" -lt 100 ]; do
  sleep 0.1
  attempt=$((attempt + 1))
done
test -s /data/local/tmp/lumo-runtime-0f5db71dd3eb2366ebcc19cf1a2ddf0a/ready
