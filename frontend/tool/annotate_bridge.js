(function(){if(window.__ihAnnot)return;var W=window,D=document,S='ieltshub-annot',C={yellow:'#FBE3A6',green:'#CDEBD6',blue:'#CFE3F2',pink:'#F7D0D8'},down=0,sel=0,st,vt;
function post(m){m.source=S;m.v=1;try{if(W.IELTSHubAnnot)IELTSHubAnnot.postMessage(JSON.stringify(m));else parent.postMessage(m,'*')}catch(e){}}
function txt(){return D.body?D.body.textContent:''}
function rc(r){return{x:r.left,y:r.top,w:r.width,h:r.height}}
function sentence(t,q){var i=t.indexOf(q),a,b,e=/[.!?\n]/;if(i<0)return q;a=i;while(a>0&&!e.test(t.charAt(a-1)))a--;b=i+q.length;while(b<t.length&&!e.test(t.charAt(b)))b++;return t.slice(a,b+1).trim()}
function report(){var s=W.getSelection(),raw=s?String(s):'',t=raw.trim();if(!t||!s.rangeCount||t.length>300){post({type:'selectionCleared'});return}
var r=s.getRangeAt(0),p=D.createRange(),k,f=txt(),n;p.selectNodeContents(D.body);p.setEnd(r.startContainer,r.startOffset);k=p.toString().length+(raw.length-raw.replace(/^\s+/,'').length);
n=r.commonAncestorContainer;if(n.nodeType!=1)n=n.parentNode;while(n&&n!=D.body&&!/^(P|LI|H\d|TD|DIV|SECTION)$/.test(n.tagName))n=n.parentNode;
post({type:'selection',text:t,sentence:sentence((n||D.body).textContent,t),prefix:f.slice(Math.max(0,k-32),k),suffix:f.slice(k+t.length,k+t.length+32),start:k,rect:rc(r.getBoundingClientRect())})}
function slideKey(){var h=location.hash.replace(/[^A-Za-z0-9_-]/g,'').slice(0,39),l,i,b,c,m=innerHeight/2;if(h)return'h'+h;l=D.querySelectorAll('[data-slide],section');if(l.length<2)return null;
for(i=0;i<l.length;i++){b=l[i].getBoundingClientRect();c=getComputedStyle(l[i]);if(b.height>0&&b.top<=m&&b.bottom>=m&&c.visibility!='hidden'&&+c.opacity>.5)return's'+i}return null}
function vp(){post({type:'viewport',scrollY:W.scrollY,height:innerHeight,docHeight:D.documentElement.scrollHeight,slideKey:slideKey()})}
function soon(t){clearTimeout(vt);vt=setTimeout(vp,t||200)}
function nodes(){var w=D.createTreeWalker(D.body,4,null),a=[],x,o=0;while(x=w.nextNode()){a.push({n:x,o:o});o+=x.nodeValue.length}return a}
function find(h,f){var i=f.indexOf(h.quote),best=-1,sc=-1,s;while(i>=0){s=(h.prefix&&f.slice(0,i).slice(-h.prefix.length)==h.prefix?2:0)+(h.suffix&&f.substr(i+h.quote.length,h.suffix.length)==h.suffix?2:0)+(i==h.start?1:0);if(s>sc){sc=s;best=i}i=f.indexOf(h.quote,i+1)}return best}
function unmark(id){var l=D.querySelectorAll('mark[data-ann-id="'+id+'"]'),i,m;for(i=0;i<l.length;i++){m=l[i];while(m.firstChild)m.parentNode.insertBefore(m.firstChild,m);m.parentNode.removeChild(m)}D.body.normalize()}
function mark(h){unmark(h.id);var a=nodes(),f='',i,s,e,x,u,v,m;for(i=0;i<a.length;i++)f+=a[i].n.nodeValue;s=find(h,f);if(s<0){post({type:'highlightMissing',id:h.id});return}e=s+h.quote.length;
for(i=a.length-1;i>=0;i--){x=a[i];u=Math.max(s,x.o)-x.o;v=Math.min(e,x.o+x.n.nodeValue.length)-x.o;if(v<=u)continue;var r=D.createRange();r.setStart(x.n,u);r.setEnd(x.n,v);m=D.createElement('mark');m.setAttribute('data-ann-id',h.id);m.style.cssText='border-radius:2px;cursor:pointer;color:inherit;background:'+(C[h.color]||C.yellow);r.surroundContents(m)}}
function run(c){var i;if(!c||c.source!='ieltshub-host')return;if(c.type=='applyHighlights')for(i=0;i<c.items.length;i++)mark(c.items[i]);
else if(c.type=='removeHighlight')unmark(c.id);else if(c.type=='clearSelection'){i=W.getSelection();if(i)i.removeAllRanges()}
else if(c.type=='lockScroll')D.documentElement.style.overflow=D.body.style.overflow=c.on?'hidden':'';}
W.__ihAnnot=run;W.addEventListener('message',function(e){var d=e.data;if(e.source!==parent)return;if(typeof d=='string')try{d=JSON.parse(d)}catch(x){return}run(d)});
D.addEventListener('selectionchange',function(){sel=1;clearTimeout(st);if(!down)st=setTimeout(report,250)});
function on(l,f){l.split(' ').forEach(function(t){W.addEventListener(t,f,true)})}
on('pointerdown mousedown',function(e){sel=0;if(e.type=='mousedown')down=1});
// Vừa kéo chọn chữ: giấu lần thả tay khỏi script của file (nhiều file coi kéo ngang là vuốt chuyển slide).
on('pointerup mouseup touchend',function(e){if(e.type!='pointerup'){down=0;setTimeout(report,0)}if(sel&&String(W.getSelection()).trim())e.stopPropagation()});
D.addEventListener('click',function(e){var m=e.target.closest&&e.target.closest('mark[data-ann-id]');if(m)post({type:'highlightTap',id:m.getAttribute('data-ann-id'),rect:rc(m.getBoundingClientRect())});soon(450)},true);
on('scroll resize',function(){soon()});on('keyup',function(){soon(450)});if(D.body)D.body.style.webkitTouchCallout='none';soon()})();
