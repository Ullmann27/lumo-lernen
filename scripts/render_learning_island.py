#!/usr/bin/env python3
"""Deterministic real 3D LUMO learning-world render for mobile game assets.

Uses VTK 9/EGL and Pillow; 3D geometry, material lighting, depth and raster
are generated, never derived from screenshot text or third-party stock.
"""
import argparse
import math
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import vtk
from vtk.util.numpy_support import numpy_to_vtk

CANVAS=960
RNG=random.Random(271828)

def rgb(v):
    return tuple(x/255.0 for x in v)

def actor(mesh, color=(1,1,1), opacity=1, specular=.26, power=33, ambient=.14):
    mapper=vtk.vtkPolyDataMapper()
    mapper.SetInputData(mesh)
    a=vtk.vtkActor(); a.SetMapper(mapper)
    p=a.GetProperty();p.SetColor(*color);p.SetOpacity(opacity)
    p.SetSpecular(specular);p.SetSpecularPower(power);p.SetDiffuse(.84);p.SetAmbient(ambient)
    p.SetInterpolationToPhong()
    return a

def ellipsoid(ren,p,sc,color,theta=22,spec=.36,opacity=1):
    src=vtk.vtkSphereSource();src.SetThetaResolution(theta);src.SetPhiResolution(max(12,theta//2));src.Update()
    a=actor(src.GetOutput(),rgb(color),opacity,spec)
    a.SetScale(*sc);a.SetPosition(*p);ren.AddActor(a);return a

def tube(ren,pts, radius, color, sides=8, spec=.20):
    line=vtk.vtkPolyLine();line.GetPointIds().SetNumberOfIds(len(pts))
    vpts=vtk.vtkPoints();
    for i,p in enumerate(pts):line.GetPointIds().SetId(i,i);vpts.InsertNextPoint(*p)
    cells=vtk.vtkCellArray();cells.InsertNextCell(line)
    data=vtk.vtkPolyData();data.SetPoints(vpts);data.SetLines(cells)
    smoother=vtk.vtkSplineFilter();smoother.SetInputData(data);smoother.SetSubdivideToSpecified();smoother.SetNumberOfSubdivisions(max(12,len(pts)*4));smoother.Update()
    fil=vtk.vtkTubeFilter();fil.SetInputConnection(smoother.GetOutputPort());fil.SetRadius(radius)
    fil.SetNumberOfSides(sides);fil.CappingOn();fil.Update()
    a=actor(fil.GetOutput(),rgb(color),specular=spec);ren.AddActor(a);return a

def cone(ren,p,r,h,color,direction=(0,0,1),opacity=1):
    c=vtk.vtkConeSource();c.SetResolution(7);c.SetRadius(r);c.SetHeight(h);c.SetDirection(*direction);c.Update()
    a=actor(c.GetOutput(),rgb(color),opacity,specular=.61,power=46,ambient=.21)
    a.SetPosition(*p);ren.AddActor(a);return a

def simple_box(ren,p,sc,color,rot=0):
    c=vtk.vtkCubeSource();c.Update()
    a=actor(c.GetOutput(),rgb(color),specular=.27);a.SetPosition(*p);a.SetScale(*sc);a.RotateZ(rot);ren.AddActor(a);return a

def render_mesh(ren,points,triangles,colors,spec=.30):
    ps=vtk.vtkPoints();ps.SetData(numpy_to_vtk(np.asarray(points,dtype=np.float32),deep=1))
    c=vtk.vtkCellArray();facecols=vtk.vtkUnsignedCharArray();facecols.SetName('flatColor');facecols.SetNumberOfComponents(3)
    for ix,tri in enumerate(triangles):
        ar=vtk.vtkTriangle()
        for j,x in enumerate(tri):ar.GetPointIds().SetId(j,int(x))
        c.InsertNextCell(ar)
        facecols.InsertNextTuple3(*colors[ix])
    pd=vtk.vtkPolyData();pd.SetPoints(ps);pd.SetPolys(c);pd.GetCellData().SetScalars(facecols)
    normals=vtk.vtkPolyDataNormals();normals.SetInputData(pd);normals.ComputeCellNormalsOn();normals.ComputePointNormalsOff();normals.SplittingOn();normals.Update()
    a=actor(normals.GetOutput(),specular=spec)
    a.GetMapper().SetScalarModeToUseCellData()
    a.GetMapper().ScalarVisibilityOn()
    ren.AddActor(a)

def island(ren,x,y,z,rad=1.0,seed=4):
    rg=random.Random(seed); n=36; rads=[]
    for i in range(n):
        t=i*2*math.pi/n
        rads.append(rad*(.90+.10*math.sin(3*t+.25)+.06*math.sin(9*t)+rg.uniform(-.10,.08)))
    rings=[]
    for ir,(mul,high) in enumerate([(1.0,0),(.93,-.11),(.79,-.33),(.58,-.86),(.31,-1.32),(.02,-1.70)]):
        ring=[]
        for i in range(n):
            t=i*2*math.pi/n; rr=rads[i]*mul
            dz= rg.uniform(-.05,.05) if ir not in (0,5) else 0
            ring.append((x+rr*math.cos(t),y+rr*math.sin(t),z+high*rad+dz*rad))
        rings.append(ring)
    pts=[v for ring in rings for v in ring]
    faces=[];cols=[]
    rockcolors=[(45,73,141),(48,79,150),(67,96,172),(39,64,124),(87,110,167),(28,55,115),(64,79,146),(54,89,149)]
    for row in range(len(rings)-1):
        for i in range(n):
            nexti=(i+1)%n;a=row*n+i;b=row*n+nexti;c=(row+1)*n+i;d=(row+1)*n+nexti
            faces.extend([(a,c,b),(b,c,d)])
            for extra in (0,1):
                bcol=rockcolors[(row*11+i*7+extra*3)%len(rockcolors)]
                v=rg.uniform(.90,1.13)
                cols.append(tuple(min(255,int(q*v)) for q in bcol))
    render_mesh(ren,pts,faces,cols,.35)
    # Multi-layered raised grassy top; real geometry provides highlights.
    ellipsoid(ren,(x,y,z+.007*rad),(rad*1.02,rad*.99,.096*rad),(30,127,110),spec=.24)
    ellipsoid(ren,(x,y,z+.075*rad),(rad*.98,rad*.96,.09*rad),(49,184,126),spec=.19)
    ellipsoid(ren,(x-.08*rad,y+.11*rad,z+.112*rad),(.75*rad,.69*rad,.065*rad),(79,209,141),spec=.15)
    # Chunky rim crystals and accent rocks
    for i in range(22):
        t=2*math.pi*i/22; rr=rad*(.85+rg.uniform(-.05,.05))
        a=(x+rr*math.cos(t),y+rr*math.sin(t),z+.1*rad)
        ellipsoid(ren,a,(rg.uniform(.045,.095)*rad,rg.uniform(.045,.095)*rad,.044*rad),
                  rg.choice([(34,150,125),(59,194,150),(18,94,128)]),theta=10,spec=.11)
    return rad

def tree(ren,x,y,z,stage):
    # Stage 0 = sapling, 1 = growing, 2 = flourishing, 3 = mastered.
    height=[.70,1.37,2.06,2.25][stage]
    width=[.34,.75,1.30,1.48][stage]
    bark=(139,91,68);bark_light=(208,148,104)
    tube(ren,[(x,y,z+.01),(x+.03,y+.02,z+height*.37),
       (x-.045,y-.005,z+height*.68),(x+.01,y,z+height*.94)],max(.06,height*.073),bark,12,.12)
    tube(ren,[(x+.06,y+.027,z+.045),(x+.13,y+.04,z+height*.38),
        (x+.02,y+.065,z+height*.7)],max(.019,height*.011),bark_light,8,.13)
    ellipsoid(ren,(x,y,z+.06),(.21,.21,.11),bark,theta=14)
    if stage==0:
        ellipsoid(ren,(x-.16,y,z+height*.86),(.24,.12,.08),(54,206,144),theta=20)
        ellipsoid(ren,(x+.15,y+.02,z+height*.73),(.24,.13,.09),(88,237,176),theta=20)
        return
    rg=random.Random(777)
    palettes=[(23,104,110),(32,143,123),(45,179,131),(78,217,150),(107,234,166),(27,123,146),(55,182,168),
              (29,110,143),(69,214,173),(95,199,189),(95,216,147)]
    canopy_center=(x+.03,y,z+height*.86)
    for i in range(5+stage*5):
        t=rg.uniform(-math.pi,math.pi);phi=rg.uniform(.10,math.pi*.65)
        dist=width*rg.uniform(.43,.91)
        tip=(x+dist*math.cos(t),y+dist*.76*math.sin(t),z+height*(.69+rg.uniform(-.02,.18)))
        tube(ren,[(x,y,z+height*.50),
                  (x+tip[0]*0.5-x*.5,y+tip[1]*.5-y*.5,z+height*.75),tip],
             max(.018,height*.042*(1-dist/(width*2))),rg.choice([(153,97,67),(109,71,73),(178,118,80)]),sides=7)
    clusters=(15+stage*27)
    # 3D contour of leaf canopy made of dozens of volumetric individual clumps.
    for j in range(clusters):
        a=rg.uniform(0,2*math.pi);r=width*(.20+math.sqrt(rg.random())*.64)
        dz=(rg.uniform(-.36,.72))*height*.32 + (1-(r/width)**2)*height*.115
        p=(x+math.cos(a)*r,y+math.sin(a)*r*.76,z+height*.86+dz)
        base=rg.choice(palettes)
        scale=rg.uniform(.15,.32)*width
        ellipsoid(ren,p,(scale,scale*rg.uniform(.67,.94),scale*rg.uniform(.85,1.28)),base,theta=20,spec=.33)
        # Bright bevel / specular blooms on selected leaves.
        if j%5==0:
            ellipsoid(ren,(p[0]-.12*scale,p[1]-.24*scale,p[2]+.32*scale),
               (.40*scale,.24*scale,.14*scale),(170,250,146),theta=12,spec=.55)
    ellipsoid(ren,canopy_center,(width*.53,width*.43,height*.18), (25,107,105),spec=.14)
    # Individual 3D leaves add foliage detail instead of single smooth circles.
    points=[];tris=[];colors=[]
    leaf_count=680+stage*720
    for i in range(leaf_count):
        t=rg.uniform(0,2*math.pi);cost=rg.uniform(-.60,.90);sint=math.sqrt(max(.01,1-cost*cost))
        rr=width*(.32+.56*rg.random())
        q=np.array([x+rr*sint*math.cos(t),y+rr*.80*sint*math.sin(t),z+height*.88+cost*height*.27])
        leaflen=rg.uniform(.027,.088)*max(1,width)
        side=np.array([-math.sin(t),math.cos(t),.08]); fwd=np.array([math.cos(t),math.sin(t),.4])
        a=q-fwd*leaflen*.54;b=q+fwd*leaflen;c=q+side*leaflen*.29;d=q-side*leaflen*.29
        ix=len(points);points.extend([a,c,b,d,q+np.array([0,0,leaflen*.28])])
        base=rg.choice(palettes)
        cols=[tuple(min(255,int(v*rg.uniform(.85,1.2))) for v in base) for _ in range(4)]
        for tri,col in zip([(ix,ix+1,ix+4),(ix+1,ix+2,ix+4),(ix+2,ix+3,ix+4),(ix+3,ix,ix+4)],cols):
            tris.append(tri);colors.append(col)
    if pts_all:=len(points):render_mesh(ren,points,tris,colors,.31)
    # Sparkling collectible magical mini-lights; decorative, not progress data.
    for i in range(12+stage*10):
        a=rg.uniform(0,math.tau);t=rg.uniform(-.1,.75)
        p=(x+math.cos(a)*width*rg.uniform(.38,.85),
           y+math.sin(a)*width*.70*rg.uniform(.38,.85),z+height*.79+t*.44)
        c=rg.choice([(255,217,124),(255,245,181),(105,244,229)])
        ellipsoid(ren,p,(.025,.025,.035),c,theta=10,spec=.95)

def crystal_cluster(ren,x,y,z,scale=1):
    col=[(84,224,240),(70,152,233),(164,120,244),(102,250,224)]
    for i in range(5):
        dx=(i-2)*.105*scale;dy=((i*3)%4-2)*.06*scale
        height=(.14+(i%3)*.11)*scale
        cone(ren,(x+dx,y+dy,z+height*.43),.09*scale,height,col[i%len(col)],(0,0,1))
        ellipsoid(ren,(x+dx,y+dy,z+.035*scale),(.065*scale,.065*scale,.035*scale),col[i%len(col)],theta=10)

def flowers(ren,x,y,z,rad,seed=666):
    rg=random.Random(seed)
    for i in range(130):
        theta=rg.random()*math.tau;rr=rg.random()**.62*rad*.93
        px=x+rr*math.cos(theta);py=y+rr*math.sin(theta);pz=z+.16*rad
        c=rg.choice([(255,219,100),(255,151,181),(207,123,245),(142,247,244),(247,123,174),(255,241,180)])
        r=rg.uniform(.018,.040)*rad
        if i%7==0:
            tube(ren,[(px,py,pz-.03),(px,py,pz+.065*rad)],.007*rad,(34,125,77),6)
        ellipsoid(ren,(px,py,pz+.065*rad),(r,r,r*.65),c,theta=10,spec=.34)
        if i%23==0:
            ellipsoid(ren,(px,py,pz+.08*rad),(.007,.007,.010),(255,255,211),theta=8)

def cottage(ren,x,y,z,scale=1):
    # A tiny wood fairy cottage, warm lit windows and a roof as two sloped slabs.
    simple_box(ren,(x,y,z+.20*scale),(.32*scale,.28*scale,.32*scale),(247,186,120))
    cone(ren,(x,y,z+.44*scale),.30*scale,.25*scale,(70,81,144))
    simple_box(ren,(x,y-.147*scale,z+.20*scale),(.11*scale,.02*scale,.17*scale),(254,223,132))
    simple_box(ren,(x+.09*scale,y-.155*scale,z+.28*scale),(.07*scale,.02*scale,.085*scale),(255,251,187))
    ellipsoid(ren,(x+.09*scale,y-.179*scale,z+.28*scale),(.06*scale,.007*scale,.07*scale),(255,242,151),theta=14,opacity=.75)
    simple_box(ren,(x+.09*scale,y+.01*scale,z+.54*scale),(.048*scale,.048*scale,.16*scale),(132,92,111))

def waterfall(ren,x,y,z,depth=.95):
    # Semi-transparent volumetric water ribbon with highlights at island edge.
    for i in range(7):
        xx=x+(i-3)*.044;zz=z-.13
        rg=random.Random(1200+i)
        pts=[]
        for j in range(9):
            f=j/8
            pts.append((xx+.05*math.sin(f*3+i*.5),y-.03-f*.09,zz-depth*f))
        color=[(110,239,246),(177,248,255),(54,175,252),(60,203,247)][i%4]
        tube(ren,pts,.028 if i%3==0 else .022,color,6,.58)
    ellipsoid(ren,(x,y,z-.13),(.24,.095,.045),(106,242,255),theta=16,opacity=.89)

def setup():
    ren=vtk.vtkRenderer();ren.SetBackground(0.014,0.038,0.16)
    ren.SetBackgroundAlpha(0.0)
    rw=vtk.vtkRenderWindow();rw.SetOffScreenRendering(1);rw.SetMultiSamples(8)
    rw.SetSize(CANVAS,CANVAS);rw.SetAlphaBitPlanes(1);rw.AddRenderer(ren)
    for pos,col,inten in [((3,-5,8),(1.,.92,.81),1.18),((-5,2,6),(.32,.76,1.),.47),((1,5,7),(1.,.74,.49),.55)]:
        li=vtk.vtkLight();li.SetLightTypeToSceneLight();li.SetPosition(*pos)
        li.SetFocalPoint(0,0,0);li.SetColor(*col);li.SetIntensity(inten);ren.AddLight(li)
    ren.SetAutomaticLightCreation(False)
    camera=ren.GetActiveCamera();camera.SetPosition(5.2,-8.0,5.15)
    camera.SetFocalPoint(0,0,.42);camera.SetViewUp(0,0,1)
    camera.SetParallelProjection(True);camera.SetParallelScale(3.55)
    return ren,rw

def postprocess(im,stage):
    im=im.convert('RGBA')
    arr=np.array(im)
    # original translucency is preserved; bright highlight blooms remain inside mask.
    lum=(arr[:,:,:3].astype(np.float32)*np.array([.2,.68,.12])).sum(axis=2)
    bright=((np.clip((lum-115)*1.35,0,190)).astype(np.uint8))
    glows=np.zeros_like(arr);glows[:,:,0]=60;glows[:,:,1]=228;glows[:,:,2]=255
    glows[:,:,3]=((bright.astype(np.float32)*arr[:,:,3]/255)*.34).astype(np.uint8)
    glow=Image.fromarray(glows,'RGBA').filter(ImageFilter.GaussianBlur(16))
    cloud=Image.alpha_composite(glow,im)
    # Glow around decorative crystals and leaves adds holographic sheen.
    draw=ImageDraw.Draw(cloud,'RGBA')
    for i in range(10+stage*5):
        rg=random.Random(558+i+stage*100)
        x=rg.randint(200,790);y=rg.randint(200,700);r=rg.choice([1,1,2])
        draw.ellipse((x-r,y-r,x+r,y+r),fill=(221,245,255,120))
    return cloud

def render_hero(stage,out):
    ren,rw=setup()
    island(ren,0,0,-.33,1.54,77+stage)
    tree(ren,0,.11,-.04,stage)
    flowers(ren,0,0,-.33,1.40,600+stage)
    # High-detail miniature landscape elements.
    crystal_cluster(ren,-.89,-.65,-.10,.92)
    crystal_cluster(ren,.78,.26,-.13,.66)
    cottage(ren,1.08,.38,-.14,.77)
    cottage(ren,-.98,.46,-.17,.50)
    waterfall(ren,1.05,-.58,-.32,1.23)
    waterfall(ren,-1.0,-.53,-.26,.77)
    for i in range(11):
        t=i*math.tau/11
        x=math.cos(t)*1.18;y=math.sin(t)*1.08
        cone(ren,(x,y,-.10),.07,.16,(47,120,95))
        ellipsoid(ren,(x,y,-.02),(.10,.10,.075),(38,168,122),theta=14)
    rw.Render()
    img=vtk.vtkWindowToImageFilter();img.SetInput(rw);img.SetInputBufferTypeToRGBA();img.ReadFrontBufferOff();img.Update()
    data=img.GetOutput();w,h=data.GetDimensions()[:2]
    from vtk.util.numpy_support import vtk_to_numpy
    pixels=vtk_to_numpy(data.GetPointData().GetScalars()).reshape(h,w,4)
    # VTK OpenGL output is bottom-up.
    im=Image.fromarray(pixels[::-1].copy(),'RGBA')
    result=postprocess(im,stage)
    out.parent.mkdir(parents=True,exist_ok=True)
    result.save(out,optimize=True)
    print(out, 'pixels',result.size,'bytes',out.stat().st_size)
    rw.Finalize()

def make_world_wallpaper(heroes,out):
    w,h=1080,1920
    y=np.arange(h)[:,None].astype(np.float32);x=np.arange(w)[None,:].astype(np.float32)
    # Physically-inspired stellar atmospheric gradient, with spatial depth.
    hue=np.empty((h,w,4),dtype=np.uint8)
    hglow=np.exp(-((x-w*.48)**2/(w*.74)**2+(y-h*.64)**2/(h*.38)**2))
    horizon=np.exp(-((y-h*.74)**2/(h*.29)**2))
    hue[:,:,0]=np.clip(3+13*y/h+18*hglow,0,255)
    hue[:,:,1]=np.clip(15+31*y/h+61*hglow+17*horizon,0,255)
    hue[:,:,2]=np.clip(46+91*y/h+70*hglow,0,255)
    hue[:,:,3]=255
    im=Image.fromarray(hue,'RGBA')
    fog=Image.new('RGBA',(w,h));fdraw=ImageDraw.Draw(fog,'RGBA')
    rg=random.Random(442)
    for i in range(52):
        xx=rg.randint(-150,w+150);yy=rg.randint(350,h+200)
        radius=rg.randint(120,340)
        c=rg.choice([(74,122,235,21),(114,177,255,21),(70,183,204,12)])
        fdraw.ellipse((xx-radius,yy-radius*.44,xx+radius,yy+radius*.44),fill=c)
    fog=fog.filter(ImageFilter.GaussianBlur(56))
    im=Image.alpha_composite(im,fog)
    # Distant floating miniature islands and big learning tree, all same 3D scene rendering.
    p=Image.open(heroes[3]).convert('RGBA')
    for loc,scale,opacity in [((85,245),.20,.45),((770,350),.16,.34),((875,740),.12,.30),
                             ((-70,1090),.25,.24),((792,1345),.24,.24)]:
        q=p.resize((int(p.width*scale),int(p.height*scale)),Image.Resampling.LANCZOS)
        a=q.getchannel('A').point(lambda v:int(v*opacity));q.putalpha(a)
        im.alpha_composite(q,loc)
    # Foreground main world: hero island, massive visual scale on phone.
    p=Image.open(heroes[2]).convert('RGBA')
    p=p.resize((920,920),Image.Resampling.LANCZOS)
    im.alpha_composite(p,(80,410))
    sparks=Image.new('RGBA',(w,h));d=ImageDraw.Draw(sparks,'RGBA')
    for i in range(230):
        sx=rg.randint(4,w-4);sy=rg.randint(6,h-8);v=rg.choice([1,1,1,2,2,3]);alpha=rg.randint(65,210)
        d.ellipse((sx-v,sy-v,sx+v,sy+v),fill=(165,228,255,alpha))
        if i%25==0:
            d.line((sx-v*4,sy,sx+v*4,sy),fill=(139,238,255,alpha),width=1)
            d.line((sx,sy-v*4,sx,sy+v*4),fill=(139,238,255,alpha),width=1)
    im=Image.alpha_composite(im,sparks)
    im.convert('RGB').save(out,quality=90,optimize=True)
    print(out,'bytes',out.stat().st_size)

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--output',default='assets/lumo_design/learning_world');ap.add_argument('--stage',type=int,default=-1)
    args=ap.parse_args();output=Path(args.output);output.mkdir(parents=True,exist_ok=True)
    stages=range(4) if args.stage<0 else [args.stage]
    arts=[]
    for j in stages:
        name=output/f'learning_tree_stage_{j}.png';render_hero(j,name);arts.append(name)
    if args.stage<0:make_world_wallpaper(arts,output/'learning_world_night.jpg')

if __name__=='__main__':main()