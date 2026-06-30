#!/usr/bin/env python3
"""
rebuild_db.py — Rebuild chiraag_e_azaa.db from data.js

Usage:
    python3 scripts/rebuild_db.py --input path/to/data.js --output assets/chiraag_e_azaa.db

Run this whenever you update data.js with new lyrics, then re-ship the app
or deliver the new .db file via a remote update mechanism.
"""
import argparse, re, base64, gzip, json, sqlite3, os, sys

DB_VERSION = 1  # Bump this when schema changes

CATS = [
    ('nouhay','Nouhay','🌙',1),('nouhaDarHaal','Nouha Dar Haal','💧',2),
    ('marsias','Marsias','📜',3),('manqabat','Manqabat','⭐',4),
    ('qasiday','Qasiday','🕌',5),('duas','Dua & Amal','🤲',6),
    ('salaam','Salaam','✋',7),('munaejaat','Munaejaat','🌹',8),
    ('ziyaraat','Ziyaraat','🕋',9),('oldNouhay','Bayazi Nouhay','📻',10),
    ('urduMarsiye','Urdu Marsiye','📖',11),
]

def is_rtl(html):
    stripped = re.sub(r'<div[^>]*id="urduTextPath"[^>]*>[\s\S]*?<\/div>','',html,flags=re.I)
    return 1 if len(re.findall(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]',stripped))>50 else 0

def build(input_path, output_path):
    print(f"Reading {input_path}...")
    with open(input_path,'r',encoding='utf-8') as f:
        content = f.read()

    idx_m = re.search(r'const LYRICS_INDEX=(\[[\s\S]*?\]);',content)
    if not idx_m: sys.exit("ERROR: LYRICS_INDEX not found")
    index = json.loads(idx_m.group(1))
    print(f"  {len(index)} index entries")

    b64_m = re.search(r'const CONTENT_B64="([^"]+)"',content)
    if not b64_m: sys.exit("ERROR: CONTENT_B64 not found")
    lyric_content = json.loads(gzip.decompress(base64.b64decode(b64_m.group(1))).decode('utf-8'))
    print(f"  {len(lyric_content)} content entries")

    if os.path.exists(output_path): os.remove(output_path)
    conn = sqlite3.connect(output_path)
    c = conn.cursor()
    c.execute(f'PRAGMA user_version = {DB_VERSION}')

    c.execute('CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, key TEXT NOT NULL UNIQUE, label TEXT NOT NULL, icon TEXT NOT NULL, sort_order INTEGER NOT NULL DEFAULT 0)')
    c.executemany('INSERT INTO categories (key,label,icon,sort_order) VALUES (?,?,?,?)', CATS)
    c.execute('CREATE TABLE artists (id INTEGER PRIMARY KEY AUTOINCREMENT, category_key TEXT NOT NULL, name TEXT NOT NULL, UNIQUE(category_key,name), FOREIGN KEY(category_key) REFERENCES categories(key))')
    c.execute('CREATE TABLE lyrics (id INTEGER PRIMARY KEY, category_key TEXT NOT NULL, artist_id INTEGER, year TEXT, title TEXT NOT NULL, content_html TEXT, is_rtl INTEGER NOT NULL DEFAULT 0, FOREIGN KEY(category_key) REFERENCES categories(key), FOREIGN KEY(artist_id) REFERENCES artists(id))')
    c.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)')
    c.executemany('INSERT INTO settings VALUES (?,?)',[('ltr_font_size','19'),('rtl_font_size','46'),('para_spacing','0'),('line_height','1.9'),('app_version','1.0')])

    artist_cache = {}
    def get_artist(cat_key, name):
        k=(cat_key,name)
        if k not in artist_cache:
            c.execute('INSERT OR IGNORE INTO artists (category_key,name) VALUES (?,?)',(cat_key,name))
            c.execute('SELECT id FROM artists WHERE category_key=? AND name=?',(cat_key,name))
            artist_cache[k]=c.fetchone()[0]
        return artist_cache[k]

    rows=[]
    for entry in index:
        lid,cat_path,title=entry
        parts=cat_path.split('/')
        cat_key=parts[0]
        artist_id=get_artist(cat_key,parts[1]) if len(parts)>=2 else None
        year=parts[2] if len(parts)>=3 else None
        html=lyric_content.get(str(lid),'')
        rows.append((lid,cat_key,artist_id,year,title,html,is_rtl(html)))

    c.executemany('INSERT INTO lyrics (id,category_key,artist_id,year,title,content_html,is_rtl) VALUES (?,?,?,?,?,?,?)',rows)
    c.execute("CREATE VIRTUAL TABLE lyrics_fts USING fts5(title,content='lyrics',content_rowid='id')")
    c.execute("INSERT INTO lyrics_fts(lyrics_fts) VALUES('rebuild')")
    c.execute('CREATE INDEX idx_lyrics_category ON lyrics(category_key)')
    c.execute('CREATE INDEX idx_lyrics_artist ON lyrics(artist_id)')
    c.execute('CREATE INDEX idx_artists_category ON artists(category_key)')

    conn.commit(); conn.close()
    size_mb=os.path.getsize(output_path)/1024/1024
    print(f"\nDatabase written: {output_path}")
    print(f"  Lyrics: {len(rows)} | Artists: {len(artist_cache)} | Size: {size_mb:.1f} MB")

if __name__=='__main__':
    ap=argparse.ArgumentParser()
    ap.add_argument('--input',default='data.js')
    ap.add_argument('--output',default='assets/chiraag_e_azaa.db')
    args=ap.parse_args()
    build(args.input,args.output)
