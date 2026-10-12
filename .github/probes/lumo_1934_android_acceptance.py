#!/usr/bin/env python3
import argparse
from pathlib import Path
import subprocess
import sys

parser=argparse.ArgumentParser()
parser.add_argument('--baseline',required=True)
parser.add_argument('--candidate',required=True)
parser.add_argument('--out',required=True)
a=parser.parse_args()
folder=Path(__file__).resolve().parent
subprocess.run([sys.executable,str(folder/'lumo_education_android_probe.py'),
    '--baseline',a.baseline,'--candidate',a.candidate,'--out',a.out],check=True)
subprocess.run([sys.executable,str(folder/'lumo_games_android_probe.py'),
    '--out',a.out],check=True)
