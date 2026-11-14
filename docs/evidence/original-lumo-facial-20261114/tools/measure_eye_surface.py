"""Project original triangles/UVs to measure the painted eye support surface."""
import json
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage
BASE=Path(__file__).resolve().parents[1]
geom=np.load(BASE/'evidence/inspection/source_geometry.npz')
pos,uv,tris=geom['positions'],geom['uv'],geom['indices']
tex=np.asarray(Image.open(BASE/'evidence/inspection/Image_0.png').convert('RGB'))
w,h=800,400
xmin,xmax,ymin,ymax=-.20,.20,1.27,1.47
zbuf=np.full((h,w),-.5,np.float32); colors=np.zeros((h,w,3),np.uint8)
uvmap=np.zeros((h,w,2),np.float32)
for tri in tris:
 p=pos[tri]
 if p[:,2].max()<.18 or p[:,0].min()>xmax or p[:,0].max()<xmin or p[:,1].max()<ymin or p[:,1].min()>ymax:continue
 q=np.column_stack(((p[:,0]-xmin)/(xmax-xmin)*(w-1),(ymax-p[:,1])/(ymax-ymin)*(h-1)))
 lo=np.maximum([0,0],np.floor(q.min(0)).astype(int));hi=np.minimum([w-1,h-1],np.ceil(q.max(0)).astype(int))
 if np.any(hi<lo):continue
 den=(q[1,1]-q[2,1])*(q[0,0]-q[2,0])+(q[2,0]-q[1,0])*(q[0,1]-q[2,1])
 if abs(den)<1e-7:continue
 X,Y=np.meshgrid(np.arange(lo[0],hi[0]+1),np.arange(lo[1],hi[1]+1))
 a=((q[1,1]-q[2,1])*(X-q[2,0])+(q[2,0]-q[1,0])*(Y-q[2,1]))/den
 b=((q[2,1]-q[0,1])*(X-q[2,0])+(q[0,0]-q[2,0])*(Y-q[2,1]))/den;c=1-a-b
 mask=(a>=0)&(b>=0)&(c>=0)
 z=a*p[0,2]+b*p[1,2]+c*p[2,2]
 mask&=z>zbuf[Y,X]
 if not mask.any():continue
 U=a*uv[tri[0],0]+b*uv[tri[1],0]+c*uv[tri[2],0];V=a*uv[tri[0],1]+b*uv[tri[1],1]+c*uv[tri[2],1]
 tx=np.clip(np.rint(U*1024).astype(int),0,1023);ty=np.clip(np.rint(V*1024).astype(int),0,1023)
 yy,xx=Y[mask],X[mask];zbuf[yy,xx]=z[mask];colors[yy,xx]=tex[ty[mask],tx[mask]];uvmap[yy,xx]=np.column_stack((U[mask],V[mask]))
out=BASE/'evidence/eye-surface';out.mkdir(exist_ok=True)
Image.fromarray(colors).save(out/'original-textured-surface.png')
np.savez_compressed(out/'projected-surface.npz',z=zbuf,uv=uvmap,colors=colors,bounds=np.array([xmin,xmax,ymin,ymax]))
report={'method':'Orthographic projection of exact original triangles and UV-sampled original basecolor. No landmarks claimed from model names. Eye contours artist-selected after this measured surface.'}
for sign,name in [(1,'left'),(-1,'right')]:
 X,Y=np.meshgrid(np.linspace(xmin,xmax,w),np.linspace(ymax,ymin,h))
 r,g,b=[colors[:,:,k].astype(float) for k in range(3)]
 mask=(sign*X>.045)&(sign*X<.174)&(Y>1.298)&(Y<1.417)&((r<g*1.20)|(np.maximum.reduce([r,g,b])<95))&(zbuf>.20)
 mask=ndimage.binary_fill_holes(ndimage.binary_closing(mask,iterations=2))
 labels,n=ndimage.label(mask);sizes=ndimage.sum(mask,labels,range(1,n+1));mask=labels==(int(np.argmax(sizes))+1)
 ys,xs=np.nonzero(mask)
 report[name]={'painted_region_pixels':int(len(ys)),'bounds':[float(X[ys,xs].min()),float(X[ys,xs].max()),float(Y[ys,xs].min()),float(Y[ys,xs].max())],'z_range':[float(zbuf[ys,xs].min()),float(zbuf[ys,xs].max())]}
 Image.fromarray((mask*255).astype('uint8')).save(out/(name+'-paint-mask.png'))
(out/'measurement.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
