from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math
LOGO="/Users/macbook/Projects/Music Shadow/Music Shadow/Assets.xcassets/MusicShadowEmblem.imageset/MusicShadowEmblem.png"
BG=(10,10,25); GOLD=(255,255,255); LINEN=(255,255,255); MIST=(178,178,190); FAINT=(74,56,120); VIOLET=(140,80,220)
def gradbg(w,h):
    stops=[((10,10,25),0.0),((30,12,60),0.55),((5,5,20),1.0)]
    g=Image.new("RGB",(w,h)); px=g.load()
    for y in range(h):
        for x in range(w):
            t=(x/w*0.35+y/h*0.65) if w==h else (x/w*0.8+y/h*0.2)
            for i in range(len(stops)-1):
                (c0,t0),(c1,t1)=stops[i],stops[i+1]
                if t<=t1:
                    k=(t-t0)/(t1-t0); px[x,y]=tuple(int(c0[j]+(c1[j]-c0[j])*k) for j in range(3)); break
    return g.convert("RGBA")
SERIF="/System/Library/Fonts/Supplemental/Georgia.ttf"
SERIF_I="/System/Library/Fonts/Supplemental/Georgia Italic.ttf"
SS=2  # supersample

def emblem(size, color, boost=True):
    im=Image.open(LOGO).convert("RGBA")
    bbox=im.getchannel("A").getbbox(); im=im.crop(bbox).resize((size,size),Image.LANCZOS)
    a=im.getchannel("A")
    if boost: a=a.filter(ImageFilter.MaxFilter(3))  # thicken hairlines slightly
    out=Image.new("RGBA",im.size,color+(255,)); out.putalpha(a); return out

def rings(d, cx, cy, radii, color, width=2, alphas=None):
    for r in radii:
        d.ellipse([cx-r,cy-r,cx+r,cy+r],outline=color,width=width)

def glow(img, cx, cy, r, color, strength=40):
    g=Image.new("RGBA",img.size,(0,0,0,0)); d=ImageDraw.Draw(g)
    d.ellipse([cx-r,cy-r,cx+r,cy+r],fill=color+(strength,))
    g=g.filter(ImageFilter.GaussianBlur(r/2.2)); img.alpha_composite(g)

def spaced(d, xy, text, font, fill, spacing, anchor="l"):
    w=sum(d.textlength(c,font=font) for c in text)+spacing*(len(text)-1)
    x,y=xy
    if anchor=="m": x-=w/2
    for c in text:
        d.text((x,y),c,font=font,fill=fill); x+=d.textlength(c,font=font)+spacing
    return w

# ---- Profile picture 1080 (safe inside circle crop)
S=1080*SS
img=gradbg(S,S); d=ImageDraw.Draw(img)
glow(img,S//2,S//2,int(S*0.30),VIOLET,70)
d=ImageDraw.Draw(img)
rings(d,S//2,S//2,[int(S*r) for r in (0.46,0.40)],FAINT,width=2*SS)
em=emblem(int(S*0.46),GOLD); img.alpha_composite(em,((S-em.width)//2,int(S*0.20)))
d=ImageDraw.Draw(img); fw=ImageFont.truetype(SERIF,60*SS)
spaced(d,(S//2,int(S*0.71)),"MUSIC SHADOW",fw,LINEN,9*SS,anchor="m")
img.resize((1080,1080),Image.LANCZOS).convert("RGB").save("profile-picture-1080.png")

# ---- X header 1500x500 (avatar sits bottom-left; keep left clear, composition weighted right)
W,H=1500*SS,500*SS
img=gradbg(W,H)
glow(img,int(W*0.89),H//2,int(H*0.55),VIOLET,70)
d=ImageDraw.Draw(img)
cx,cy=int(W*0.89),H//2
rings(d,cx,cy,[int(H*r) for r in (0.62,0.82,1.02,1.22)],FAINT,width=2*SS)
em=emblem(int(H*0.56),GOLD); img.alpha_composite(em,(cx-em.width//2,cy-em.height//2))
d=ImageDraw.Draw(img)
tx=int(W*0.27)
f1=ImageFont.truetype(SERIF,62*SS); f2=ImageFont.truetype(SERIF_I,34*SS); f3=ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc",17*SS)
spaced(d,(tx,int(H*0.20)),"MUSIC SHADOW",f3,MIST,6*SS)
d.text((tx,int(H*0.33)),"Say what you couldn't say.",font=f1,fill=LINEN)
d.text((tx,int(H*0.56)),"Send the song.",font=f1,fill=LINEN)
d.line([tx,int(H*0.82),tx+60*SS,int(H*0.82)],fill=(180,120,255),width=2*SS)
img.resize((1500,500),Image.LANCZOS).convert("RGB").save("x-header-1500x500.png")

# ---- Instagram highlight covers 1080x1920-safe -> square 1080 icons
def cover(name,motif):
    S=1080*SS; im=gradbg(S,S); d=ImageDraw.Draw(im)
    c=S//2; d.ellipse([c-int(S*.42),c-int(S*.42),c+int(S*.42),c+int(S*.42)],outline=FAINT,width=3*SS)
    motif(d,c,S); im.resize((1080,1080),Image.LANCZOS).convert("RGB").save(name)
def eye(d,c,S):
    w=int(S*.30);h=int(S*.15)
    pts=[(c+x, c-int(h*math.sin(math.pi*(x+w)/(2*w))*1.0)) for x in range(-w,w+1,4)]
    low=[(c+x, c+int(h*math.sin(math.pi*(x+w)/(2*w)))) for x in range(w,-w-1,-4)]
    d.line(pts+low+[pts[0]],fill=GOLD,width=4*SS,joint="curve")
    r=int(S*.07); d.ellipse([c-r,c-r,c+r,c+r],outline=GOLD,width=4*SS)
    r=int(S*.025); d.ellipse([c-r,c-r,c+r,c+r],fill=GOLD)
def ringm(d,c,S):
    for i,r in enumerate((.05,.12,.19,.26,.33)):
        d.ellipse([c-int(S*r),c-int(S*r),c+int(S*r),c+int(S*r)],outline=GOLD,width=4*SS)
def arcm(d,c,S):
    for i,r in enumerate((.12,.20,.28,.36)):
        bb=[c-int(S*r)-int(S*.1),c-int(S*r),c+int(S*r)-int(S*.1),c+int(S*r)]
        d.arc(bb,-70,70,fill=GOLD,width=4*SS)
    d.ellipse([c+int(S*.06)-20*SS,c-20*SS,c+int(S*.06)+20*SS,c+20*SS],fill=GOLD)
cover("highlight-cover-eye.png",eye); cover("highlight-cover-rings.png",ringm); cover("highlight-cover-arcs.png",arcm)
print("ok")
