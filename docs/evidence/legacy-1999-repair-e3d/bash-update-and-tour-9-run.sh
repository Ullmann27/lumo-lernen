set -euo pipefail
Xvfb :99 -screen 0 1920x1080x24 -nolisten tcp +extension GLX > update-proof/xvfb.log 2>&1 &
for attempt in $(seq 1 20); do
  if glxinfo -B > update-proof/mesa-renderer.txt 2>&1; then break; fi
  sleep 1
done
grep -i 'OpenGL renderer string' update-proof/mesa-renderer.txt

