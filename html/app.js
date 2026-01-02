const toast=document.getElementById('toast');
const img=document.getElementById('img');
const title=document.getElementById('title');
const sub=document.getElementById('sub');
const meta=document.getElementById('meta');
let timer=null;

window.addEventListener('message',(e)=>{
  const d=e.data||{};
  if(d.type!=='hunt:popup') return;
  img.src=d.img||'';
  title.textContent=d.title||'Hunt Reward';
  sub.textContent=d.sub||'';
  meta.textContent=d.meta||'';

  toast.classList.remove('hidden');
  requestAnimationFrame(()=>toast.classList.add('show'));

  clearTimeout(timer);
  timer=setTimeout(()=>{
    toast.classList.remove('show');
    setTimeout(()=>toast.classList.add('hidden'),200);
  }, Number(d.duration||5200));
});
