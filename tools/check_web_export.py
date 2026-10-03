#!/usr/bin/env python3
"""Read-only structural and PCK v3 integrity checks, not browser acceptance."""
import argparse, hashlib, json, re, struct
from pathlib import Path
p=argparse.ArgumentParser(); p.add_argument('web',type=Path); p.add_argument('--compare',type=Path); args=p.parse_args()
def sha(b): return hashlib.sha256(b).hexdigest()
def inspect(root):
 files={x.name:{'bytes':x.stat().st_size,'sha256':sha(x.read_bytes())} for x in sorted(root.iterdir()) if x.is_file()}
 html=(root/'index.html').read_text()
 assert 'const GODOT_THREADS_ENABLED = false;' in html
 assert 'a8c00b3224e7fdba7801d3aeb6e76ffa70118976' in html
 cfg=json.loads(re.search(r'const GODOT_CONFIG = (.*?);',html).group(1))
 assert cfg['ensureCrossOriginIsolationHeaders'] is False and not cfg.get('serviceWorker') and not cfg['gdextensionLibs']
 assert cfg['fileSizes']['index.pck']==files['index.pck']['bytes']
 assert cfg['fileSizes']['index.wasm']==files['index.wasm']['bytes']
 for ref in re.findall(r'(?:src|href)="([^"]+)"',html):
  assert not re.match(r'(?:https?:)?//',ref),ref
  assert (root/ref).is_file(),ref
 b=(root/'index.pck').read_bytes()
 magic,ver,major,minor,patch,flags=struct.unpack_from('<6I',b)
 assert (magic,ver,major,minor,patch,flags)==(0x43504447,3,4,6,3,2)
 base,pos=struct.unpack_from('<QQ',b,24)
 count,=struct.unpack_from('<I',b,pos);pos+=4
 entries=[]
 for i in range(count):
  n,=struct.unpack_from('<I',b,pos);pos+=4
  name=b[pos:pos+n].rstrip(b'\0').decode();pos+=n
  offset,size=struct.unpack_from('<QQ',b,pos);pos+=16
  md5=b[pos:pos+16].hex();pos+=16
  flags,=struct.unpack_from('<I',b,pos);pos+=4
  assert flags==0,(name,flags)
  data=b[base+offset:base+offset+size]
  assert len(data)==size and hashlib.md5(data).hexdigest()==md5,name
  assert not any(x in name for x in ['tests/','fixtures/','evidence/','docs/']),name
  entries.append({'path':name,'bytes':size,'sha256':sha(data),'pck_md5_verified':True})
 assert any(x['path']=='main.tscn' for x in entries)
 assert any('Cinderweave-NotoSansSC' in x['path'] for x in entries)
 assert sum(x['path'].endswith('.gdc') for x in entries)==5
 return {'files':files,'pack_entries':entries,'config':cfg,'threads':False,'pwa':False,'browser_runtime_tested':False}
out=inspect(args.web)
if args.compare:
 other=inspect(args.compare)
 assert out==other,'Export mismatch'
 out['independent_clean_exports_identical']=True
print(json.dumps(out,ensure_ascii=False,indent=2))
