#!/usr/bin/env python3
"""Deterministic, text-searchable PDF source archive of every tracked repository file."""
import hashlib, json, os, re, subprocess, textwrap
from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A3, landscape
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

ROOT=Path.cwd()
OUT=ROOT/"argon-pdf"
OUT.mkdir(exist_ok=True)
PROJECT=os.environ.get("ARGON_PROJECT",ROOT.name)
SHA=subprocess.check_output(["git","rev-parse","HEAD"],text=True).strip()
FONT="/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
pdfmetrics.registerFont(TTFont("ArgonMono",FONT))
W,H=landscape(A3)
FONT_SIZE=7.05
LINE=9.5
COLS=260
MAX_PAGES=650
SECRET=re.compile(r"(?i)(^|/)(?:\.env(?:\..*)?|[^/]*\.(?:pem|p12|pfx|keystore|jks|privatekey)|[^/]*service[_-]?account[^/]*\.json)$")
BINARY_EXT={".png",".jpg",".jpeg",".webp",".gif",".mp4",".webm",".mov",".m4a",".mp3",".wav",".ogg",".flac",".ttf",".woff",".woff2",".otf",".glb",".gltf-binary",".blend",".blend1",".apk",".aab",".zip",".gz",".jar",".so",".dll",".exe",".pdf",".class",".pb",".bin",".db",".sqlite",".sqlite3",".ico",".icns",".aseprite",".psd",".sketch",".hdr",".exr",".ktx",".ktx2",".basis",".pck",".tresbinary",".ttf",".7z",".rar",".tar"}
paths=[x.decode("utf-8","surrogateescape") for x in subprocess.check_output(["git","ls-files","-z"]).split(b"\0") if x]
manifest=[]
for path in paths:
    f=ROOT/path
    if not f.is_file():
        manifest.append(dict(path=path,kind="MISSING_OR_SUBMODULE",size=0,sha256=""))
        continue
    data=f.read_bytes()
    encrypted=bool(SECRET.search(path))
    binary=Path(path).suffix.lower() in BINARY_EXT or b"\0" in data[:8192]
    decoded=None
    if not binary and not encrypted:
        try:
            decoded=data.decode("utf-8")
        except UnicodeDecodeError:
            binary=True
    kind="EXCLUDED_SENSITIVE" if encrypted else "BINARY_INVENTORY" if binary else "SOURCE_TEXT"
    sha=hashlib.sha256(data).hexdigest()
    manifest.append(dict(path=path,kind=kind,size=len(data),sha256=sha,git_blob=subprocess.check_output(["git","hash-object","--",path],text=True).strip()))
    if kind=="SOURCE_TEXT":
        manifest[-1]["lines"]=len(decoded.splitlines())
manifest.sort(key=lambda x:x["path"])
(OUT/f"{PROJECT}_COMPLETE_MANIFEST.json").write_text(json.dumps({"project":PROJECT,"git_commit":SHA,"files":manifest},ensure_ascii=False,indent=2))
class Book:
    def __init__(self,label):
        self.label=label
        self.volume=0
        self.page=0
        self.y=0
        self.c=None
        self.files=[]
        self._new_volume()
    def _new_volume(self):
        if self.c is not None:
            self.c.save()
        self.volume+=1
        self.page=0
        self.path=OUT/f"{PROJECT}_{self.label}_{self.volume:02d}.pdf"
        self.files.append(str(self.path))
        self.c=canvas.Canvas(str(self.path),pagesize=(W,H),pageCompression=1,invariant=1)
        self.c.setTitle(f"Lumo {PROJECT} {self.label} {self.volume} - {SHA}")
    def _new_page(self):
        if self.page>=MAX_PAGES:
            self._new_volume()
        if self.page:
            self.c.showPage()
        self.page+=1
        self.c.setFont("ArgonMono",9)
        self.c.setFillColorRGB(.06,.17,.31)
        self.c.drawString(26,H-25,f"LUMO | {PROJECT} | {self.label} | Commit {SHA[:14]}")
        self.c.setFont("ArgonMono",8)
        self.c.drawRightString(W-25,H-25,f"Band {self.volume} - Seite {self.page}")
        self.c.setStrokeColorRGB(.75,.82,.9)
        self.c.line(26,H-30,W-26,H-30)
        self.c.setFont("ArgonMono",7)
        self.c.drawString(26,18,f"Originale Git-Dateipfade, UTF-8-Quelltext | Lumo / Gemini Argon - Audit")
        self.y=H-46
    def line(self,value="",color=(.10,.13,.18)):
        safe="".join(ch if ch.isprintable() or ch=="\t" else " " for ch in value.expandtabs(4))
        segments=[safe[i:i+COLS] for i in range(0,len(safe),COLS)] or [""]
        for chunk in segments:
            if self.page==0 or self.y<35:
                self._new_page()
            self.c.setFont("ArgonMono",FONT_SIZE)
            self.c.setFillColorRGB(*color)
            self.c.drawString(27,self.y,chunk)
            self.y-=LINE
    def heading(self,value):
        self.line("")
        self.line("="*min(COLS,155),(.20,.36,.60))
        self.line(value,(.06,.27,.53))
        self.line("="*min(COLS,155),(.20,.36,.60))
    def finish(self):
        self.c.save()
        return self.files

books={}
book=Book("SOURCE")
book.line("VOLLVOLLSTAENDIGER VERSIONIERTER UTF-8 QUELLCODE - Pfade/Hashes im MANIFEST")
book.line("Kopierbarer PDF-Text; Zeilen ueber 260 Zeichen werden visuell umgebrochen.")
book.line("Bytegenaue Wiederherstellung nur ueber Git-Commit und Manifest-Pruefsummen.")
book.line("Geheimschluessel/Keystores nie in ein Forschungspaket exportieren.")
codes=0
for ent in manifest:
    if ent["kind"]!="SOURCE_TEXT":
        continue
    path=ent["path"]
    content=(ROOT/path).read_text("utf-8")
    book.heading(f"DATEI: {path} | SHA256 {ent['sha256']} | {ent['size']} Bytes | {ent['lines']} Zeilen")
    for line in content.splitlines():
        book.line(line)
    if not content.endswith("\n"):
        book.line("[Ende der Datei: letzte Zeile ohne Newline]",(.50,.3,.12))
    codes+=1
books["source"]=book.finish()

man=Book("MANIFEST")
man.line("KOMPLETTES GIT-DATEIINVENTAR - JEDE GETRACKTE DATEI")
man.line(f"Projekt {PROJECT}, SHA {SHA}, Dateien {len(manifest)}, Text {codes}")
man.line("BINARY_INVENTORY bedeutet: volle Binardatei verbleibt im Original-Repository.")
man.line("EXCLUDED_SENSITIVE bedeutet: Schluessel/Keystore/Umgebungsgeheimnis niemals kopieren.")
for kind in ("SOURCE_TEXT","BINARY_INVENTORY","EXCLUDED_SENSITIVE","MISSING_OR_SUBMODULE"):
    items=[ent for ent in manifest if ent["kind"]==kind]
    man.heading(f"{kind} - {len(items)} DATEIEN")
    for ent in items:
        man.line(f"{ent['path']} | {ent['size']} B | sha256:{ent['sha256']} | git:{ent.get('git_blob','')}")
books["manifest"]=man.finish()

try:
    from PIL import Image, ImageOps
    from reportlab.lib.utils import ImageReader
    key_assets=[]
    for e in manifest:
        p=e["path"].lower()
        if e["kind"]!="BINARY_INVENTORY" or not p.endswith((".png",".jpg",".jpeg",".webp")):
            continue
        rank=0
        if "/lumo/reference/" in p or "/lumo_design/fox/" in p: rank=4
        elif "screenshots/" in p or "sonnenhafen" in p: rank=3
        elif "kart" in p and ("reference" in p or "render" in p): rank=2
        if rank: key_assets.append((rank,e))
    key_assets=sorted(key_assets,key=lambda z:(-z[0],z[1]["path"]))[:48]
    out=OUT/f"{PROJECT}_VISUAL_REFERENCES.pdf"
    c=canvas.Canvas(str(out),pagesize=(W,H),pageCompression=1,invariant=1)
    for index,(rank,e) in enumerate(key_assets):
        if index%4==0:
            if index:c.showPage()
            c.setFont("ArgonMono",12)
            c.drawString(30,H-26,f"LUMO VISUALREFERENZEN | {PROJECT} | {SHA[:14]}")
        try:
            im=Image.open(ROOT/e["path"]).convert("RGB")
            im.thumbnail((970,580))
            x=30+(index%2)*575
            y=H-410-(index%4//2)*384
            c.drawImage(ImageReader(im),x+5,y+45,width=min(im.width,550),height=min(im.height,285),preserveAspectRatio=True,anchor="c")
            c.setFont("ArgonMono",6.7)
            short=e["path"][:93]
            c.drawString(x+5,y+26,short)
            c.drawString(x+5,y+13,f"sha256 {e['sha256'][:32]}... ")
        except Exception:
            pass
    c.save()
    books["visual"]=[str(out)]
except Exception as exc:
    print("VISUAL WARN",type(exc).__name__,exc)
print(json.dumps({"project":PROJECT,"commit":SHA,"total_files":len(manifest),"text_files":codes,"binary_files":sum(x["kind"]=="BINARY_INVENTORY" for x in manifest),"pdfs":books},indent=2))
