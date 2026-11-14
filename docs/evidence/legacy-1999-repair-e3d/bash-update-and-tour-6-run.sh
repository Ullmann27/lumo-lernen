set -euo pipefail
sudo apt-get -o Acquire::Retries=2 update -qq
sudo apt-get -o Acquire::Retries=2 install -y xvfb mesa-utils libegl1 libgl1-mesa-dri libglx-mesa0 libpulse0 tesseract-ocr tesseract-ocr-deu tesseract-ocr-eng
python3 -m venv .update-python
.update-python/bin/python -m pip install --disable-pip-version-check uiautomator2==3.7.0 Pillow==12.3.0
.update-python/bin/python -m unittest discover -s tools/android_qa/tests -p test_update_preservation.py -v
.update-python/bin/python -m unittest discover -s tools/android_qa/tests -p test_kart_tour_evidence.py -v
.update-python/bin/python -m unittest discover -s tools/android_qa/tests -p test_modernization_tour_identity.py -v
.update-python/bin/python -m unittest discover -s scripts/tests -p test_historical_apk_expectations.py -v

