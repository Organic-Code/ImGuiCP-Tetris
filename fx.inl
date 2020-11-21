#define F(a,b)for(int a=b;a--;)
#define G(a)F(a,3)
#define S(a,b)s(c[a], c[b]);
#define C(a,b,c)a>b?b:a<c?c:a
int T[41][21];
int pc[][9]={{1,1,1},{0,1,1,0,1,1},{1,1,1,0,1},{1,1,1,1},{1,1,1,0,0,1},{1,1,0,0,1,1},{0,1,1,1,1}};
int* c{};
int p{0};
int f=0;
using V=ImVec2;
void s(int&a,int&b){int d=a;a=b;b=d;}
void FX(ImDrawList*d,V a,V,V,ImVec4 m,float t) {
	F(i,21) T[40][i]=1;
	if (!m.z)
		S(0,6)S(1,5)S(2,8)S(3,7)S(3,5)S(0,8)
	if (!p)
		F(i,40) {
			c = pc[(int)t%7];
			int s=-21;
			F(j,21)s+=T[i][j];
			if (!s)F(j,i)F(k,21)T[j+1][k]=T[j][k];
	}
	int y=m.y*23-1.;
	if (y<0){
		if(!(c[0]|c[1]|c[2]))
			G(i){
				c[i]=c[i+3];
				c[i+3]=c[i+6];
				c[i+6]=0;
			}
		y=0;
	}
	if(y>18){
		if(!(c[6]|c[7]|c[8]))
			G(i) {
				c[i+6]=c[i+3];
				c[i+3]=c[i];
				c[i]=0;
			}
		y=18;
	}
	if(m.w>0|!(++f%8))++p;
	G(i)G(j)
		if(c[j*3+i] & T[p +i+1][y+j]){
			G(k)G(l)
				T[p+k][y+l]|=c[l*3+k];
			p=0;
		}
#define P(x,y)a+V(x,y)*8,a+V(x+1,y+1)*8
#define R(x,y,c)d->AddRectFilled(P(x,y),c);
	F(i,40)F(j,21)
		if (T[i][j])R(i,j,0xFFFA6225)
	G(i)G(j)
		if (c[j*3+i])R(i+p,j+y, 0xFF34CFEB)

#define L(w,z)d->AddLine(a+V(p,y)*8,a+V(p+w,y+z)*8,0x50FFFFFF);
	L(3,0)L(0,3)p+=3;y+=3;
	L(0,-3)L(-3,0)p-=3;
}