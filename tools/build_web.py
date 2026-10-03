#!/usr/bin/env python3
"""Build and test in a fresh local copy; emit only runtime files and licenses."""
import argparse, hashlib, json, os, shutil, subprocess, tempfile
from pathlib import Path

TEMPLATE_SHA = '1446f79dc12f60ce5d244c39fb6628ec298337ca5c4f91a16491feea72aa1bc9'
ENGINE_SHA = 'f64d4ed19fc9df9440321653fcc80df8c6e365ba7b6de0a29e2cfa9fa71bfeb3'
ENGINE_VERSION = '4.6.3.stable.official.7d41c59c4'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--godot', default='godot')
p.add_argument('--template', type=Path, required=True)
p.add_argument('--work-parent', type=Path, required=True)
a = p.parse_args()
repo = Path(__file__).resolve().parent.parent
engine = Path(shutil.which(a.godot) or a.godot).resolve()
assert sha(engine) == ENGINE_SHA, 'Unexpected Godot binary'
assert sha(a.template) == TEMPLATE_SHA, 'Unexpected Web release template'
a.work_parent.mkdir(parents=True, exist_ok=True)
root = Path(tempfile.mkdtemp(prefix='cinderweave-', dir=a.work_parent.resolve()))
project = root/'run'/'cinderweave'; project.mkdir(parents=True)
(root/'inputs').mkdir(); (root/'web').mkdir(); (root/'logs').mkdir()
for name in ['data', 'config', 'cache']:
    (root/'runtime'/name).mkdir(parents=True)
for name in ['project.godot', 'main.tscn']:
    shutil.copy2(repo/name, project/name)
for name in ['scripts', 'assets', 'tests']:
    shutil.copytree(repo/name, project/name, ignore=shutil.ignore_patterns('*.json'))
(project/'tests'/'fixtures').mkdir(exist_ok=True)
shutil.copy2(a.template, root/'inputs'/'web_nothreads_release.zip')
(project/'export_presets.cfg').write_text((repo/'tools'/'export_presets.cfg').read_text())
with (project/'project.godot').open('a') as f:
    f.write('\n[editor]\nexport/convert_text_resources_to_binary=false\n')
env = os.environ.copy()
for key, name in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
    env[key] = str(root/'runtime'/name)
assert subprocess.check_output([str(engine), '--version'], env=env, text=True).strip() == ENGINE_VERSION

def run(name, command):
    log = root/'logs'/f'{name}.log'
    with log.open('w') as f:
        subprocess.run(command, env=env, stdout=f, stderr=subprocess.STDOUT, check=True)
    text = log.read_text()
    assert 'ERROR:' not in text and 'SCRIPT ERROR:' not in text, text
    print(name + ': PASS')
    return text

run('import', [str(engine), '--headless', '--editor', '--path', str(project), '--import'])
for name in ['test_rules', 'test_ui', 'test_independent_ui']:
    log = run(name, [str(engine), '--headless', '--path', str(project), '--script', 'res://tests/'+name+'.gd'])
    assert 'FAILURES 0' in log, log
run('export', [str(engine), '--headless', '--path', str(project), '--export-release', 'Web', str(root/'web'/'index.html')])
run('pck-integrity', ['python3', str(repo/'tools'/'check_web_export.py'), str(root/'web')])
run('js-wasm', ['node', str(repo/'tools'/'check_js_wasm.cjs'), str(root/'web')])
baseline = json.loads((repo/'tools'/'m1-baseline.json').read_text())
for name, expected in baseline['exported_files'].items():
    assert sha(root/'web'/name) == expected['sha256'], 'M1 runtime mismatch: '+name
    assert (root/'web'/name).stat().st_size == expected['bytes'], name
(root/'web'/'licenses').mkdir()
for name in ['GODOT_LICENSE.txt', 'GODOT_THIRD_PARTY.txt', 'Noto-CJK-LICENSE.txt']:
    shutil.copy2(repo/'third_party'/name, root/'web'/'licenses'/name)
(root/'web'/'.nojekyll').touch()
info = dict(baseline)
info.update({'repository': 'gongfpp/cinderweave-godot', 'repository_commit': os.environ.get('GITHUB_SHA', 'local-uncommitted'), 'workflow_run_id': os.environ.get('GITHUB_RUN_ID'), 'workflow_run_attempt': os.environ.get('GITHUB_RUN_ATTEMPT'), 'runtime_matches_m1_candidate': True})
(root/'web'/'build-info.json').write_text(json.dumps(info, ensure_ascii=False, indent=2)+'\n')
files = sorted(p for p in (root/'web').rglob('*') if p.is_file())
(root/'web'/'SHA256SUMS.txt').write_text(''.join(sha(p)+'  '+p.relative_to(root/'web').as_posix()+'\n' for p in files))
result = {'web': str(root/'web'), 'engine': ENGINE_VERSION, 'runtime_files_identical': len(baseline['exported_files']), 'browser_accepted': False}
print(json.dumps(result, indent=2))
if os.environ.get('GITHUB_OUTPUT'):
    with open(os.environ['GITHUB_OUTPUT'], 'a') as f:
        f.write('web='+str(root/'web')+'\n')
