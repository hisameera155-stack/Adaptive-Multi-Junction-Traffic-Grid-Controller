const $=id=>document.getElementById(id);
let running=true, emergency=false, tick=0;
const phases=['NS GREEN','NS YELLOW','ALL RED','EW GREEN','EW YELLOW','ALL RED','PEDESTRIAN'];
const base={green:5,yellow:2,red:2,ped:3};
let A={phase:2,t:0,ped:0,density:2},B={phase:2,t:0,ped:0,density:2};
let wave=0,waveDelay=3,pedQueueA=false,pedQueueB=false,lastPed='B';
function greenTime(j){return Math.min(10,Math.max(3,3+j.density));}
function duration(j){return j.phase===0||j.phase===3?greenTime(j):j.phase===1||j.phase===4?base.yellow:j.phase===6?base.ped:base.red;}
function request(j,who){j.ped=1; if(who==='A')pedQueueA=true; else pedQueueB=true;}
function stepJ(j,isA){
  if(emergency){j.phase=2;j.t=0;j.ped=0;return;}
  j.t++;
  if(j.t<duration(j)) return;
  j.t=0;
  if(j.phase===0)j.phase=1;
  else if(j.phase===1)j.phase=2;
  else if(j.phase===2){
    if(j.ped){j.phase=6;j.ped=0;}
    else j.phase=isA?3:0;
  } else if(j.phase===3)j.phase=4;
  else if(j.phase===4)j.phase=5;
  else if(j.phase===5){if(j.ped){j.phase=6;j.ped=0;}else j.phase=0;}
  else if(j.phase===6)j.phase=5;
}
function arbitrate(){
  if(!pedQueueA&&!pedQueueB)return;
  if(pedQueueA&&pedQueueB){if(lastPed==='B'){A.ped=1;pedQueueA=false;lastPed='A';}else{B.ped=1;pedQueueB=false;lastPed='B';}}
  else if(pedQueueA){A.ped=1;pedQueueA=false;lastPed='A';}
  else {B.ped=1;pedQueueB=false;lastPed='B';}
}
function renderJ(j,prefix,stateEl,timeEl,pedEl){
  $(stateEl).textContent=phases[j.phase];$(timeEl).textContent=`${j.t}/${duration(j)}`;$(pedEl).textContent=j.phase===6?'ACTIVE':j.ped?'QUEUED':'IDLE';
  const map=[['r',false],['y',false],['g',false],['er',false],['ey',false],['eg',false]];
  if(j.phase===0)map[5][1]=true,map[0][1]=false; else if(j.phase===1)map[4][1]=true,map[0][1]=false; else if(j.phase===3)map[2][1]=true,map[3][1]=false; else if(j.phase===4)map[1][1]=true,map[3][1]=false;
  if(j.phase===0||j.phase===1){map[0][1]=false;map[3][1]=true}else{map[0][1]=true}
  if(j.phase===3||j.phase===4){map[3][1]=false;map[3][1]=false}else{map[3][1]=true}
  if(j.phase===0)map[2][1]=true;if(j.phase===1)map[1][1]=true;if(j.phase===3)map[5][1]=true;if(j.phase===4)map[4][1]=true;
  map.forEach(([k,on])=>{const e=$(`${prefix}-${k}`);e.className='';if(on)e.classList.add(k==='r'||k==='er'?'active-r':k==='y'||k==='ey'?'active-y':'active-g')});
}
function render(){renderJ(A,'a','stateA','timeA','pedA');renderJ(B,'b','stateB','timeB','pedB');$('waveStatus').textContent=wave?'Synchronizing':'Waiting';$('waveBar').style.width=`${Math.min(100,(wave/waveDelay)*100)}%`;}
function tickOnce(){if(!running)return;tick++;arbitrate();if(A.phase===0&&A.t===0)wave=1;if(wave>0&&wave<waveDelay)wave++;if(wave>=waveDelay){wave=0;if(B.phase===2)B.phase=0;}
  stepJ(A,true);stepJ(B,false);render();}
$('runBtn').onclick=()=>{running=!running;$('runBtn').textContent=running?'Pause':'Run'};
$('resetBtn').onclick=()=>{A={phase:2,t:0,ped:0,density:+$('densityA').value};B={phase:2,t:0,ped:0,density:+$('densityB').value};wave=0;pedQueueA=pedQueueB=false;emergency=false;$('emergencyBtn').textContent='Emergency OFF';render()};
$('emergencyBtn').onclick=()=>{emergency=!emergency;$('emergencyBtn').textContent=emergency?'Emergency ON':'Emergency OFF';if(emergency){A.phase=B.phase=2;A.t=B.t=0;}render()};
$('densityA').oninput=e=>{A.density=+e.target.value;$('densityAVal').textContent=e.target.value};$('densityB').oninput=e=>{B.density=+e.target.value;$('densityBVal').textContent=e.target.value};
$('pedABtn').onclick=()=>request(A,'A');$('pedBBtn').onclick=()=>request(B,'B');
render();setInterval(tickOnce,500);
