c Solves the epidemic 1D problem from the text
c Constant time step: 4th order ETDRK4-B
      program reaction_diffusion
      implicit none

* PROGRAM LOCAL PARAMETER & VARIABLE 
c     n are the number of modes (a power of 2)
      integer n,mxneq
      parameter(mxneq=2048,n=128)
      integer nprint,it,count,m2,khalfp,mm,kn,i,k,ncount
      double precision length,time,dt,dy
      double precision lambda,epsilon,eps
* SERVICE VARIABLES
      double precision u(2,n),yf(mxneq),ee(2,n),ee2(2,n),u1(2,n),
     .u2(2,n)
     .,u3(2,n),u4(2,n),fftu(2,n),fftu2(2,n),fftu3(2,n),fftu4(2,n)
     ., a(2,n),b(2,n),c(2,n),d(2,n),fftd(2,n)
     .,ffta(2,n),fftb(2,n),fftc(2,n)
* ETDRK4-B variables
      integer m,j,ic
      parameter(m=16)
      double complex roots(m),ival,ipi,one,lr(n,m),lr3(n,m),elr(n,
     + m),elr2(n,m),zero,lr2(n,m),four,three,two
      double precision q(n,2),qb1(n,2),qb2(n,2),qc1(n,2)
     +,qc3(n,2),f1(n,2),f2(n,2),f3(n,2)
* COMMON BLOCKS
      double precision trigy(2,mxneq)
      integer nfay, ifay(20)
      common/yfac/trigy,nfay,ifay
      double precision wavey1(mxneq), wavey2(mxneq)
      common/wvz/wavey1,wavey2
      common/space/yf
      double precision asn60,root
      common/roots/asn60,root
      double precision pi
      common/pival/pi
      common/parms/lambda,epsilon

c     useful variables
      asn60=0.5d0*dsqrt(3d0)
      root=1d0/dsqrt(2d0)
      pi=4d0*datan(1d0)

      open(50,file='epid_ETDRK4_B.dat',status='unknown')

       dy=2d0*pi/dble(n)
       dt=0.1d0
       length=75d0
       epsilon=0.1d0
       lambda=0.85d0
       ncount=100
       nprint=5

c +++++++++++++++++++initial condition++++++++++++++++++++++++++
         do k=1,n
            yf(k)=(dble(k-1)*dy)
            yf(k)=length*(yf(k)-pi)/pi
         u(1,k)=dexp(-1d0*yf(k)*yf(k))
         u(2,k)=1d0
         enddo

c++++++++++++++++fft derivative initialization +++++++++++++++++
      call prefft(n,nfay,ifay,trigy)
      kn=n
      khalfp=n/2+1
      do i=1,n
         mm=i/khalfp
         m2=mm*n+1
         wavey1(i)=dble(i-m2)*pi/length
         wavey2(i)=wavey1(i)*wavey1(i)
      enddo
         wavey1(khalfp)=0.0d0

c +++++++++++++++++++ set up etdrk4-b +++++++++++++++++++++++++
      do k=1,n
            u1(1,k)=u(1,k)
            u1(2,k)=u(2,k)
         ee2(1,k)=dexp(-wavey2(k)*dt/2d0)
         ee(1,k)=dexp(-wavey2(k)*dt)
         ee2(2,k)=dexp(-epsilon*wavey2(k)*dt/2d0)
         ee(2,k)=dexp(-epsilon*wavey2(k)*dt)
       enddo

       ival=dcmplx(0d0,1d0)
       ipi=dcmplx(0d0,4d0*datan(1d0))
       one=dcmplx(1d0,0d0)
       two=dcmplx(2d0,0d0)
       zero=dcmplx(0d0,0d0)
       four=dcmplx(4d0,0d0)
       three=dcmplx(3d0,0d0)
       do i=1,m
        roots(i)=cdexp(ipi*dcmplx((dble(i)-0.5d0)/dble(m),0d0))
       enddo

       do ic=1,2
          if(ic.eq.2) then
             eps=epsilon
          else
             eps=1d0
          endif

          do k=1,n
          do j=1,m
           lr(k,j)=-dcmplx(eps*dt*wavey2(k),0d0)+roots(j)
           lr3(k,j)=lr(k,j)**dcmplx(3d0,0d0)
           lr2(k,j)=lr(k,j)**two
           elr(k,j)=cdexp(lr(k,j))
           elr2(k,j)=cdexp(lr(k,j)/two)
          enddo
           q(k,ic)=0d0
           qb1(k,ic)=0d0
           qb2(k,ic)=0d0
           qc1(k,ic)=0d0
           qc3(k,ic)=0d0
           f1(k,ic)=0d0
           f2(k,ic)=0d0
           f3(k,ic)=0d0
       enddo

       do k=1,n
          do j=1,m
             q(k,ic)=q(k,ic)+dble((elr2(k,j)-one)/lr(k,j))
             qb1(k,ic)=qb1(k,ic)+dble((elr2(k,j)*(lr(k,j)-four)
     +       +lr(k,j)+four)/lr2(k,j))
             qb2(k,ic)=qb2(k,ic)+dble((four*elr2(k,j)-
     +         two*lr(k,j)-four)/lr2(k,j))
             qc1(k,ic)=qc1(k,ic)+dble(((lr(k,j)-two)*
     +       elr(k,j)+lr(k,j)+two)/lr2(k,j))
             qc3(k,ic)=qc3(k,ic)+dble((two*elr(k,j)
     +        -two*lr(k,j)-two)/lr2(k,j))

             f1(k,ic)=f1(k,ic)+dble((elr(k,j)*
     +        (four-three*lr(k,j)+lr2(k,j))-
     +        four-lr(k,j))/lr3(k,j))

             f2(k,ic)=f2(k,ic)+dble((elr(k,j)*(-two+lr(k,j))+
     +        two+lr(k,j))/lr3(k,j))

             f3(k,ic)=f3(k,ic)+dble((elr(k,j)*(four-lr(k,j))-
     +        four-three*lr(k,j)-lr2(k,j))/lr3(k,j))

          enddo
       q(k,ic)=dt*q(k,ic)/dble(m)
       qb1(k,ic)=dt*qb1(k,ic)/dble(m)
       qb2(k,ic)=dt*qb2(k,ic)/dble(m)
       qc1(k,ic)=dt*qc1(k,ic)/dble(m)
       qc3(k,ic)=dt*qc3(k,ic)/dble(m)
       f1(k,ic)=dt*f1(k,ic)/dble(m)
       f2(k,ic)=dt*f2(k,ic)/dble(m)
       f3(k,ic)=dt*f3(k,ic)/dble(m)
       enddo

       enddo

c+++++++++++++++++++the time stepping routine ++++++++++++++++++
c     4th order ETDRK4-B Krogstad's modification of Cox & Matthews
       do 90 it=1,nprint
c     +++++++++++++++++++ a loop taken until print out ++++++++++
         do count=1,ncount 
          time=dble(it*count)*dt

       do k=1,n
          call righthandside(a(1,k),a(2,k),u1(1,k),u1(2,k))
       enddo
       call fft1(a,ffta,n,nfay,ifay,-1,trigy)
       call fft1(u1,fftu,n,nfay,ifay,-1,trigy)

       do k=1,n
      fftu2(1,k)=ee2(1,k)*fftu(1,k)+q(k,1)*ffta(1,k)
      fftu2(2,k)=ee2(2,k)*fftu(2,k)+q(k,2)*ffta(2,k)
       enddo
       call fft1(fftu2,u2,n,nfay,ifay,+1,trigy)

       do k=1,n
          call righthandside(b(1,k),b(2,k),u2(1,k),u2(2,k))
       enddo
       call fft1(b,fftb,n,nfay,ifay,-1,trigy)

       do k=1,n
      fftu3(1,k)=ee2(1,k)*fftu(1,k)+
     +qb1(k,1)*ffta(1,k)+qb2(k,1)*fftb(1,k)
      fftu3(2,k)=ee2(2,k)*fftu(2,k)+
     +qb1(k,2)*ffta(2,k)+qb2(k,2)*fftb(2,k)
       enddo
       call fft1(fftu3,u3,n,nfay,ifay,+1,trigy)

       do k=1,n
          call righthandside(c(1,k),c(2,k),u3(1,k),u3(2,k))
       enddo
       call fft1(c,fftc,n,nfay,ifay,-1,trigy)

       do k=1,n
       fftu4(1,k)=ee(1,k)*fftu(1,k)+
     + qc1(k,1)*ffta(1,k)+qc3(k,1)*fftc(1,k)
       fftu4(2,k)=ee(2,k)*fftu(2,k)+
     + qc1(k,2)*ffta(2,k)+qc3(k,2)*fftc(2,k)
       enddo
       call fft1(fftu4,u4,n,nfay,ifay,+1,trigy)

          do k=1,n
          call righthandside(d(1,k),d(2,k),u4(1,k),u4(2,k))
          enddo
       call fft1(d,fftd,n,nfay,ifay,-1,trigy)

        do k=1,n
       fftu(1,k)=ee(1,k)*fftu(1,k)+f1(k,1)*ffta(1,k)
     . +2d0*f2(k,1)*(fftb(1,k)+fftc(1,k))+f3(k,1)*fftd(1,k)
       fftu(2,k)=ee(2,k)*fftu(2,k)+f1(k,2)*ffta(2,k)
     . +2d0*f2(k,2)*(fftb(2,k)+fftc(2,k))+f3(k,2)*fftd(2,k)
          enddo

       call fft1(fftu,u1,n,nfay,ifay,+1,trigy)
       enddo
c     +++++++++++++++++ end of time loop  ++++++++++++++++++++++++

      write(*,*) 'Time= ',time
      do k=1,n
        write(50,*) sngl(yf(k)),sngl(u1(1,k)),sngl(u1(2,k))
      enddo

 90      continue

      end

c     +++++++++++++++++ the nonlinear terms in the pde +++++++++++++
      subroutine righthandside(rhs1,rhs2,u,v)
      implicit none
      double precision rhs1,rhs2,u,v,tmp
* COMMON BLOCKS
      double precision lambda,epsilon
      common /parms/ lambda,epsilon
      tmp=u*v
      rhs1=(tmp-lambda*u)
      rhs2=-tmp
      return
      end

c     +++++++++++++++++++FFT routines ++++++++++++++++++++++++++++++
c     These are primarily from Canuto et al 1988 Spectral Methods in
c     Fluid Mechanics, Springer-Verlag

      subroutine fft1(a,c,n,nfax,ifax,isign,trig)
      implicit none
      integer mxneq,n,i,ifac,la,nfax,isign,ij
      parameter(mxneq=2048)
      double precision a(2,0:n-1),c(2,0:n-1)
      double precision trig(2,0:mxneq-1),pi,xni
      integer ifax(*)
      logical odd
      common/pival/pi

      la=1
      odd=.true.
      do 10 i=1,nfax
         ifac=ifax(i)
         if(odd)then
            call pass1(a,c,n,isign,ifac,la,trig,1)
         else
            call pass1(c,a,n,isign,ifac,la,trig,1)
         endif
         odd=.not. odd
         la=la*ifac
 10   continue
      if(odd)then
         do 30 i=0,n-1
            do 20 ij=1,2
               c(ij,i)=a(ij,i)
 20         continue
 30      continue
      endif
      if(isign.eq.-1) then
         xni=1./n
         do 50 i=0,n-1
            do 40 ij=1,2
               c(ij,i)=xni*c(ij,i)
 40         continue
 50      continue
      endif
      return
      end

      subroutine pass1(a,c,n,isign,ifac,la,trig,len)
      implicit none 
      integer mxneq,n
      parameter(mxneq=2048)
      double precision a(1,2,0:n-1),c(1,2,0:n-1),cc,ss,sn60,root,asn60
     +     ,trig(2,0:mxneq-1),t1,t2,s1,s2,c1,c2,ta1,ta2,ap1,ap2,am1,am2
      integer ind(0:20),jnd(0:20),j2,i2,ij,j0,j1,i0,i1,l,jump,i,k,j,m
     +     ,ifac,la,isign,len
      common/roots/asn60,root
      sn60=dble(isign)*asn60
      m=n/ifac

      do 10 k=0,ifac-1
         ind(k)=k*m
         jnd(k)=k*la
 10   continue

      i=0
      j=0
      jump=(ifac-1)*la
      do 130 k=0,m-la,la
         do 120 l=1,la
            if(ifac.eq.2)then
               i0=ind(0)+i
               i1=ind(1)+i
               j0=jnd(0)+j
               j1=jnd(1)+j
               cc=trig(1,k)
               ss=isign*trig(2,k)
               if(k.eq.0) then
                  do 20 ij=1,len
                     c(ij,1,j0)=a(ij,1,i0)+a(ij,1,i1)
                     c(ij,2,j0)=a(ij,2,i0)+a(ij,2,i1)
                     c(ij,1,j1)=a(ij,1,i0)-a(ij,1,i1)
                     c(ij,2,j1)=a(ij,2,i0)-a(ij,2,i1)
 20               continue
               else
                  do 50 ij=1,len
                     c(ij,1,j0)=a(ij,1,i0)+a(ij,1,i1)
                     c(ij,2,j0)=a(ij,2,i0)+a(ij,2,i1)
                     am1=a(ij,1,i0)-a(ij,1,i1)
                     am2=a(ij,2,i0)-a(ij,2,i1)
                     c(ij,1,j1)=cc*am1-ss*am2
                     c(ij,2,j1)=ss*am1+cc*am2
 50               continue
               endif
            elseif(ifac.eq.3) then
               i0=ind(0)+i
               i1=ind(1)+i
               i2=ind(2)+i
               j0=jnd(0)+j
               j1=jnd(1)+j
               j2=jnd(2)+j
               if(k.eq.0)then
                  do 60 ij=1,len
                     ap1=a(ij,1,i1)+a(ij,1,i2)
                     ap2=a(ij,2,i1)+a(ij,2,i2)
                     c(ij,1,j0)=a(ij,1,i0)+ap1
                     c(ij,2,j0)=a(ij,2,i0)+ap2
                     ta1=a(ij,1,i0)-0.5*ap1
                     ta2=a(ij,2,i0)-0.5*ap2
                     am1=sn60*(a(ij,1,i1)-a(ij,1,i2))
                     am2=sn60*(a(ij,2,i1)-a(ij,2,i2))
                     c(ij,1,j1)=ta1-am2
                     c(ij,2,j1)=ta2+am1
                     c(ij,1,j2)=ta1+am2
                     c(ij,2,j2)=ta2-am1
 60               continue
               else
                  c1=trig(1,k)
                  c2=trig(1,2*k)
                  s1=isign*trig(2,k)
                  s2=isign*trig(2,2*k)
                  do 70 ij=1,len
                     ap1=a(ij,1,i1)+a(ij,1,i2)
                     ap2=a(ij,2,i1)+a(ij,2,i2)
                     c(ij,1,j0)=a(ij,1,i0)+ap1
                     c(ij,2,j0)=a(ij,2,i0)+ap2
                     ta1=a(ij,1,i0)-0.5*ap1
                     ta2=a(ij,2,i0)-0.5*ap2
                     am1=sn60*(a(ij,1,i1)-a(ij,1,i2))
                     am2=sn60*(a(ij,2,i1)-a(ij,2,i2))
                     t1=ta1-am2
                     t2=ta2+am1
                     c(ij,1,j1)=c1*t1-s1*t2
                     c(ij,2,j1)=s1*t1+c1*t2
                     t1=ta1+am2
                     t2=ta2-am1
                     c(ij,1,j2)=c2*t1-s2*t2
                     c(ij,2,j2)=s2*t1+c2*t2
 70               continue
               endif
            endif
            i=i+1
            j=j+1
 120     continue
         j=j+jump
 130  continue
      return
      end


      subroutine prefft(n,nfax,ifax,trig)
      implicit none
      integer mxneq,k,n,nfax
      parameter(mxneq=2048)
      double precision trig(2,0:mxneq-1),arg,pi
      integer ifax(*)
      common/pival/pi
      call factor(n,nfax,ifax)
      do k=0,n-1
         arg=2d0*pi*dble(k)/dble(n)
         trig(1,k)=dcos(arg)
         trig(2,k)=dsin(arg)
      enddo
      return
      end

      subroutine factor(n,nfax,ifax)
      implicit none
      integer ifax(*),ii,n,nfax,nn
      nfax=0
      nn=n

      do 10 ii=1,20
         if(nn.eq.3*(nn/3)) then
            nfax=nfax+1
            ifax(nfax)=3
            nn=nn/3
         else
            goto 20
         endif
 10   continue
 20   continue

      do 30 ii=nfax+1,20
         if(nn.eq.2*(nn/2)) then
            nfax=nfax+1
            ifax(nfax)=2
            nn=nn/2
         else
            goto 40
         endif
 30   continue
 40   continue
      if(nn.ne.1)then
         stop
      endif
      return
      end

