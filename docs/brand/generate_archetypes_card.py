from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math, os, textwrap
A="/Users/macbook/Projects/Music Shadow/Music Shadow/Assets.xcassets/"
SERIF="/System/Library/Fonts/Supplemental/Georgia.ttf"; SERIF_I="/System/Library/Fonts/Supplemental/Georgia Italic.ttf"
SANS="/System/Library/Fonts/Helvetica.ttc"
WHITE=(255,255,255); MIST=(190,184,214); VIOLET=(180,120,255); FAINT=(74,56,120)

def gradbg(w,h):
    stops=[((10,10,25),0.0),((30,12,60),0.55),((5,5,20),1.0)]
    g=Image.new("RGB",(w,h)); px=g.load()
    for y in range(h):
        for x in range(w):
            t=x/w*0.3+y/h*0.7
            for i in range(2):
                (c0,t0),(c1,t1)=stops[i],stops[i+1]
                if t<=t1:
                    k=(t-t0)/(t1-t0); px[x,y]=tuple(int(c0[j]+(c1[j]-c0[j])*k) for j in range(3)); break
    return g.convert("RGBA")

def load_icon(path,size):
    im=Image.open(path).convert("RGBA"); im=im.crop(im.getchannel("A").getbbox())
    s=size/max(im.size); im=im.resize((int(im.width*s),int(im.height*s)),Image.LANCZOS)
    out=Image.new("RGBA",im.size,WHITE+(255,)); out.putalpha(im.getchannel("A")); return out

# placeholder line glyphs for the light archetypes (same circular language, white on transparent)
def glyph(kind,N=1024,sw=26):
    S=2; im=Image.new("RGBA",(N*S,N*S),(0,0,0,0)); d=ImageDraw.Draw(im); c=N*S//2; w=sw*S
    R=int(N*S*0.46)
    def ring(r,**k): d.ellipse([c-r,c-r,c+r,c+r],outline=WHITE,width=w,**k)
    def arc(r,a0,a1): d.arc([c-r,c-r,c+r,c+r],a0,a1,fill=WHITE,width=w)
    if kind=="open":   # ring open at the top, heart inside
        arc(R,-65,245)
        pts=[]
        for i in range(361):
            t=math.radians(i); x=16*math.sin(t)**3; y=-(13*math.cos(t)-5*math.cos(2*t)-2*math.cos(3*t)-math.cos(4*t))
            pts.append((c+x*N*S*0.017,c+y*N*S*0.017+N*S*0.02))
        d.line(pts+[pts[0]],fill=WHITE,width=w,joint="curve")
    elif kind=="free": # open ring, three rising arcs
        arc(R,-30,250)
        for i,r in enumerate((0.16,0.27,0.38)):
            rr=int(N*S*r); bb=[c-rr-int(N*S*0.06),c-rr+int(N*S*0.12),c+rr-int(N*S*0.06),c+rr+int(N*S*0.12)]
            d.arc(bb,200,340,fill=WHITE,width=w)
        d.ellipse([c+int(N*S*0.16)-w,c-int(N*S*0.16)-w,c+int(N*S*0.16)+w,c-int(N*S*0.16)+w],fill=WHITE)
    elif kind=="celebrant": # ring, inner ring, rays
        ring(R); ring(int(R*0.34))
        for i in range(16):
            a=math.radians(i*22.5); r0=R*0.52; r1=R*(0.78 if i%2==0 else 0.68)
            d.line([c+r0*math.cos(a),c+r0*math.sin(a),c+r1*math.cos(a),c+r1*math.sin(a)],fill=WHITE,width=w)
    elif kind=="connector": # two overlapping rings (vesica) inside frame, centre dot
        ring(R); rr=int(R*0.46); off=int(R*0.30)
        d.ellipse([c-off-rr,c-rr,c-off+rr,c+rr],outline=WHITE,width=w)
        d.ellipse([c+off-rr,c-rr,c+off+rr,c+rr],outline=WHITE,width=w)
        d.ellipse([c-w,c-w,c+w,c+w],fill=WHITE)
    elif kind=="held":
        ring(R); rr=int(R*0.5); d.arc([c-rr,c-int(R*0.3)-rr//2,c+rr,c-int(R*0.3)+rr+rr//2],0,180,fill=WHITE,width=w)
        d.ellipse([c-int(R*0.16),c-int(R*0.28),c+int(R*0.16),c+int(R*0.04)],fill=WHITE)
    elif kind=="embodied":
        ring(R); d.ellipse([c-int(R*0.14),c-int(R*0.6)-int(R*0.17),c+int(R*0.17),c-int(R*0.6)+int(R*0.17)],fill=WHITE)
        d.line([c,c-int(R*0.34),c,c+int(R*0.5)],fill=WHITE,width=w)
        for sgn in (-1,1):
            for rr in (0.3,0.55):
                r2=int(R*rr)
                d.arc([c-r2,c-int(R*0.05)-r2,c+r2,c-int(R*0.05)+r2],(-45 if sgn>0 else 135),(45 if sgn>0 else 225),fill=WHITE,width=w)
    elif kind=="firekeeper":
        ring(R); fl=[(-0.3,0.25),(-0.32,0.0),(-0.17,-0.2),(-0.1,-0.42),(0.0,-0.7),(0.12,-0.4),(0.3,-0.1),(0.3,0.25)]
        pts=[(c+x*R,c+y*R) for x,y in fl]; d.line(pts,fill=WHITE,width=w,joint="curve")
        for p in pts: d.ellipse([p[0]-w/2,p[1]-w/2,p[0]+w/2,p[1]+w/2],fill=WHITE)
        d.arc([c-int(R*0.55),c-int(R*0.4),c+int(R*0.55),c+int(R*0.7)],0,180,fill=WHITE,width=w)
    elif kind=="whole":
        ring(R); r2=int(R*0.55); d.ellipse([c-r2,c-r2,c+r2,c+r2],outline=WHITE,width=w)
        d.ellipse([c-int(R*0.16),c-int(R*0.16),c+int(R*0.16),c+int(R*0.16)],fill=WHITE)
    elif kind=="steady":
        ring(R)
        for y,hw in ((0.4,0.5),(0.14,0.36),(-0.1,0.22)):
            d.line([c-hw*R,c+y*R,c+hw*R,c+y*R],fill=WHITE,width=int(w*1.9))
            for sx in (-1,1): d.ellipse([c+sx*hw*R-w*0.95,c+y*R-w*0.95,c+sx*hw*R+w*0.95,c+y*R+w*0.95],fill=WHITE)
        d.ellipse([c-int(R*0.09),c-int(R*0.42),c+int(R*0.09),c-int(R*0.24)],fill=WHITE)
    elif kind=="maker":
        ring(R); pts=[]
        for k in range(0,721,4):
            t=math.radians(k); rr=R*0.78*(k/720); pts.append((c+rr*math.cos(t-math.pi/2),c+rr*math.sin(t-math.pi/2)))
        d.line(pts,fill=WHITE,width=w,joint="curve")
    return im.resize((N,N),Image.LANCZOS)


def glyph_shadow(kind,N=1024,sw=26):
    S=2; M=N*S; im=Image.new("RGBA",(M,M),(0,0,0,0)); d=ImageDraw.Draw(im); c=M//2; w=sw*S; R=int(M*0.46)
    P=lambda x,y:(c+x*R,c+y*R)
    def ring(): d.ellipse([c-R,c-R,c+R,c+R],outline=WHITE,width=w)
    def dot(x,y,r): px,py=P(x,y); rr=r*R; d.ellipse([px-rr,py-rr,px+rr,py+rr],fill=WHITE)
    def line(pts,close=False):
        pp=[P(*p) for p in pts]+([P(*pts[0])] if close else []); d.line(pp,fill=WHITE,width=w,joint="curve")
        for p in pp: d.ellipse([p[0]-w/2,p[1]-w/2,p[0]+w/2,p[1]+w/2],fill=WHITE)
    if kind=="abandoned":
        d.arc([c-R,c-R,c+R,c+R],40,320,fill=WHITE,width=w); dot(-0.22,0,0.2); dot(1.0,0,0.08)
    elif kind=="lonewolf":
        ring(); m=Image.new("L",(M,M),0); md=ImageDraw.Draw(m); r=int(R*0.5)
        md.ellipse([c-r-int(R*0.12),c-r,c+r-int(R*0.12),c+r],fill=255); md.ellipse([c-r+int(R*0.2),c-r-int(R*0.06),c+r+int(R*0.2),c+r-int(R*0.06)],fill=0)
        im.paste(Image.new("RGBA",(M,M),WHITE+(255,)),(0,0),m); dot(0.32,-0.02,0.07)
    elif kind=="overachiever":
        ring()
        for y,hw in ((0.38,0.5),(0.14,0.4),(-0.1,0.3)): line([(-hw,y+0.2),(0,y-0.1),(hw,y+0.2)])
        dot(0,-0.55,0.1)
    elif kind=="invisible":
        for i in range(24):
            a0=i*15; sp=max(1.2,13*(1-i/23)**1.3); d.arc([c-R,c-R,c+R,c+R],a0,a0+sp,fill=WHITE,width=w)
        dot(0,0,0.06)
    elif kind=="protector":
        ring(); line([(-0.42,-0.4),(0.42,-0.4),(0.42,0.08),(0.0,0.58),(-0.42,0.08)],close=True)
    elif kind=="mask":
        ring(); r=int(R*0.6); d.pieslice([c-r,c-r,c+r,c+r],90,270,fill=WHITE); d.arc([c-r,c-r,c+r,c+r],270,90,fill=WHITE,width=w)
        d.line([c,c-r,c,c+r],fill=WHITE,width=w)
    elif kind=="performer":
        ring(); line([(0,-0.62),(-0.5,0.5),(0.5,0.5),(0,-0.62)]); dot(0,0.22,0.12)
    elif kind=="ghost":
        ring(); x0=0.4
        d.arc([c-x0*R,c-0.62*R,c+x0*R,c+0.18*R],180,360,fill=WHITE,width=w)
        line([(-x0,-0.22),(-x0,0.46)]); line([(x0,-0.22),(x0,0.46)])
        sw3=2*x0/3
        for i in range(3):
            xa=-x0+i*sw3; d.arc([c+xa*R,c+(0.46-sw3/2)*R,c+(xa+sw3)*R,c+(0.46+sw3/2)*R],0,180,fill=WHITE,width=w)
        dot(-0.16,-0.24,0.07); dot(0.16,-0.24,0.07)
    elif kind=="buriedfire":
        ring(); line([(-0.42,0.25),(-0.42,0.0),(-0.22,-0.2),(-0.12,-0.45),(0.0,-0.72),(0.14,-0.4),(0.42,-0.1),(0.42,0.25)])
        line([(-0.62,0.25),(0.62,0.25)]); line([(-0.4,0.47),(0.4,0.47)])
    elif kind=="defective":
        ring(); zz=[(0.1,-1.1),(-0.14,-0.62),(0.14,-0.24),(-0.14,0.14),(0.14,0.5),(-0.1,0.8),(0.1,1.1)]
        d.line([P(*p) for p in zz],fill=(0,0,0,0),width=int(w*2.4),joint="curve")
        line(zz[1:-1])
    return im.resize((N,N),Image.LANCZOS)

kinds_map=dict(zip(['The Abandoned Child','The Lone Wolf','The Overachiever','The Invisible One','The Protector','The Mask','The Performer','The Ghost','The Buried Fire','The Defective One'],['abandoned', 'lonewolf', 'overachiever', 'invisible', 'protector', 'mask', 'performer', 'ghost', 'buriedfire', 'defective']))
SHADOW=[("The Abandoned Child","Longing for care, bracing for being left.","ArchetypeAbandonedChild.imageset/AbandonedChild.png"),
("The Lone Wolf","I'm safest when I rely on no one.","ArchetypeLoneWolf.imageset/Lonewolf.png"),
("The Overachiever","If I'm perfect, I might be enough.","ArchetypeOverachiever.imageset/overachiever.png"),
("The Invisible One","If no one sees me, I can't be hurt.","ArchetypeInvisibleOne.imageset/InvisibleOne.png"),
("The Protector","Always on guard, always managing danger.","ArchetypeProtector.imageset/protector.png"),
("The Mask","I show what's acceptable, hide what's real.","ArchetypeMask.imageset/theMask.png"),
("The Performer","I earn love by entertaining and pleasing.","ArchetypePerformer.imageset/Performer.png"),
("The Ghost","If I can't feel it, I can't be hurt by it.","ArchetypeGhost.imageset/theghost.png"),
("The Buried Fire","My anger was too dangerous to feel, so I swallowed it.","ArchetypeBuriedFire.imageset/buriedfire.png"),
("The Defective One","Something is fundamentally wrong with me.","ArchetypeDefectiveOne.imageset/defectveone.png")]
LIGHT=[("The Open Heart","I can be moved without being undone.","open"),
("The Free One","This is who I am. No performance.","free"),
("The Celebrant","Joy with nothing underneath.","celebrant"),
("The Connector","This song is you.","connector"),
("The Held One","I trust that people stay.","held"),
("The Embodied One","I feel it, and I'm here.","embodied"),
("The Fire Keeper","My anger warms. It doesn't burn.","firekeeper"),
("The Whole One","I'm enough as I am.","whole"),
("The Steady One","I'm safe enough to soften.","steady"),
("The Maker","I create because it's alive in me.","maker")]

W,H=2400,3720; img=gradbg(W//2,H//2).resize((W,H),Image.BILINEAR); d=ImageDraw.Draw(img)
def spaced(xy,text,font,fill,sp,anchor="l"):
    w=sum(d.textlength(ch,font=font) for ch in text)+sp*(len(text)-1); x,y=xy
    if anchor=="m": x-=w/2
    for ch in text: d.text((x,y),ch,font=font,fill=fill); x+=d.textlength(ch,font=font)+sp
def wrap_center(text,font,cx,y,maxw,fill,lh):
    words=text.split(); lines=[]; cur=""
    for w in words:
        t=(cur+" "+w).strip()
        if d.textlength(t,font=font)<=maxw: cur=t
        else: lines.append(cur); cur=w
    lines.append(cur)
    for i,l in enumerate(lines): d.text((cx-d.textlength(l,font=font)/2,y+i*lh),l,font=font,fill=fill)

# header
em=Image.open(A+"MusicShadowEmblem.imageset/MusicShadowEmblem.png").convert("RGBA"); em=em.crop(em.getchannel("A").getbbox()).resize((150,150),Image.LANCZOS)
eo=Image.new("RGBA",em.size,WHITE+(255,)); eo.putalpha(em.getchannel("A")); img.alpha_composite(eo,(W//2-75,120))
spaced((W//2,300),"MUSIC SHADOW",ImageFont.truetype(SANS,30),MIST,10,"m")
t=ImageFont.truetype(SERIF,130); d.text((W//2-d.textlength("The Archetypes",font=t)/2,370),"The Archetypes",font=t,fill=WHITE)
wrap_center("Ten patterns the shadow takes. Ten the light takes. Every song that hits you points to one of them.",ImageFont.truetype(SERIF_I,44),W//2,540,1500,MIST,60)

def section(label,y,sub):
    f=ImageFont.truetype(SANS,28); spaced((150,y),label,f,VIOLET,9)
    wlab=sum(d.textlength(ch,font=f)+9 for ch in label)
    d.line([150+wlab+30,y+16,W-150,y+16],fill=FAINT,width=2)
    d.text((150,y+52),sub,font=ImageFont.truetype(SERIF_I,34),fill=MIST)

nf=ImageFont.truetype(SERIF,42); tf=ImageFont.truetype(SERIF_I,30)
def tile(cx,y,icon,name,tag,colw=420):
    img.alpha_composite(icon,(cx-icon.width//2,y+(300-icon.height)//2))
    d.text((cx-d.textlength(name,font=nf)/2,y+330),name,font=nf,fill=WHITE)
    wrap_center(tag,tf,cx,y+395,colw-30,MIST,40)

# shadow grid 5x2
section("SHADOW",760,"Patterns that formed to keep you safe.")
colw=(W-300)//5
for i,(n,tg,p) in enumerate(SHADOW):
    r,c=divmod(i,5); cx=150+colw*c+colw//2; y=890+r*590
    gk=kinds_map[n]; g=glyph_shadow(gk); g=g.crop(g.getchannel("A").getbbox()); sc=215/max(g.size); g=g.resize((int(g.width*sc),int(g.height*sc)),Image.LANCZOS)
    tile(cx,y,g,n,tg,colw)

# light grid 5x2
section("LIGHT",2150,"What opens when a song lands without a wound.")
for i,(n,tg,k) in enumerate(LIGHT):
    r,c=divmod(i,5); cx=150+colw*c+colw//2; y=2300+r*590
    g=glyph(k); g=g.crop(g.getchannel("A").getbbox()); sc=215/max(g.size); g=g.resize((int(g.width*sc),int(g.height*sc)),Image.LANCZOS)
    tile(cx,y,g,n,tg,colw)

# footer
d.line([150,3470,W-150,3470],fill=FAINT,width=2)
wrap_center("Light archetypes are a proposed set: icons are working sketches, names and lines open to revision.",ImageFont.truetype(SERIF_I,30),W//2,3510,1800,(140,134,170),40)
spaced((W//2,3620),"EVERY SONG THAT HITS YOU IS A MAP",ImageFont.truetype(SANS,24),MIST,8,"m")
img.convert("RGB").save("archetypes-card.png"); print("ok")
