#!/usr/bin/env python3
"""GHLauncher Web File Browser. Usage: python3 server.py [port]"""
import http.server, json, os, re, sys, urllib.parse, shutil, tempfile, zipfile, io, cgi
from datetime import datetime, timezone

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 9293
BASE = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(BASE)
MAX_UPLOAD = 200 * 1024 * 1024

FT = {
    "swift":{"c":"#FF375F","l":"swift","n":"Swift"},"kt":{"c":"#B87FFF","l":"kotlin","n":"Kotlin"},
    "kts":{"c":"#B87FFF","l":"kotlin","n":"KtScript"},"json":{"c":"#D6A53A","l":"json","n":"JSON"},
    "plist":{"c":"#5BC0DE","l":"xml","n":"Plist"},"xml":{"c":"#5BC0DE","l":"xml","n":"XML"},
    "zip":{"c":"#A0522D","l":"zip","n":"Archive"},"jar":{"c":"#A0522D","l":"zip","n":"JAR"},
    "gradle":{"c":"#02A48E","l":"groovy","n":"Gradle"},"groovy":{"c":"#02A48E","l":"groovy","n":"Groovy"},
    "md":{"c":"#4A90D9","l":"markdown","n":"Markdown"},"txt":{"c":"#9AA0A6","l":None,"n":"Text"},
    "py":{"c":"#34C759","l":"python","n":"Python"},
}
DQ=chr(34);SQ=chr(39);BS=chr(92)

def esc(s): return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace(DQ,"&quot;")
def js_esc(s): return s.replace(BS,BS+BS).replace(SQ,BS+SQ)
def gfi(name):
    e=name.rsplit(".",1)[-1].lower() if "." in name else ""
    return FT.get(e, {"c":"#9AA0A6","l":None,"n":e.upper() if e else "FILE"})
def fsz(b):
    if b<1024: return "%d B"%b
    if b<1048576: return "%.1f KB"%(b/1024.0)
    return "%.1f MB"%(b/1048576.0)

def lfiles(path):
    fp=os.path.join(PROJECT_DIR,path) if path else PROJECT_DIR
    if not os.path.isdir(fp): return [],[]
    ds,fs=[],[]
    try:
        for e in os.scandir(fp):
            if e.name.startswith("."): continue
            r=(path+"/"+e.name).replace(BS,"/") if path else e.name
            if e.is_dir(): ds.append({"name":e.name,"path":r})
            else:
                i=gfi(e.name);s=e.stat()
                fs.append({"name":e.name,"path":r,"n":i["n"],"c":i["c"],"l":i["l"],"size":s.st_size,"sz":fsz(s.st_size),"mod":datetime.fromtimestamp(s.st_mtime).strftime("%d.%m %H:%M")})
    except: pass
    ds.sort(key=lambda x:x["name"].lower());fs.sort(key=lambda x:x["name"].lower())
    return ds,fs

def rfile(path):
    fp=os.path.join(PROJECT_DIR,path)
    if not os.path.isfile(fp): return None
    try:
        with open(fp,"r",encoding="utf-8",errors="replace") as f: return f.read()
    except: return None

def rzip(path):
    fp=os.path.join(PROJECT_DIR,path)
    if not os.path.isfile(fp): return None
    try:
        zf=zipfile.ZipFile(fp,"r");ent=[]
        for zi in zf.infolist():
            id2=zi.filename.endswith("/")
            pt=zi.filename.rstrip("/").split("/")
            fn=pt[-1] if pt else zi.filename.rstrip("/")
            md=datetime(*zi.date_time).strftime("%d.%m %H:%M") if zi.date_time and zi.date_time[0]>1980 else ""
            ent.append({"n":fn,"fp":zi.filename.rstrip("/"),"size":zi.file_size,"sz":fsz(zi.file_size),"d":id2,"mod":md})
        zf.close();ent.sort(key=lambda x:(not x["d"],x["fp"].lower()));return ent
    except: return None

def hl(code, lang):
    code = esc(code)
    if lang == "swift":
        code = re.sub(r'(//[^\n]*)', r'<span class="cm">$1</span>', code)
        code = re.sub(r'(/\*[\s\S]*?\*/)', r'<span class="cm">$1</span>', code)
        code = re.sub(r'("(?:[^"\\]|\\.)*")', r'<span class="st">$1</span>', code)
        code = re.sub(r'\b(import|struct|class|enum|protocol|extension|func|var|let|init|return|if|else|guard|for|in|switch|case|break|continue|throw|try|catch|do|async|await|Task|some|any|private|public|internal|fileprivate|open|self|Self|static|override|mutating|throws|rethrows|where|actor|lazy|weak|unowned|convenience|required|get|set|didSet|willSet|typealias|subscript|prefix|infix|postfix|operator|associatedtype)\b', r'<span class="kw">$1</span>', code)
        code = re.sub(r'(@\w+)', r'<span class="at">$1</span>', code)
        code = re.sub(r'\b(true|false|nil)\b', r'<span class="lt">$1</span>', code)
        code = re.sub(r'\b([A-Z][A-Za-z0-9]*)\b', r'<span class="tp">$1</span>', code)
        code = re.sub(r'\b(\d+\.?\d*)\b', r'<span class="lt">$1</span>', code)
    elif lang == "json":
        code = re.sub(r'("(?:[^"\\]|\\.)*")(\s*:)', r'<span class="tp">$1</span>$2', code)
        code = re.sub(r'(:)\s*("(?:[^"\\]|\\.)*")', r': <span class="st">$2</span>', code)
    elif lang == "xml":
        code = re.sub(r'(&lt;!--[\s\S]*?--&gt;)', r'<span class="cm">$1</span>', code)
        code = re.sub(r'(&lt;/?)([\w-]+)', r'\1<span class="kw">$2</span>', code)
        code = re.sub(r'([\w-]+)(=)', r'<span class="tp">$1</span>$2', code)
        code = re.sub(r'(".*?")', r'<span class="st">$1</span>', code)
    elif lang == "python":
        code = re.sub(r'(#[^\n]*)', r'<span class="cm">$1</span>', code)
        code = re.sub(r'("(?:[^"\\]|\\.)*")', r'<span class="st">$1</span>', code)
    elif lang == "kotlin":
        code = re.sub(r'(//[^\n]*)', r'<span class="cm">$1</span>', code)
        code = re.sub(r'("(?:[^"\\]|\\.)*")', r'<span class="st">$1</span>', code)
        code = re.sub(r'\b(import|class|object|fun|val|var|return|if|else|when|for|in|is|as|try|catch|finally|throw|override|data|sealed|companion|interface|enum|typealias|suspend|private|protected|internal|public|open|package)\b', r'<span class="kw">$1</span>', code)
    return code

def dr(name,path):
    return '<div class="fr dir" onclick="n(\''+js_esc(path)+'\')"><div class="fi"><span class="da">\u203a</span></div><div class="bd"><div class="fn">'+esc(name)+'</div></div><div class="ar">\u203a</div></div>'
def fr_row(name,path,label,sz,mod,col,iz=False):
    jp="oz('"+js_esc(path)+"','"+esc(sz)+"')" if iz else "o('"+js_esc(path)+"','"+esc(label)+"','"+esc(sz)+"')"
    bd='<span class="eb" style="background:'+col+'18;color:'+col+'">'+esc(label)+'</span>' if label else ''
    return '<div class="fr file" onclick="'+jp+'"><div class="fi">'+bd+'</div><div class="bd"><div class="fn">'+esc(name)+'</div><div class="mt"><span>'+esc(sz)+'</span><span>'+esc(mod)+'</span></div></div><div class="ar" style="color:'+col+'">\u203a</div></div>'
def bc(path):
    p=path.split("/") if path else []
    h='<a class="cb cr" href="javascript:n(\'\')">\u2191 \u041a\u043e\u0440\u0435\u043d\u044c</a>';a=""
    for i,x in enumerate(p):
        a=(a+"/"+x) if a else x;c=(i==len(p)-1);cl=" cr" if c else ""
        h+='<span class="sp">\u203a</span><a class="cb'+cl+'" href="javascript:n(\''+js_esc(a)+'\')">'+esc(x)+'</a>'
    return h

CSS='<style>' + r'''
:root{--bg:#0A0E14;--bg2:#10141C;--bg3:#1C2233;--ac:#5BB8FF;--tx:#E5E7EB;--tx2:#6B7280;--bd:#1E2533;--ra:14px}
*{margin:0;padding:0;box-sizing:border-box;-webkit-tap-highlight-color:transparent}
body{font-family:-apple-system,BlinkMacSystemFont,"SF Pro",Roboto,sans-serif;background:var(--bg);color:var(--tx);min-height:100vh}
a{color:inherit;text-decoration:none}
#hdr{background:var(--bg2);border-bottom:1px solid var(--bd);padding:12px 16px;position:sticky;top:0;z-index:100;-webkit-backdrop-filter:blur(20px);backdrop-filter:blur(20px)}
.hr{display:flex;align-items:center;gap:10px}.lg{font-size:20px;font-weight:800;background:linear-gradient(135deg,#34C759,#5BB8FF);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
.ha{margin-left:auto;display:flex;gap:8px}.bt{background:var(--bg3);border:1px solid var(--bd);color:var(--tx);border-radius:10px;padding:8px 14px;font-size:13px;font-weight:600;cursor:pointer;display:flex;align-items:center;gap:6px;transition:background .15s}.bt:hover{background:#253041}
.bc{padding:10px 16px 6px;display:flex;flex-wrap:wrap;gap:4px;font-size:13px}.bc .sp{color:var(--tx2);opacity:.4}.bc .cb{color:var(--ac);padding:2px 6px;border-radius:6px;cursor:pointer}.bc .cb:hover{background:rgba(91,184,255,.1)}.bc .cr{color:var(--tx);font-weight:600;cursor:default;background:var(--bg3)}
.sb{display:flex;gap:10px;padding:0 16px 10px;flex-wrap:wrap}.sp2{background:var(--bg3);border:1px solid var(--bd);padding:4px 12px;border-radius:20px;font-size:12px;color:var(--tx2);display:flex;align-items:center;gap:5px}
.vt{display:flex;background:var(--bg3);border-radius:9px;border:1px solid var(--bd);overflow:hidden}.vt b{padding:6px 10px;cursor:pointer;font-size:14px;color:var(--tx2);transition:all .15s}.vt b.ac{background:var(--ac);color:#fff}
.ua{display:flex;align-items:center;justify-content:center;margin:4px 12px 10px;padding:14px;border:2px dashed var(--bd);border-radius:var(--ra);color:var(--tx2);font-size:13px;cursor:pointer;transition:border-color .2s,color .2s;background:rgba(91,184,255,.03);user-select:none}.ua:hover,.ua.over{border-color:var(--ac);color:var(--ac);background:rgba(91,184,255,.08)}
.fl{padding:6px 8px;display:flex;flex-direction:column;gap:2px}.fl.gr{display:grid;grid-template-columns:repeat(auto-fill,minmax(145px,1fr));gap:8px;padding:10px 12px}
.fr{display:flex;align-items:center;gap:12px;padding:10px 14px;border-radius:var(--ra);cursor:pointer;transition:background .12s;user-select:none}.fr:hover{background:rgba(91,184,255,.06)}
.fl.gr .fr{flex-direction:column;text-align:center;padding:16px 10px;gap:8px}.fl.gr .fi{justify-content:center}.fl.gr .fn{font-size:12px}
.fi{width:30px;height:20px;display:flex;align-items:center;justify-content:center;flex-shrink:0}.fi .eb{font-size:9px;font-weight:700;padding:2px 5px;border-radius:4px;letter-spacing:.3px;text-transform:uppercase}
.da{font-size:18px;font-weight:700;color:var(--ac);line-height:1}.bd{flex:1;min-width:0}
.fn{font-size:14px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;font-weight:500}.mt{display:flex;gap:8px;font-size:11px;color:var(--tx2);margin-top:2px}
.dir .fn{font-weight:700}.ar{color:var(--tx2);font-size:16px;opacity:.4;flex-shrink:0}
.zvh{padding:10px 16px 8px;border-bottom:1px solid var(--bd);flex-shrink:0}.zvn{font-weight:700;font-size:15px;margin-bottom:2px}.zvm{font-size:11px;color:var(--tx2)}
.zvl{flex:1;overflow:auto;-webkit-overflow-scrolling:touch;padding:4px 0}
.zed{padding:8px 16px;cursor:pointer;display:flex;align-items:center;gap:12px}.zed:hover{background:rgba(91,184,255,.06)}.zdd .fn{font-weight:700;color:var(--ac)}
.mo{position:fixed;inset:0;background:rgba(0,0,0,.6);z-index:500;display:none;justify-content:center;align-items:flex-end}.mo.show{display:flex}
@keyframes su{from{transform:translateY(100%)}to{transform:translateY(0)}}
.sh{background:var(--bg2);border-top:1px solid var(--bd);border-radius:18px 18px 0 0;width:100%;max-width:800px;height:94vh;display:none;flex-direction:column;overflow:hidden;animation:su .3s cubic-bezier(.22,1,.36,1)}.mo.show .sh{display:flex}
.hd{width:40px;height:5px;background:var(--bd);border-radius:3px;margin:10px auto;cursor:pointer;flex-shrink:0}
.mh{display:flex;align-items:center;gap:8px;padding:0 16px 10px;border-bottom:1px solid var(--bd);flex-shrink:0;flex-wrap:wrap}.tt{flex:1;font-weight:700;font-size:16px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;min-width:0}.me{font-size:11px;color:var(--tx2)}
.ma{display:flex;gap:6px}.ma button{background:var(--bg3);border:1px solid var(--bd);color:var(--tx);border-radius:8px;padding:6px 12px;font-size:12px;cursor:pointer;display:flex;align-items:center;gap:5px;transition:background .1s}.ma button:hover{background:#253041}
.cl{background:var(--bg3);border:1px solid var(--bd);color:var(--tx);width:32px;height:32px;border-radius:50%;display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:15px;flex-shrink:0}
.mbb{flex:1;overflow:auto;-webkit-overflow-scrolling:touch}
.cd{padding:14px 16px;font-family:"SF Mono","Fira Code",Menlo,Consolas,monospace;font-size:12.5px;line-height:1.7;white-space:pre;tab-size:4;overflow-x:auto}
.cm{color:#6A737D}.kw{color:#FF7AB2}.st{color:#9ECBFF}.tp{color:#66D9EF}.at{color:#BB8AFF}.lt{color:#FF9E44}
.ts{position:fixed;bottom:30px;left:50%;transform:translateX(-50%) translateY(120px);background:var(--bg3);color:var(--tx);padding:12px 22px;border-radius:12px;font-size:14px;font-weight:600;z-index:9999;transition:transform .3s;border:1px solid var(--bd);pointer-events:none}.ts.show{transform:translateX(-50%) translateY(0)}
.ep{text-align:center;padding:60px 20px;color:var(--tx2)}
::-webkit-scrollbar{width:6px}::-webkit-scrollbar-track{background:transparent}::-webkit-scrollbar-thumb{background:var(--bd);border-radius:4px}
@media(max-width:480px){.fl.gr{grid-template-columns:repeat(auto-fill,minmax(110px,1fr))}.fl.gr .fr{padding:12px 6px}.ma button span,.bt span{display:none}}
''' + '</style>'

JS = r'''<script>
var curFile="",curPath="";
document.addEventListener("DOMContentLoaded",function(){sv(localStorage.getItem("ghv")||"list")});
function sv(v){localStorage.setItem("ghv",v);document.getElementById("vL").classList.toggle("ac",v==="list");document.getElementById("vG").classList.toggle("ac",v==="grid");document.getElementById("fl").classList.toggle("gr",v==="grid")}
function n(p){location.search="p="+encodeURIComponent(p)}
function o(p,lb,sz){var x=new XMLHttpRequest();x.open("GET","/api/file?p="+encodeURIComponent(p),true);x.onload=function(){if(x.status===200){var d=JSON.parse(x.responseText);curFile=d.content;curPath=p;document.getElementById("mt").textContent=d.name;document.getElementById("me").textContent=d.lang+" \u2022 "+d.size;document.getElementById("cd").innerHTML=d.html||esc(d.content);showFileModal()}else{toast("Error loading file")}};x.onerror=function(){toast("Network error")};x.send()}
function oz(p,sz){var x=new XMLHttpRequest();x.open("GET","/api/zipview?p="+encodeURIComponent(p),true);x.onload=function(){if(x.status===200){var d=JSON.parse(x.responseText);showZipModal(d.name,sz,d.count,d.entries)}else{toast("ZIP error")}};x.send()}
function showFileModal(){document.getElementById("mo").classList.add("show");document.getElementById("zv").style.display="none";document.getElementById("fv").style.display="flex";document.body.style.overflow="hidden"}
function showZipModal(nm,sz2,cnt,entries){document.getElementById("mo").classList.add("show");document.getElementById("fv").style.display="none";var zv=document.getElementById("zv");zv.style.display="flex";document.getElementById("zvN").textContent=nm;document.getElementById("zvM").textContent=cnt+" entries, "+sz2;var list=document.getElementById("zvL");list.innerHTML="";for(var i=0;i<entries.length;i++){var e=entries[i];var row=document.createElement("div");row.className="zed"+(e.is_dir?" zdd":"");row.innerHTML='<div class="fi">'+(e.is_dir?'<span class="da">\u203a</span>':'')+'</div><div class="bd"><div class="fn">'+(e.is_dir?"[ "+esc(e.name)+" ]":esc(e.name))+'</div><div class="mt"><span>'+esc(e.sz||"")+'</span><span>'+esc(e.mod||"")+'</span></div></div>';if(!e.is_dir){row.setAttribute("data-fp",e.fp);row.onclick=function(){var a=document.createElement("a");a.href="/api/zipdl?p="+encodeURIComponent(curPath)+"\x26f="+encodeURIComponent(this.getAttribute("data-fp"));a.download=this.getAttribute("data-fp").split("/").pop();document.body.appendChild(a);a.click();a.remove()}};list.appendChild(row)};document.body.style.overflow="hidden"}
function mc(){document.getElementById("mo").classList.remove("show");document.getElementById("fv").style.display="";document.getElementById("zv").style.display="";document.body.style.overflow=""}
function cp2(){if(navigator.clipboard){navigator.clipboard.writeText(curFile).then(function(){toast("Copied!")}).catch(function(){toast("Failed")})}else{toast("Failed")}}
function dl(){var a=document.createElement("a");a.href="/api/dl?p="+encodeURIComponent(curPath);a.download=curPath.split("/").pop();document.body.appendChild(a);a.click();a.remove()}
function dz(){location.href="/api/zip"}
function toast(m){var el=document.getElementById("ts");el.textContent=m;el.classList.add("show");setTimeout(function(){el.classList.remove("show")},2000)}
function esc(s){return s.replace(/\x26/g,""+"\x26"+"amp;").replace(/</g,""+"\x26"+"lt;").replace(/>/g,""+"\x26"+"gt;").replace(/"/g,""+"\x26"+"quot;")}
document.addEventListener("keydown",function(e){if(e.key==="Escape")mc()});
var ua2=document.getElementById("upload-area");if(ua2){ua2.addEventListener("dragover",function(ev){ev.preventDefault();ua2.classList.add("over")});ua2.addEventListener("dragleave",function(){ua2.classList.remove("over")});ua2.addEventListener("drop",function(ev){ev.preventDefault();ua2.classList.remove("over");if(ev.dataTransfer.files.length)doUp(ev.dataTransfer.files[0])})}
function triggerUpload(){document.getElementById("upload-input").click()}
function doUp(file){var fd=new FormData();fd.append("file",file);toast("Uploading "+file.name+"...");var x=new XMLHttpRequest();x.open("POST","/api/upload?p="+encodeURIComponent(location.search.substring(3)||""),true);x.onload=function(){if(x.status===200){toast("Uploaded: "+file.name);setTimeout(function(){location.reload()},500)}else{toast("Upload failed: "+x.responseText)}};x.send(fd)}
</script>'''

def build_page(path):
    ds,fs=lfiles(path); tf=len(fs); td=len(ds); ts=sum(f["size"] for f in fs)
    items=""
    if path:
        p2=path.rsplit("/",1)[0]; items+=dr("..",p2)
    for d in ds: items+=dr(d["name"],d["path"])
    for f in fs: items+=fr_row(f["name"],f["path"],f["n"],f["sz"],f["mod"],f["c"],iz=(f["l"]=="zip"))
    if not items: items='<div class="ep">\u041f\u0443\u0441\u0442\u043e</div>'
    h='<!DOCTYPE html>\n<html lang="ru">\n<head>\n<meta charset="UTF-8">\n<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">\n'
    h+='<title>'+esc(path.split("/")[-1] if path else "\u041a\u043e\u0440\u0435\u043d\u044c")+'</title>\n'+CSS+'</head>\n<body>\n'
    h+='<header id="hdr"><div class="hr"><div class="lg">\u0424\u0430\u0439\u043b\u044b</div><div class="ha">'
    h+='<div class="vt"><b id="vL" class="ac">\u2630</b><b id="vG">\u229e</b></div>'
    h+='<button class="bt" onclick="dz()"><span>ZIP</span></button></div></div></header>\n'
    h+='<nav class="bc">'+bc(path)+'</nav>\n'
    h+='<div class="ua" id="upload-area" onclick="triggerUpload()">\u2b06 \u041d\u0430\u0436\u043c\u0438\u0442\u0435 \u0438\u043b\u0438 \u043f\u0435\u0440\u0435\u0442\u0430\u0449\u0438\u0442\u0435 \u0444\u0430\u0439\u043b</div>\n'
    h+='<input type="file" id="upload-input" style="display:none" onchange="if(this.files[0])doUp(this.files[0])">\n'
    h+='<div class="sb"><div class="sp2">%d \u043f\u0430\u043f\u043e\u043a</div><div class="sp2">%d \u0444\u0430\u0439\u043b\u043e\u0432</div><div class="sp2">%s</div></div>\n'%(td,tf,fsz(ts))
    h+='<div class="fl" id="fl">\n'+items+'\n</div>\n'
    h+='<div class="mo" id="mo"><div class="sh"><div class="hd" onclick="mc()"></div>'
    h+='<div id="fv" style="display:none;flex-direction:column;height:100%"><div class="mh"><div class="tt" id="mt">\u2014</div><div class="me" id="me"></div><div class="ma">'
    h+='<button onclick="cp2()"><span>\u041a\u043e\u043f\u0438\u0440\u043e\u0432\u0430\u0442\u044c</span></button>'
    h+='<button onclick="dl()"><span>\u0421\u043a\u0430\u0447\u0430\u0442\u044c</span></button></div>'
    h+='<button class="cl" onclick="mc()">\u00d7</button></div><div class="mbb"><div class="cd" id="cd"></div></div></div>'
    h+='<div id="zv" style="display:none;flex-direction:column;height:100%"><div class="zvh"><div class="zvn" id="zvN"></div><div class="zvm" id="zvM"></div></div>'
    h+='<div class="ma" style="padding:6px 16px"><button onclick="dl()"><span>\u0421\u043a\u0430\u0447\u0430\u0442\u044c ZIP</span></button></div>'
    h+='<div class="mbb"><div class="zvl" id="zvL"></div></div></div></div></div>\n'
    h+='<div class="ts" id="ts"></div>\n'+JS+'</body></html>'
    return h

class H(http.server.BaseHTTPRequestHandler):
    def log_message(self,fmt,*a): print("[%s] %s"%(datetime.now().strftime("%H:%M:%S"),a[0]))
    def do_GET(self):
        p=urllib.parse.urlparse(self.path); qs=urllib.parse.parse_qs(p.query)
        if p.path=="/api/file": self._file(qs.get("p",[""])[0])
        elif p.path=="/api/dl": self._dl(qs.get("p",[""])[0])
        elif p.path=="/api/zip": self._zip()
        elif p.path=="/api/zipview": self._zv(qs.get("p",[""])[0])
        elif p.path=="/api/zipdl": self._zdl(qs.get("p",[""])[0],qs.get("f",[""])[0])
        else: self._page(qs.get("p",[""])[0])
    def do_POST(self):
        if self.path.startswith("/api/upload"): self._up()
        else: self.send_error(405)
    def _page(self,path):
        try:
            data=build_page(path).encode("utf-8")
            self.send_response(200);self.send_header("Content-Type","text/html;charset=utf-8");self.send_header("Content-Length",str(len(data)));self.end_headers();self.wfile.write(data)
        except Exception as e: self.send_error(500,str(e))
    def _file(self,path):
        c=rfile(path)
        if c is None: self.send_response(404);self.end_headers();self.wfile.write(b"Not found");return
        nm=path.split("/")[-1];i=gfi(nm);sz=os.path.getsize(os.path.join(PROJECT_DIR,path))
        hl2=hl(c,i["l"]) if i["l"] else None
        r=json.dumps({"name":nm,"content":c,"html":hl2,"lang":i["n"] or "Text","size":fsz(sz)},ensure_ascii=False)
        d=r.encode("utf-8");self.send_response(200);self.send_header("Content-Type","application/json;charset=utf-8");self.send_header("Content-Length",str(len(d)));self.end_headers();self.wfile.write(d)
    def _dl(self,path):
        fp=os.path.join(PROJECT_DIR,path)
        if not os.path.isfile(fp): self.send_response(404);self.end_headers();return
        self.send_response(200);self.send_header("Content-Type","application/octet-stream");self.send_header("Content-Disposition",'attachment; filename="%s"'%os.path.basename(fp));self.send_header("Content-Length",str(os.path.getsize(fp)));self.end_headers()
        with open(fp,"rb") as f: self.wfile.write(f.read())
    def _zip(self):
        tmp=tempfile.mkdtemp();zp=shutil.make_archive(tmp+"/proj","zip",PROJECT_DIR)
        self.send_response(200);self.send_header("Content-Type","application/zip");self.send_header("Content-Disposition",'attachment; filename="project.zip"');self.send_header("Content-Length",str(os.path.getsize(zp)));self.end_headers()
        with open(zp,"rb") as f: self.wfile.write(f.read());shutil.rmtree(tmp)
    def _zv(self,path):
        entries=rzip(path)
        if entries is None: self.send_response(400);self.end_headers();self.wfile.write(b"Cannot read zip");return
        nm=path.split("/")[-1]
        r=json.dumps({"name":nm,"count":len(entries),"entries":entries},ensure_ascii=False)
        d=r.encode("utf-8");self.send_response(200);self.send_header("Content-Type","application/json;charset=utf-8");self.send_header("Content-Length",str(len(d)));self.end_headers();self.wfile.write(d)
    def _zdl(self,path,fname):
        fp=os.path.join(PROJECT_DIR,path)
        if not os.path.isfile(fp): self.send_response(404);self.end_headers();return
        try:
            zf=zipfile.ZipFile(fp,"r");bd=zf.read(fname);zf.close()
            self.send_response(200);self.send_header("Content-Type","application/octet-stream");self.send_header("Content-Disposition",'attachment; filename="%s"'%fname.split("/")[-1]);self.send_header("Content-Length",str(len(bd)));self.end_headers();self.wfile.write(bd)
        except: self.send_response(404);self.end_headers()
    def _up(self):
        cl=int(self.headers.get("Content-Length",0))
        ct=self.headers.get("Content-Type","")
        if "multipart/form-data" in ct:
            fs=cgi.FieldStorage(fp=self.rfile,environ={"REQUEST_METHOD":"POST"},headers={"Content-Type":ct})
            item=fs["file"];curp=urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query).get("p",[""])[0]
            dest=os.path.join(PROJECT_DIR,curp,item.filename)
            self.send_response(200);self.send_header("Content-Type","text/plain");self.end_headers();self.wfile.write(b"ok")
            with open(dest,"wb") as f: f.write(item.file.read())
        else:
            data=self.rfile.read(cl)
            fn=urllib.parse.unquote(self.headers.get("X-Filename","upload.bin"))
            curp=urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query).get("p",[""])[0]
            dest=os.path.join(PROJECT_DIR,curp,fn)
            self.send_response(200);self.send_header("Content-Type","text/plain");self.end_headers();self.wfile.write(b"ok")
            with open(dest,"wb") as f: f.write(data)

if __name__=="__main__":
    try:
        srv=http.server.ThreadingHTTPServer(("0.0.0.0",PORT),H)
        print("File Browser on port %d"%PORT);print("Project: "+PROJECT_DIR)
        srv.serve_forever()
    except OSError: print("Port %d in use"%PORT)

