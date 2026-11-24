from pathlib import Path
import ast,subprocess,hashlib,json,yaml
root=Path('/workspace/scratch/909ddb52fe7b/lumo-upstream057-review')
paths=['.github/workflows/lumo-connect-four-2020.yml','scripts/verify_connect_four_delivery.py','scripts/tests/test_connect_four_delivery.py','scripts/tests/test_connect_four_pipeline.py']
def show(rev,p):return subprocess.check_output(['git','show',rev+':'+p],cwd=root,text=True)
def nodes(text):
 t=ast.parse(text)
 return {n.name:ast.get_source_segment(text,n) for n in t.body if isinstance(n,(ast.FunctionDef,ast.AsyncFunctionDef,ast.ClassDef))}
old=show('1e22d2455937e2640d1e44e153d290746f3afe49',paths[1]);up=show('057a4e8d067872c4f3514b126aa04c3706d2e5b5',paths[1]);now=(root/paths[1]).read_text()
a,b,c=map(nodes,(old,up,now))
doc=yaml.safe_load((root/paths[0]).read_text())
workflow_steps={name:[s['name'] for s in job.get('steps',[]) if 'name' in s] for name,job in doc['jobs'].items()}
t=ast.parse(now); constants={}
for n in t.body:
 if isinstance(n,ast.Assign) and len(n.targets)==1 and isinstance(n.targets[0],ast.Name):
  k=n.targets[0].id
  try: constants[k]=ast.literal_eval(n.value)
  except (ValueError, TypeError): pass
  if k=='REQUIRED_STEPS':
   for q in ast.walk(n.value):
    if isinstance(q,ast.Name) and q.id in constants:
     pass
   expression=compile(ast.Expression(n.value),'REQUIRED_STEPS','eval')
   required=eval(expression,{'__builtins__':{}},constants)
r={'head':show('HEAD','config/godot-source.json').strip(),
 'actual_identity':subprocess.check_output(['git','show','-s','--format=%H%n%T%n%P','HEAD'],cwd=root,text=True).splitlines(),
 'files':[{ 'path':p,'git_blob':subprocess.check_output(['git','rev-parse','HEAD:'+p],cwd=root,text=True).strip(),'sha256':hashlib.sha256((root/p).read_bytes()).hexdigest()} for p in paths],
 'old_function_count':len(a),'unchanged_old_functions':[k for k in a if a[k]==c.get(k)],
 'changed_old_functions':[k for k in a if a[k]!=c.get(k)],
 'new_functions':[k for k in c if k not in a],
 'discovery_function_exact_upstream':b['checked_native_discovery']==c['checked_native_discovery'],
 'dream_function_unchanged':a['checked_native_dream']==c['checked_native_dream'],
 'required_steps':[{ 'job':job,'name':s,'occurrences':workflow_steps[job].count(s)} for job,steps in required.items() for s in steps],
 'collector_calls':(root/paths[0]).read_text().count('python3 tools/collect_discovery_connections.py'),
 'old_discovery_runner_calls':(root/paths[0]).read_text().count('bash tools/validate_discovery_connections.sh'),
 'live_runner_calls':(root/paths[0]).read_text().count('bash tools/validate_live_connections.sh'),
 'new_discovery_tests_exact_upstream':b.get('DiscoveryOriginalBoundaryTests')==c.get('DiscoveryOriginalBoundaryTests'),
 'validation':'Read-only source/AST/byte comparison. No test or engine execution.'}
td=nodes((root/paths[2]).read_text());tu=nodes(show('057a4e8d067872c4f3514b126aa04c3706d2e5b5',paths[2]))
r['new_discovery_tests_exact_upstream']=td['DiscoveryOriginalBoundaryTests']==tu['DiscoveryOriginalBoundaryTests']
r['live_negative_test_names']=[n.name for n in ast.parse(td['NativeLiveConnectionEvidenceTests']).body[0].body if isinstance(n,ast.FunctionDef) and n.name.startswith('test_')]
print(json.dumps(r,indent=2))
