import subprocess, os
F="/home/carlos/Desktop/dev/mis_proyectos/nasa_app/app/assets/fonts/"
B=F+"SpaceGrotesk-Bold.ttf"; M=F+"JetBrainsMono-Bold.ttf"
OR="0xF26B1D"
os.makedirs("clips",exist_ok=True); os.makedirs("txt",exist_ok=True)
FPS=30
def tf(name,text):
    p=f"txt/{name}.txt"; open(p,"w").write(text); return p
def dt(name,text,font,size,color,x,y,t0,t1,box=False):
    p=tf(name,text)
    a=f"if(lt(t,{t0}),0,if(lt(t,{t0+0.3}),(t-{t0})/0.3,if(lt(t,{t1-0.25}),1,max(0,({t1}-t)/0.25))))"
    s=(f"drawtext=fontfile={font}:textfile={p}:fontsize={size}:fontcolor={color}:x={x}:y={y}:alpha='{a}'"
       f":expansion=none:shadowcolor=black@0.7:shadowx=3:shadowy=3")
    if box: s+=":box=1:boxcolor=black@0.55:boxborderw=22"
    return s
def clip(name,src,dur,zoom,texts,pre="",dim=0.0,square=False):
    n=int(dur*FPS)
    crop="crop=iw:iw*9/16," if square else ""
    zin,zout=zoom
    z=f"{zin}+({zout}-{zin})*on/{n}"
    vf=(f"{crop}scale=2880:-2:flags=lanczos,"
        f"zoompan=z='{z}':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d={n}:s=1920x1080:fps={FPS},"
        f"{pre}noise=alls=7:allf=t,vignette=PI/4.5")
    if dim: vf+=f",eq=brightness=-{dim}"
    for t in texts: vf+=","+t
    vf+=f",fade=t=in:st=0:d=0.25,fade=t=out:st={dur-0.25}:d=0.25"
    subprocess.run(["ffmpeg","-y","-v","error","-loop","1","-framerate",str(FPS),"-i",src,"-vf",vf,"-t",str(dur),
        "-c:v","libx264","-pix_fmt","yuv420p","-crf","18",f"clips/{name}.mp4"],check=True)

C="img/"
# A gancho
clip("A",C+"01_astronauta_canon.jpg",3.4,(1.0,1.18),[
  dt("a1","4 KM DE CASA",B,120,"white","(w-text_w)/2","h*0.70",0.5,3.4)],square=True)
# B intro
clip("B","frames/mapa_gale.png",4.4,(1.0,1.15),[
  dt("b1","ARES PATH",B,150,"white","(w-text_w)/2","h*0.36",0.3,4.4),
  dt("b2","EL MAPA QUE DECIDE CADA PASO",M,38,OR,"(w-text_w)/2","h*0.36+180",0.9,4.4,True)],dim=0.35)
# C tres rutas
clip("C","frames/mapa_gale.png",3.0,(1.15,1.0),[
  dt("c1","MAS SEGURA",M,44,"white","80","h-250",0.2,3.0,True),
  dt("c2","MAS RAPIDA",M,44,"0xF59E0B","80","h-180",0.9,3.0,True),
  dt("c3","MAS CIENCIA",M,44,"0x22D3EE","80","h-110",1.6,3.0,True)])
# D bucle
clip("D",C+"02_visor.jpg",1.7,(1.0,1.12),[],dim=0.25,square=True)
# E oxigeno
clip("E",C+"02_visor.jpg",4.2,(1.12,1.0),[
  dt("e1","O2 AL VOLVER  52%",M,64,OR,"(w-text_w)/2","h*0.22",0.2,4.2,True),
  dt("e2","PUNTO DE NO RETORNO  2,1 KM",M,44,"white","(w-text_w)/2","h*0.22+110",1.2,4.2,True),
  dt("e3","GO / NO-GO",B,170,"0x22C55E","(w-text_w)/2","h*0.62",2.4,4.2)],dim=0.45,square=True)
# F sin internet
clip("F",C+"03_tablet.jpg",1.7,(1.0,1.1),[
  dt("f1","SIN INTERNET",B,120,"white","(w-text_w)/2","h*0.70",0.1,1.7)],dim=0.2,square=True)
# G montaje (4 x 1.65)
clip("G1","frames/mapa_gale.png",1.65,(1.0,1.08),[dt("g1","GALE",B,100,"white","80","h-190",0.0,1.65,True)])
clip("G2","frames/seguridad.png",1.65,(1.0,1.06),[dt("g2","RADIACION Y CLIMA",B,80,"white","80","h-170",0.0,1.65,True)])
clip("G3","frames/casco.png",1.65,(1.0,1.08),[dt("g3","CASCO HUD",B,100,"white","80","h-190",0.0,1.65,True)])
clip("G4","frames/mapa_meridiani.png",1.65,(1.0,1.08),[dt("g4","MERIDIANI",B,100,"white","80","h-190",0.0,1.65,True)])
# H cierre
clip("H",C+"04_regreso_habitat.jpg",5.0,(1.0,1.15),[
  dt("h1","ARES PATH",B,140,"white","(w-text_w)/2","h*0.10",0.3,5.0),
  dt("h2","PLANEA LA CAMINATA. VUELVE A CASA.",M,44,OR,"(w-text_w)/2","h*0.10+170",1.0,5.0,True),
  dt("h3","arespath.hellofactura.com",M,40,"white","(w-text_w)/2","h*0.88",2.6,5.0)],square=True)

order=["A","B","C","D","E","F","G1","G2","G3","G4","H"]
open("clips/list.txt","w").write("".join(f"file '{o}.mp4'\n" for o in order))
subprocess.run(["ffmpeg","-y","-v","error","-f","concat","-safe","0","-i","clips/list.txt","-c","copy","clips/video.mp4"],check=True)
# audio: voz 1.17x, musica baja con fade
subprocess.run(["ffmpeg","-y","-v","error","-i","clips/video.mp4","-i","audio/voz_v3b.mp3","-i","audio/musica.mp3",
 "-filter_complex","[1:a]atempo=1.17,apad[v];[2:a]volume=0.55,afade=t=in:d=1,afade=t=out:st=28.5:d=1.5[m];[v][m]amix=inputs=2:duration=first:normalize=0,alimiter=limit=0.95[a]",
 "-map","0:v","-map","[a]","-t","30","-c:v","libx264","-crf","22","-preset","medium","-pix_fmt","yuv420p","-c:a","aac","-b:a","192k","ARES_PATH_presentacion_30s.mp4"],check=True)
print("ok")
