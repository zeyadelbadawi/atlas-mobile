import colorsys, json
def hsl(h,s,l): r,g,b=colorsys.hls_to_rgb(h/360,l/100,s/100); return (r,g,b)
def lum(c):
    f=lambda x: x/12.92 if x<=0.03928 else ((x+0.055)/1.055)**2.4
    r,g,b=map(f,c); return 0.2126*r+0.7152*g+0.0722*b
def cr(a,b):
    la,lb=lum(a),lum(b); return (max(la,lb)+0.05)/(min(la,lb)+0.05)
def mix(a,b,t): return tuple(a[i]*(1-t)+b[i]*t for i in range(3))
def hx(c): return '#%02X%02X%02X'%tuple(round(x*255) for x in c)
PAPER=(0.988,0.988,0.984); NIGHT=(0.075,0.075,0.08)
INK=(0.07,0.07,0.075); WHITE=(1,1,1)
def derive(h,s,l):
    p=hsl(h,s,l)
    paperL=mix(PAPER,p,0.035); paperD=mix(NIGHT,p,0.07)
    onCover = WHITE if cr(WHITE,p)>=cr(INK,p) else INK
    # accent ink light
    L=l
    while cr(hsl(h,s,L),paperL)<4.5 and L>5: L-=1
    accL=hsl(h,s,L)
    L=l
    while cr(hsl(h,s,L),paperD)<4.5 and L<95: L+=1
    accD=hsl(h,s,L)
    # cover on dark: keep primary but if too bright keep; fine
    tonL=mix(paperL,p,0.14); tonD=mix(paperD,p,0.24)
    # button fill: use cover if onCover contrast>=4.5 else accent
    btnL = p if cr(onCover,p)>=4.5 else accL
    onBtnL = WHITE if cr(WHITE,btnL)>=cr(INK,btnL) else INK
    btnD = p if cr(onCover,p)>=4.5 else accD
    onBtnD = WHITE if cr(WHITE,btnD)>=cr(INK,btnD) else INK
    return dict(cover=hx(p),onCover=hx(onCover),coverContrast=round(cr(onCover,p),2),
      paperLight=hx(paperL),paperDark=hx(paperD),accentLight=hx(accL),accentDark=hx(accD),
      accLc=round(cr(accL,paperL),2),accDc=round(cr(accD,paperD),2),
      tonalLight=hx(tonL),tonalDark=hx(tonD),
      buttonLight=hx(btnL),onButtonLight=hx(onBtnL),btnLc=round(cr(onBtnL,btnL),2),
      buttonDark=hx(btnD),onButtonDark=hx(onBtnD),btnDc=round(cr(onBtnD,btnD),2))
out={k:derive(*v) for k,v in {'Ziadd':(40,95,54),'Manara':(222,72,46),'Riwaq':(199,64,30)}.items()}
print(json.dumps(out,indent=1))
def h2c(s): s=s.lstrip('#'); return tuple(int(s[i:i+2],16)/255 for i in (0,2,4))
for name,val in [('sec L','#5B5B60'),('ter L','#6E6E74'),('danger L','#B3261E'),('success L','#1D6B35'),('warn L','#8A5A00')]:
    print(name,[round(cr(h2c(val),h2c(p)),2) for p in ['#FCF9F3','#F4F6F9','#F4F6F7','#FFFFFF']])
for name,val in [('ink D','#F2F2EF'),('sec D','#ADADB2'),('ter D','#8E8E94'),('danger D','#FF8A80'),('success D','#5FCB85'),('warn D','#F2B544')]:
    print(name,[round(cr(h2c(val),h2c(p)),2) for p in ['#231E15','#141821','#14181C','#1E1E20']])
