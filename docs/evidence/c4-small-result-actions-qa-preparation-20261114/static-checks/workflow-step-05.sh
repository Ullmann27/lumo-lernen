set -euo pipefail
sudo apt-get -o Acquire::Retries=2 update -qq
sudo apt-get -o Acquire::Retries=2 install -y xvfb libgl1-mesa-dri libglx-mesa0 fonts-noto-color-emoji
python3 -m venv .qa-python
.qa-python/bin/python -m pip install --disable-pip-version-check Pillow==12.3.0
(cd frozen-host && flutter pub get --enforce-lockfile)
command -v xvfb-run
