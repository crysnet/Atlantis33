import cairo, math, subprocess, sys
W,H,FPS=1920,1080,30
BG=(0.961,0.941,0.910); INK=(0.106,0.106,0.122); OR=(0.910,0.349,0.047)
TEAL=(0.055,0.455,0.565); AMB=(0.961,0.620,0.043); GRN=(0.082,0.502,0.239); GREY=(0.62,0.60,0.57)
SG="Space Grotesk"; JB="JetBrains Mono"
def clamp(x): return max(0.0,min(1.0,x))
def ease(x): x=clamp(x); return 1-(1-x)**3
def eio(x): x=clamp(x); return 3*x*x-2*x**3
def prog(t,a,b): return clamp((t-a)/(b-a))
IM={k:cairo.ImageSurface.create_from_png(f"frames/{k}.png") for k in ["mapa_gale","mapa_meridiani","seguridad","casco"]}
dots=cairo.ImageSurface(cairo.FORMAT_ARGB32,W,H); d=cairo.Context(dots)
d.set_source_rgb(*BG); d.paint(); d.set_source_rgba(0,0,0,0.07)
for x in range(40,W,60):
    for y in range(40,H,60): d.arc(x,y,2,0,6.3); d.fill()
def font(c,fam,size,bold=True):
    c.select_font_face(fam,cairo.FONT_SLANT_NORMAL,cairo.FONT_WEIGHT_BOLD if bold else cairo.FONT_WEIGHT_NORMAL); c.set_font_size(size)
def text(c,s,x,y,size,col,fam=SG,al="l",a=1.0,bold=True):
    font(c,fam,size,bold); e=c.text_extents(s); w=e.x_advance
    if al=="c": x-=w/2
    elif al=="r": x-=w
    c.set_source_rgba(*col,a); c.move_to(x,y); c.show_text(s); return w
def rrect(c,x,y,w,h,r):
    c.new_sub_path(); c.arc(x+w-r,y+r,r,-math.pi/2,0); c.arc(x+w-r,y+h-r,r,0,math.pi/2)
    c.arc(x+r,y+h-r,r,math.pi/2,math.pi); c.arc(x+r,y+r,r,math.pi,1.5*math.pi); c.close_path()
def pill(c,s,cx,cy,size,fg,bgc,a=1.0,fam=SG,pad=34,outline=None):
    font(c,fam,size); w=c.text_extents(s).x_advance; h=size*1.5
    rrect(c,cx-w/2-pad,cy-h/2,w+2*pad,h,h/2)
    if bgc: c.set_source_rgba(*bgc,a); c.fill_preserve()
    if outline: c.set_source_rgba(*outline,a); c.set_line_width(4); c.stroke()
    c.new_path(); text(c,s,cx,cy+size*0.34,size,fg,fam,"c",a)
def card(c,img,x,y,w,a=1.0,lift=0):
    h=w*img.get_height()/img.get_width(); y=y+lift
    c.save()
    c.set_source_rgba(0,0,0,0.12*a); rrect(c,x+6,y+14,w,h,22); c.fill()
    rrect(c,x,y,w,h,22); c.clip()
    c.translate(x,y); c.scale(w/img.get_width(),w/img.get_width())
    c.set_source_surface(img,0,0); c.paint_with_alpha(a); c.restore()
    return h
def house(c,cx,cy,s,col,a=1.0):
    c.set_source_rgba(*col,a); c.set_line_width(6*s/40); c.set_line_join(cairo.LINE_JOIN_ROUND)
    c.move_to(cx-s,cy); c.line_to(cx-s,cy-s*0.6); c.line_to(cx,cy-s*1.4); c.line_to(cx+s,cy-s*0.6); c.line_to(cx+s,cy); c.close_path(); c.stroke()
    rrect(c,cx-s*0.25,cy-s*0.5,s*0.5,s*0.5,4); c.stroke()
def logo(c,x,y,s,a=1.0):
    c.set_source_rgba(*OR,a); c.set_line_width(5); c.rectangle(x,y,s,s); c.stroke()
    c.move_to(x+s*0.5,y+s*0.22); c.line_to(x+s*0.78,y+s*0.74); c.line_to(x+s*0.22,y+s*0.74); c.close_path(); c.set_line_width(4); c.stroke()
def dotted(c,x0,y0,x1,y1,p,col,a=1.0):
    n=int(abs(x1-x0)/26); c.set_source_rgba(*col,a)
    for i in range(int(n*p)+1):
        x=x0+(x1-x0)*i/n; c.arc(x,y0,5,0,6.3); c.fill()
SC=[("A",0,3.4),("B",3.4,7.8),("C",7.8,10.8),("D",10.8,12.5),("E",12.5,16.7),("F",16.7,18.4),("G",18.4,25.0),("H",25.0,30.0)]
def frame(t):
    s=cairo.ImageSurface(cairo.FORMAT_ARGB32,W,H); c=cairo.Context(s)
    c.set_source_surface(dots,0,0); c.paint()
    name,t0,t1=[x for x in SC if x[1]<=t<x[2] or x[0]=="H"][0] if t<30 else SC[-1]
    for x in SC:
        if x[1]<=t<x[2]: name,t0,t1=x
    u=t-t0
    if name=="A":
        hx,gx,y=300,1620,700
        house(c,hx,y,46,INK); text(c,"HÁBITAT",hx,y+60,28,INK,JB,"c",ease(prog(u,0,0.4)))
        dotted(c,hx+90,y-10,gx-60,y-10,ease(prog(u,0.4,2.0)),GREY)
        p=ease(prog(u,0.4,2.0)); px=hx+90+(gx-60-hx-90)*p
        c.set_source_rgba(*OR,1); c.arc(px,y-10,18+4*math.sin(u*9),0,6.3); c.fill()
        v=4.0*ease(prog(u,0.3,1.7))
        text(c,f"{v:.1f}".replace(".",",")+" km",W/2,420,270,OR,SG,"c",ease(prog(u,0.2,0.7)))
        text(c,"de casa. Y nadie a quién llamar.",W/2,540,62,INK,SG,"c",ease(prog(u,1.5,2.2)))
    elif name=="B":
        a=ease(prog(u,0.1,0.6)); logo(c,120,300,100,a)
        text(c,"ARES PATH",120+140,382,120,INK,SG,"l",a)
        text(c,"El mapa que decide",122,560,60,INK,SG,"l",ease(prog(u,0.9,1.5)),False)
        text(c,"cada paso antes de darlo.",122,635,60,OR,SG,"l",ease(prog(u,1.2,1.8)))
        p=ease(prog(u,0.4,1.2)); card(c,IM["mapa_gale"],1120+(1-p)*900,250,700,p)
    elif name=="C":
        text(c,"TRES RUTAS · DATOS REALES DE LA NASA",W/2,70,32,OR,JB,"c",ease(prog(u,0,0.4)))
        p=ease(prog(u,0,0.5)); card(c,IM["mapa_gale"],310,110,1300,p,(1-p)*40)
        for i,(s_,col) in enumerate([("Más segura",INK),("Más rápida",AMB),("Más ciencia",TEAL)]):
            a=ease(prog(u,0.4+0.5*i,0.8+0.5*i)); pill(c,s_,430+i*530,990,40,(1,1,1),col,a,SG)
    elif name=="D":
        k=1+0.05*math.sin(u*8); a=ease(prog(u,0,0.2))
        c.save(); c.translate(W/2,H/2+250); c.scale(k,k); text(c,"?",0,0,900,OR,SG,"c",a); c.restore()
    elif name=="E":
        cx,cy,r=520,560,260; v=100-48*eio(prog(u,0.2,1.7)); a=ease(prog(u,0,0.4))
        c.set_line_width(56); c.set_source_rgba(0.85,0.82,0.77,a); c.arc(cx,cy,r,0,6.3); c.stroke()
        c.set_source_rgba(*OR,a); c.set_line_cap(cairo.LINE_CAP_ROUND); c.arc(cx,cy,r,-math.pi/2,-math.pi/2+6.2832*v/100); c.stroke()
        w=text(c,f"{v:.0f}%",cx,cy+50,150,INK,SG,"c",a)
        text(c,"OXÍGENO AL VOLVER",cx,cy+110,26,INK,JB,"c",a)
        text(c,"PUNTO DE NO RETORNO",1000,330,30,OR,JB,"l",ease(prog(u,0.7,1.2)))
        text(c,"2,1 km",1000,470,170,INK,SG,"l",ease(prog(u,0.8,1.4)))
        k=0.6+0.4*ease(prog(u,2.3,2.8))
        if u>2.3:
            c.save(); c.translate(1230,720); c.scale(k,k); pill(c,"GO",-170,0,90,(1,1,1),GRN,ease(prog(u,2.3,2.6)),SG,60); pill(c,"NO-GO",190,0,90,GREY,None,ease(prog(u,2.3,2.6)),SG,60,GREY); c.restore()
    elif name=="F":
        a=ease(prog(u,0,0.3)); cx,cy=W/2,470
        c.set_source_rgba(*INK,a); c.set_line_cap(cairo.LINE_CAP_ROUND); c.set_line_width(24)
        for rr in (110,200,290):
            c.new_path(); c.arc(cx,cy+170,rr,-math.pi*0.75,-math.pi*0.25); c.stroke()
        c.arc(cx,cy+170,18,0,6.3); c.fill()
        p=ease(prog(u,0.35,0.8)); c.set_source_rgba(0.82,0.12,0.12,1); c.set_line_width(26)
        c.move_to(cx-300,cy-120); c.line_to(cx-300+600*p,cy-120+520*p); c.stroke()
        text(c,"Sin internet",W/2,900,110,INK,SG,"c",ease(prog(u,0.2,0.7)))
    elif name=="G":
        items=[("mapa_gale","GALE"),("mapa_meridiani","MERIDIANI"),("seguridad","RADIACIÓN Y CLIMA"),("casco","CASCO HUD")]
        i=min(3,int(u/1.65)); lu=u-i*1.65; img,lab=items[i]
        p=ease(prog(lu,0,0.35)); out=ease(prog(lu,1.4,1.65))
        card(c,IM[img],W/2-650+(1-p)*500-out*500,90,1300,p*(1-out))
        pill(c,lab,W/2,960,56,(1,1,1),INK,ease(prog(lu,0.1,0.4))*(1-out),JB)
        for j in range(4):
            c.set_source_rgba(*(OR if j==i else GREY),1); c.arc(W/2-60+j*40,1035,7,0,6.3); c.fill()
    else:
        hx,y=1560,640
        house(c,hx,y,60,INK,ease(prog(u,0,0.4)))
        p=ease(prog(u,0.2,2.0)); dotted(c,160,y-14,hx-100,y-14,p,GREY)
        px=160+(hx-100-160)*p; c.set_source_rgb(*OR); c.arc(px,y-14,20,0,6.3); c.fill()
        a=ease(prog(u,1.8,2.4)); logo(c,W/2-420,230,100,a)
        text(c,"ARES PATH",W/2-290,318,140,INK,SG,"l",a)
        text(c,"Planea la caminata. Vuelve a casa.",W/2,470,64,OR,SG,"c",ease(prog(u,2.2,2.8)))
        pill(c,"arespath.hellofactura.com",W/2,860,44,(1,1,1),INK,ease(prog(u,3.0,3.5)),JB,40)
    f=ease(1-prog(u,0,0.25))
    if f>0 and name!="A": c.set_source_rgba(*BG,f); c.paint()
    if name=="H":
        f2=prog(u,4.75,5.0)
        if f2>0: c.set_source_rgba(*BG,f2); c.paint()
    return s
ff=subprocess.Popen(["ffmpeg","-y","-v","error","-f","rawvideo","-pix_fmt","bgra","-s",f"{W}x{H}","-r",str(FPS),"-i","-",
 "-i","audio/voz_v3b.mp3","-i","audio/musica.mp3",
 "-filter_complex","[1:a]atempo=1.17,apad[v];[2:a]volume=0.55,afade=t=in:d=1,afade=t=out:st=28.5:d=1.5[m];[v][m]amix=inputs=2:duration=first:normalize=0,alimiter=limit=0.95[a]",
 "-map","0:v","-map","[a]","-t","30","-c:v","libx264","-crf","18","-pix_fmt","yuv420p","-c:a","aac","-b:a","192k","ARES_PATH_v3b_limpio.mp4"],stdin=subprocess.PIPE)
for i in range(FPS*30):
    ff.stdin.write(bytes(frame(i/FPS).get_data()))
ff.stdin.close(); ff.wait(); print("ok")
