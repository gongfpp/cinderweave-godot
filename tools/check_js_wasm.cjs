const fs=require('node:fs'); const path=require('node:path'); const vm=require('node:vm');
const dir=process.argv[2];
(async()=>{
 let js=0;
 for(const name of fs.readdirSync(dir).filter(x=>x.endsWith('.js'))){new vm.Script(fs.readFileSync(path.join(dir,name),'utf8'),{filename:name});js++;}
 const html=fs.readFileSync(path.join(dir,'index.html'),'utf8');let inline=0;
 for (const match of html.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/g)){if(match[1].trim()){new vm.Script(match[1]);inline++;}}
 const bytes=fs.readFileSync(path.join(dir,'index.wasm'));
 if(!WebAssembly.validate(bytes)) throw Error('WASM validation failed');
 const mod=await WebAssembly.compile(bytes);
 console.log(JSON.stringify({node:process.version,js_files_syntax_passed:js,inline_scripts_syntax_passed:inline,wasm_validation:true,wasm_compilation:true,wasm_imports:WebAssembly.Module.imports(mod).length,wasm_exports:WebAssembly.Module.exports(mod).length,instantiated:false,browser_runtime_tested:false},null,2));
})().catch(e=>{console.error(e);process.exitCode=1;});
