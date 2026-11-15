import subprocess, os
F="/home/carlos/Desktop/dev/mis_proyectos/nasa_app/app/assets/fonts/"
B=F+"SpaceGrotesk-Bold.ttf"; M=F+"JetBrainsMono-Bold.ttf"
OR="0xE8590C"; INK="0x2B1408"
D="a/"; os.makedirs(D+"clips",exist_ok=True); os.makedirs(D+"txt",exist_ok=True)
FPS=30
def dt(name,text,font,size,color,x,y,t0,t1,box="white@0.9"):
    p=f"{D}txt/{name}.txt"; open(p,"w").write(text)
    a=f"if(lt(t,{t0}),0,if(lt(t,{t0+0.3}),(t-{t0})/0.3,if(lt(t,{t1-0.25}),1,max(0,({t1}-t)/0.25))))"
    s=f"drawtext=fontfile={font}:textfile={p}:expansion=none:fontsize={size}:fontcolor={color}:x={x}:y={y}:alpha='{a}'"
    if box: s+=f":box=1:boxcolor={box}:boxborderw=24"
    return s
def run(vf_inputs,fc,dur,out):
    cmd=["ffmpeg","-y","-v","error"]
    for i in vf_inputs: cmd+=["-loop","1","-framerate",str(FPS),"-i",i]
    cmd+=["-filter_complex",fc,"-map","[o]","-t",str(dur),"-c:v","libx264","-pix_fmt","yuv420p","-crf","18",f"{D}clips/{out}.mp4"]
    subprocess.run(cmd,check=True)
def fade(dur): return f"fade=t=in:st=0:d=0.25,fade=t=out:st={dur-0.25}:d=0.25"
def photo(name,src,dur,zoom,texts):
    n=int(dur*FPS); zi,zo=zoom
    fc=(f"[0:v]crop=iw:iw*9/16,scale=2880:-2:flags=lanczos,zoompan=z='{zi}+({zo}-{zi})*on/{n}':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d={n}:s=1920x1080:fps={FPS},"
        f"eq=saturation=1.12:contrast=1.04"+"".join(","+t for t in texts)+f",{fade(dur)}[o]")
    run([src],fc,dur,name)
def card(name,shot,bg,dur,w,y,texts):
    n=int(dur*FPS)
    fc=(f"[1:v]crop=iw:iw*9/16,scale=1920:1080,boxblur=28:6,eq=saturation=1.2:brightness=0.04[bg];"
        f"[0:v]scale={w}:-2:flags=lanczos,pad=iw+20:ih+20:10:10:color=white[c];"
        f"[bg][c]overlay=(W-w)/2:{y}:shortest=1,fps={FPS}"+"".join(","+t for t in texts)+f",{fade(dur)}[o]")
    run([shot,bg],fc,dur,name)
I="img/"; BG=I+"b01_paisaje.jpg"
photo("A",I+"b01_paisaje.jpg",3.4,(1.0,1.15),[dt("a1","4 KM DE CASA",B,110,INK,"(w-text_w)/2","h*0.68",0.4,3.4)])
card("B","frames/mapa_gale.png",BG,4.4,1500,150,[
  dt("b1","ARES PATH",B,80,OR,"(w-text_w)/2","42",0.2,4.4,"white@0.92"),
  dt("b2","EL MAPA QUE DECIDE CADA PASO",M,36,INK,"(w-text_w)/2","h-95",0.9,4.4)])
card("C","frames/mapa_gale.png",BG,3.0,1500,150,[
  dt("c1","MÁS SEGURA",M,40,INK,"60","h-300",0.2,3.0),
  dt("c2","MÁS RÁPIDA",M,40,OR,"60","h-215",0.9,3.0),
  dt("c3","MÁS CIENCIA",M,40,"0x0E7490","60","h-130",1.6,3.0)])
photo("D",I+"b02_visor.jpg",1.7,(1.0,1.1),[dt("d1","¿Y EL OXÍGENO?",B,100,INK,"(w-text_w)/2","h*0.70",0.15,1.7)])
photo("E",I+"b02_visor.jpg",4.2,(1.12,1.0),[
  dt("e1","OXÍGENO AL VOLVER  52%",M,52,INK,"60","60",0.2,4.2),
  dt("e2","PUNTO DE NO RETORNO  2,1 KM",M,40,OR,"60","170",1.2,4.2),
  dt("e3","GO / NO-GO",B,150,"0x15803D","(w-text_w)/2","h*0.72",2.4,4.2)])
photo("F",I+"b03c.jpg",1.7,(1.0,1.1),[dt("f1","SIN INTERNET",B,110,INK,"60","h*0.76",0.1,1.7)])
card("G1","frames/mapa_gale.png",BG,1.65,1500,60,[dt("g1","GALE",B,90,INK,"(w-text_w)/2","h-150",0,1.65)])
card("G2","frames/seguridad.png",BG,1.65,1500,60,[dt("g2","RADIACIÓN Y CLIMA",B,70,INK,"(w-text_w)/2","h-150",0,1.65)])
card("G3","frames/casco.png",BG,1.65,1500,60,[dt("g3","CASCO HUD",B,90,INK,"(w-text_w)/2","h-150",0,1.65)])
card("G4","frames/mapa_meridiani.png",BG,1.65,1500,60,[dt("g4","MERIDIANI",B,90,INK,"(w-text_w)/2","h-150",0,1.65)])
photo("H",I+"b04_regreso.jpg",5.0,(1.0,1.15),[
  dt("h1","ARES PATH",B,130,OR,"(w-text_w)/2","50",0.3,5.0),
  dt("h2","PLANEA LA CAMINATA. VUELVE A CASA.",M,40,INK,"(w-text_w)/2","230",1.0,5.0),
  dt("h3","arespath.hellofactura.com",M,38,INK,"(w-text_w)/2","h-110",2.6,5.0)])
order=["A","B","C","D","E","F","G1","G2","G3","G4","H"]
open(D+"clips/list.txt","w").write("".join(f"file '{o}.mp4'\n" for o in order))
subprocess.run(["ffmpeg","-y","-v","error","-f","concat","-safe","0","-i",D+"clips/list.txt","-c","copy",D+"clips/video.mp4"],check=True)
subprocess.run(["ffmpeg","-y","-v","error","-i",D+"clips/video.mp4","-i","audio/voz_v3b.mp3","-i","audio/musica.mp3",
 "-filter_complex","[1:a]atempo=1.17,apad[v];[2:a]volume=0.55,afade=t=in:d=1,afade=t=out:st=28.5:d=1.5[m];[v][m]amix=inputs=2:duration=first:normalize=0,alimiter=limit=0.95[a]",
 "-map","0:v","-map","[a]","-t","30","-c:v","libx264","-crf","22","-preset","medium","-pix_fmt","yuv420p","-c:a","aac","-b:a","192k","ARES_PATH_v3a_luminoso.mp4"],check=True)
print("ok")
