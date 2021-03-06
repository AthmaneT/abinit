!{\src2tex{textfont=tt}}
!!****f* ABINIT/zprecon3
!!
!! NAME
!! zprecon3
!!
!! FUNCTION
!! precondition $<G|(H-e_{n,k})|C_{n,k}>$
!! for a block of band (band-FFT parallelisation)
!! in the case of real WFs (istwfk/=1)
!!
!! COPYRIGHT
!! Copyright (C) 1998-2012 ABINIT group (DCA, XG, GMR, GZ, FB, MT)
!! this file is distributed under the terms of the
!! gnu general public license, see ~abinit/COPYING
!! or http://www.gnu.org/copyleft/gpl.txt .
!! for the initials of contributors, see ~abinit/doc/developers/contributors.txt .
!!
!! INPUTS
!!  blocksize= size of blocks of bands
!!  $cg(vectsize,blocksize)=<G|C_{n,k}> for a block of bands$.
!!  $eval(blocksize,blocksize)=current block of bands eigenvalues=<C_{n,k}|H|C_{n,k}>$.
!!  $ghc(vectsize,blocksize)=<G|H|C_{n,k}> for a block of bands$.
!!  iterationnumber=number of iterative minimizations in LOBPCG 
!!  kinpw(npw)=(modified) kinetic energy for each plane wave (Hartree)
!!  mpi_enreg=informations about MPI parallelization
!!  nspinor=number of spinorial components of the wavefunctions (on current proc)
!!  $vect(vectsize,blocksize)=<G|H|C_{n,k}> for a block of bands$.
!!  npw=number of planewaves at this k point.
!!  optekin= 1 if the kinetic energy used in preconditionning is modified
!!             according to Kresse, Furthmuller, PRB 54, 11169 (1996)
!!           0 otherwise
!!  optpcon= 0 the TPA preconditionning matrix does not depend on band 
!!           1 the TPA preconditionning matrix (not modified)
!!           2 the TPA preconditionning matrix is independant of iterationnumber 
!!  vectsize= size of vectors
!!
!! OUTPUT
!!  vect(2,npw)=<g|(h-eval)|c_{n,k}>*(polynomial ratio)
!!
!! SIDE EFFECTS
!!  pcon(npw,blocksize)=preconditionning matrix
!!            input  if optpcon=0,2 and iterationnumber/=1
!!            output if optpcon=0,2 and iterationnumber==1
!!
!! PARENTS
!!      lobpcgccIIIwf,m_lobpcg
!!
!! CHILDREN
!!      timab,wrtout,xcomm_init,xsum_mpi
!!
!! SOURCE

#if defined HAVE_CONFIG_H
#include "config.h"
#endif

#include "abi_common.h"

subroutine zprecon3(cg,eval,blocksize,iterationnumber,kinpw,mpi_enreg,npw,nspinor,optekin,optpcon,pcon,ghc,vect,vectsize)

 use m_profiling

 use defs_basis
 use defs_datatypes
 use defs_abitypes
 use m_xmpi

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'zprecon3'
 use interfaces_14_hidewrite
 use interfaces_18_timing
 use interfaces_51_manage_mpi
!End of the abilint section

 implicit none

!Arguments ------------------------------------
!scalars
 integer,intent(in) :: blocksize,iterationnumber,npw,nspinor,optekin
 integer,intent(in) :: optpcon,vectsize
 type(mpi_type),intent(inout) :: mpi_enreg
!arrays
 real(dp) :: kinpw(npw)
 real(dp),intent(inout) :: pcon(npw,blocksize)
 complex(dpc),intent(in) :: cg(vectsize,blocksize),eval(blocksize,blocksize)
 complex(dpc),intent(in) :: ghc(vectsize,blocksize)
 complex(dpc),intent(inout) :: vect(vectsize,blocksize)

!Local variables-------------------------------
!scalars
 integer :: iblocksize,ierr,ig,igs,ispinor,old_paral_level,spaceComm
 real(dp) :: fac,poly,xx
 character(len=500) :: message
!arrays
 real(dp) :: tsec(2)
 real(dp),allocatable :: ek0(:),ek0_inv(:)

! *************************************************************************

 call timab(536,1,tsec)

!In this case, the Teter, Allan and Payne preconditioner is approximated:
!the factor xx=Ekin(G) and no more Ekin(G)/Ekin(iband)
 if (optpcon==0) then
   do ispinor=1,nspinor
     igs=(ispinor-1)*npw
     do ig=1+igs,npw+igs
       if (iterationnumber==1) then
         if(kinpw(ig-igs)<huge(0.0_dp)*1.d-11)then
           xx=kinpw(ig-igs)
!          teter polynomial ratio
           poly=27._dp+xx*(18._dp+xx*(12._dp+xx*8._dp))
           fac=poly/(poly+16._dp*xx**4)
           if (optekin==1) fac=two*fac
           pcon(ig-igs,1)=fac
           do iblocksize=1,blocksize 
             vect(ig,iblocksize)=(ghc(ig,iblocksize)-eval(iblocksize,iblocksize)*cg(ig,iblocksize))*pcon(ig-igs,1)
           end do 
         else
           pcon(ig-igs,1)=zero
           vect(ig,:)=dcmplx(0.0_dp,0.0_dp)
         end if
       else 
         do iblocksize=1,blocksize
           vect(ig,iblocksize)=(ghc(ig,iblocksize)-eval(iblocksize,iblocksize)*cg(ig,iblocksize))*pcon(ig-igs,1)
         end do 
       end if 
     end do
   end do

 else if (optpcon>0) then
!  Compute mean kinetic energy of all bands
   ABI_ALLOCATE(ek0,(blocksize))
   ABI_ALLOCATE(ek0_inv,(blocksize))
   if (iterationnumber==1.or.optpcon==1) then
     do iblocksize=1,blocksize
       ek0(iblocksize)=0.0_dp
       do ispinor=1,nspinor
         igs=(ispinor-1)*npw
         do ig=1+igs,npw+igs
           if(kinpw(ig-igs)<huge(0.0_dp)*1.d-11)then
             ek0(iblocksize)=ek0(iblocksize)+kinpw(ig-igs)*&
&             (real(cg(ig,iblocksize))**2+aimag(cg(ig,iblocksize))**2)
           end if
         end do
       end do
     end do

     old_paral_level= mpi_enreg%paral_level
     mpi_enreg%paral_level=3
     call xcomm_init(mpi_enreg,spaceComm,spaceComm_bandfft=mpi_enreg%commcart_3d)
     call xsum_mpi(ek0,spaceComm,ierr)
     mpi_enreg%paral_level= old_paral_level

     do iblocksize=1,blocksize
       if(ek0(iblocksize)<1.0d-10)then
         write(message, '(a,a,a,a,a,a)' )ch10,&
&         ' precon : warning -',ch10,&
&         '  the mean kinetic energy of a wavefunction vanishes.',ch10,&
&         '  it is reset to 0.1ha.'
         call wrtout(std_out,message,'PERS')
         ek0(iblocksize)=0.1_dp
       end if
     end do
     if (optekin==1) then
       ek0_inv(:)=2.0_dp/(3._dp*ek0(:))
     else
       ek0_inv(:)=1.0_dp/ek0(:)
     end if
   end if !iterationnumber==1.or.optpcon==1

!  Carry out preconditioning
   do iblocksize=1,blocksize
     do ispinor=1,nspinor
       igs=(ispinor-1)*npw
       do ig=1+igs,npw+igs
         if (iterationnumber==1.or.optpcon==1) then
           if(kinpw(ig-igs)<huge(0.0_dp)*1.d-11)then
             xx=kinpw(ig-igs)*ek0_inv(iblocksize)
!            teter polynomial ratio
             poly=27._dp+xx*(18._dp+xx*(12._dp+xx*8._dp))
             fac=poly/(poly+16._dp*xx**4)
             if (optekin==1) fac=two*fac
             pcon(ig-igs,iblocksize)=fac
             vect(ig,iblocksize)=(ghc(ig,iblocksize)-&
&             eval(iblocksize,iblocksize)*cg(ig,iblocksize))*pcon(ig-igs,iblocksize)
           else
             pcon(ig-igs,iblocksize)=zero
             vect(ig,iblocksize)=dcmplx(0.0_dp,0.0_dp)
           end if
         else 
           vect(ig,iblocksize)=(ghc(ig,iblocksize)-&
&           eval(iblocksize,iblocksize)*cg(ig,iblocksize))*pcon(ig-igs,iblocksize)
         end if 
       end do
     end do
   end do
   ABI_DEALLOCATE(ek0)
   ABI_DEALLOCATE(ek0_inv)
 end if !optpcon

 call timab(536,2,tsec)

end subroutine zprecon3
!!***
