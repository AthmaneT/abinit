!{\src2tex{textfont=tt}}
!!****f* ABINIT/newrho
!! NAME
!! newrho
!!
!! FUNCTION
!! Compute new trial density by mixing new and old values.
!! Call prcref to compute preconditioned residual density and forces,
!! Then, call one of the self-consistency drivers,
!! then update density.
!!
!! COPYRIGHT
!! Copyright (C) 2005-2012 ABINIT group (MT).
!! This file is distributed under the terms of the
!! GNU General Public License, see ~abinit/COPYING
!! or http://www.gnu.org/copyleft/gpl.txt .
!! For the initials of contributors, see ~abinit/doc/developers/contributors.txt .
!!
!! INPUTS
!!  atindx(natom)=index table for atoms (see scfcv.f)
!!  dielar(7)=input parameters for dielectric matrix:
!!                diecut,dielng,diemac,diemix,diegap,dielam,diemixmag.
!!  dielinv(2,npwdiel,nspden,npwdiel,nspden)=
!!                              inverse of the dielectric matrix in rec. space
!!  dielstrt=number of the step at which the dielectric preconditioning begins.
!!  dtset <type(dataset_type)>=all input variables in this dataset
!!   | iprcch= governs the preconditioning of the atomic charges
!!   | iprcel= governs the preconditioning of the density residual
!!   | iprcfc= governs the preconditioning of the forces
!!   | iscf=( <= 0 =>non-SCF), >0 => SCF)
!!   |  iscf =11 => determination of the largest eigenvalue of the SCF cycle
!!   |  iscf =12 => SCF cycle, simple mixing
!!   |  iscf =13 => SCF cycle, Anderson mixing
!!   |  iscf =14 => SCF cycle, Anderson mixing (order 2)
!!   |  iscf =15 => SCF cycle, CG based on the minimization of the energy
!!   |  iscf =17 => SCF cycle, Pulay mixing
!!   | isecur=level of security of the computation
!!   | mffmem=governs the number of FFT arrays which are fit in core memory
!!   |          it is either 1, in which case the array f_fftgr is used,
!!   |          or 0, in which case the array f_fftgr_disk is used
!!   | natom=number of atoms
!!   | nspden=number of spin-density components
!!   | pawoptmix=-PAW- 1 if the computed residuals include the PAW (rhoij) part
!!   | prtvol=control print volume and debugging
!!  etotal=the total energy obtained from the input density
!!  fnametmp_fft=name of _FFT file
!!  fcart(3,natom)=cartesian forces (hartree/bohr)
!!  ffttomix(nfft*(1-nfftmix/nfft))=Index of the points of the FFT (fine) grid on the grid used for mixing (coarse)
!!  gmet(3,3)=metrix tensor in G space in Bohr**-2.
!!  grhf(3,natom)=Hellman-Feynman derivatives of the total energy
!!  gsqcut=cutoff on (k+G)^2 (bohr^-2)
!!  initialized= if 0, the initialization of the gstate run is not yet finished
!!  ispmix=1 if mixing is done in real space, 2 if mixing is done in reciprocal space
!!  istep= number of the step in the SCF cycle
!!  kg_diel(3,npwdiel)=reduced planewave coordinates for the dielectric matrix.
!!  kxc(nfft,nkxc)=exchange-correlation kernel, needed only for electronic
!!     dielectric matrix
!!  mgfft=maximum size of 1D FFTs
!!  mixtofft(nfftmix*(1-nfftmix/nfft))=Index of the points of the FFT grid used for mixing (coarse) on the FFT (fine) grid
!!  moved_atm_inside= if 1, then the preconditioned forces
!!    as well as the preconditioned density residual must be computed;
!!    otherwise, compute only the preconditioned density residual.
!!  mpi_enreg=informations about MPI parallelization
!!  nattyp(ntypat)=number of atoms of each type in cell.
!!  nfft=(effective) number of FFT grid points (for this processor)
!!  nfftmix=dimension of FFT grid used to mix the densities (used in PAW only)
!!  ngfft(18)=contain all needed information about 3D FFT, see ~abinit/doc/input_variables/vargs.htm#ngfft
!!  ngfftmix(18)=contain all needed information about 3D FFT, for the grid corresponding to nfftmix
!!  nkxc=second dimension of the array kxc, see rhohxc.f for a description
!!  npawmix=-PAW only- number of spherical part elements to be mixed
!!  npwdiel=number of planewaves for dielectric matrix
!!  nresid(nfft,nspden)=array for the residual of the density
!!  ntypat=number of types of atoms in cell.
!!  n1xccc=dimension of xccc1d ; 0 if no XC core correction is used
!!  pawrhoij(natom*usepaw) <type(pawrhoij_type)>= paw rhoij occupancies and related data
!!                                         Use here rhoij residuals (and gradients)
!!  pawtab(ntypat*usepaw) <type(pawtab_type)>=paw tabulated starting data
!!  psps <type(pseudopotential_type)>=variables related to pseudopotentials
!!  rprimd(3,3)=dimensional primitive translations in real space (bohr)
!!  susmat(2,npwdiel,nspden,npwdiel,nspden)=
!!   the susceptibility (or density-density response) matrix in reciprocal space
!!  usepaw= 0 for non paw calculation; =1 for paw calculation
!!  vtrial(nfft,nspden)=the trial potential that gave vresid.
!!  xred(3,natom)=reduced dimensionless atomic coordinates
!!
!! OUTPUT
!!  dbl_nnsclo=1 if nnsclo has to be doubled to secure the convergence.
!!
!! SIDE EFFECTS
!!  dtn_pc(3,natom)=preconditioned change of atomic position,
!!                                          in reduced coordinates
!!  rhor(nfft,nspden)= at input, it is the "out" trial density that gave nresid=(rho_out-rho_in)
!!                     at output, it is an updated "mixed" trial density
!!  rhog(2,nfft)= Fourier transform of the new trial density
!!  ===== if iprcch==3 .and. moved_atm_inside==1 =====
!!    ph1d(2,3*(2*mgfft+1)*natom)=1-dim structure factor phases
!!  ==== if usepaw==1
!!    pawrhoij(natom)%nrhoijsel=number of non-zero values of rhoij
!!    pawrhoij(iatom)%rhoijp(cplex*lmn2_size,nspden)= new (mixed) value of rhoij quantities in PACKED STORAGE
!!    pawrhoij(natom)%rhoijselect(lmn2_size)=select the non-zero values of rhoij
!!
!! NOTES
!!  In case of PAW calculations:
!!    Computations are done either on the fine FFT grid or the coarse grid (depending on dtset%pawmixdg)
!!    All variables (nfft,ngfft,mgfft) refer to the fine FFT grid.
!!    All arrays (densities/potentials...) are computed on this fine FFT grid.
!!  ! Developpers have to be careful when introducing others arrays:
!!      they have to be stored on the fine FFT grid (except f_fftgr).
!!  In case of norm-conserving calculations the FFT grid is the usual FFT grid.
!!
!! PARENTS
!!      scfcv
!!
!! CHILDREN
!!      ab6_mixing_copy_current_step,ab6_mixing_eval,ab6_mixing_eval_allocate
!!      ab6_mixing_eval_deallocate,ab6_mixing_use_moving_atoms,fourdp,leave_new
!!      metric,prcref,timab,wrtout,xcomm_init
!!
!! SOURCE

#if defined HAVE_CONFIG_H
#include "config.h"
#endif

#include "abi_common.h"

subroutine newrho(atindx,dbl_nnsclo,dielar,dielinv,dielstrt,dtn_pc,dtset,etotal,fcart,ffttomix,&
&  gmet,grhf,gsqcut,initialized,ispmix,istep,kg_diel,kxc,mgfft,mix,mixtofft,&
&  moved_atm_inside,mpi_enreg,nattyp,nfft,nfftmix,ngfft,ngfftmix,nkxc,npawmix,npwdiel,&
&  nresid,ntypat,n1xccc,pawrhoij,pawtab,&
&  ph1d,psps,rhog,rhor,rprimd,susmat,usepaw,vtrial,wvl,xred)

 use m_profiling

 use defs_basis
 use defs_datatypes
 use defs_abitypes
 use m_ab6_mixing
 use defs_wvltypes

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'newrho'
 use interfaces_14_hidewrite
 use interfaces_16_hideleave
 use interfaces_18_timing
 use interfaces_42_geometry
 use interfaces_51_manage_mpi
 use interfaces_53_ffts
 use interfaces_68_rsprc, except_this_one => newrho
!End of the abilint section

 implicit none

!Arguments-------------------------------
!scalars
 integer,intent(in) :: dielstrt,initialized,ispmix,istep,mgfft
 integer,intent(in) :: moved_atm_inside,n1xccc,nfft,nfftmix
 integer,intent(in) :: nkxc,npawmix,npwdiel,ntypat,usepaw
 integer,intent(inout) :: dbl_nnsclo
 real(dp),intent(in) :: etotal,gsqcut
 type(MPI_type),intent(inout) :: mpi_enreg
 type(ab6_mixing_object), intent(inout) :: mix
 type(dataset_type),intent(in) :: dtset
 type(pseudopotential_type),intent(in) :: psps
 type(wvl_internal_type), intent(in) :: wvl
!arrays
 integer,intent(in) :: atindx(dtset%natom),ffttomix(nfft*(1-nfftmix/nfft))
 integer,intent(in) :: kg_diel(3,npwdiel),mixtofft(nfftmix*(1-nfftmix/nfft))
 integer,intent(in) :: nattyp(ntypat),ngfft(18),ngfftmix(18)
 real(dp),intent(in) :: dielar(7),fcart(3,dtset%natom),grhf(3,dtset%natom)
 real(dp),intent(in) :: rprimd(3,3)
 real(dp),intent(in) :: susmat(2,npwdiel,dtset%nspden,npwdiel,dtset%nspden)
 real(dp),intent(in), target :: vtrial(nfft,dtset%nspden)
 real(dp),intent(inout) :: dielinv(2,npwdiel,dtset%nspden,npwdiel,dtset%nspden)
 real(dp),intent(inout), target :: dtn_pc(3,dtset%natom)
 real(dp), intent(inout) :: gmet(3,3)
 real(dp),intent(inout) :: kxc(nfft,nkxc),nresid(nfft,dtset%nspden)
 real(dp),intent(inout) :: ph1d(2,3*(2*mgfft+1)*dtset%natom)
 real(dp),intent(inout) :: rhor(nfft,dtset%nspden)
 real(dp), intent(inout), target :: xred(3,dtset%natom)
 real(dp),intent(out) :: rhog(2,nfft)
 type(pawrhoij_type),intent(inout) :: pawrhoij(dtset%natom*psps%usepaw)
 type(pawtab_type),intent(in) :: pawtab(ntypat*psps%usepaw)

!Local variables-------------------------------
!scalars
 integer :: cplex,dplex,i_vresid1,i_vrespc1,iatom,ifft,indx,irhoij,ispden,jfft
 integer :: jrhoij,klmn,kmix,nfftot,nselect,mpi_comm,old_paral_level
 integer :: errid,tim_fourdp
 logical :: mpi_summarize, reset
 real(dp) :: fact,ucvol
 character(len=500) :: message
!arrays
 real(dp) :: gprimd(3,3),rmet(3,3),ro(2),tsec(2),vhartr_dum(1),vpsp_dum(1)
 real(dp) :: vxc_dum(1,1)
 real(dp),allocatable :: magng(:,:,:)
 real(dp),allocatable :: nresid0(:,:),nrespc(:,:),nreswk(:,:,:)
 real(dp),allocatable :: rhoijrespc(:),rhoijtmp(:,:)
 real(dp), pointer :: rhomag(:,:), npaw(:)

! *************************************************************************

!DEBUG
!write(std_out,*)' newrho : enter '
!stop
!ENDDEBUG

 call timab(94,1,tsec)
 tim_fourdp=9

!Compatibility tests
 if(nfftmix>nfft) then
   write(message, '(a,a,a,a)' )ch10,&
&   ' newrho : BUG -',ch10,&
&   '  nfftmix>nfft not allowed !'
   call wrtout(std_out,message,'COLL')
   call leave_new('PERS')
 end if
 if(ispmix/=2.and.nfftmix/=nfft) then
   write(message, '(a,a,a,a)' )ch10,&
&   ' newrho : BUG -',ch10,&
&   '  nfftmix/=nfft allowed only when ispmix=2 !'
   call wrtout(std_out,message,'COLL')
   call leave_new('PERS')
 end if

 if (usepaw==1) then
   cplex=pawrhoij(1)%cplex;dplex=cplex-1
 else
   cplex = 0;dplex = 0
 end if

!Compute different geometric tensor, as well as ucvol, from rprimd
 call metric(gmet,gprimd,-1,rmet,rprimd,ucvol)

!Select components of density to be mixed
 ABI_ALLOCATE(rhomag,(ispmix*nfftmix,dtset%nspden))
 ABI_ALLOCATE(nresid0,(ispmix*nfftmix,dtset%nspden))
 if (ispmix==1.and.nfft==nfftmix) then
   rhomag(:,1:dtset%nspden)=rhor(:,1:dtset%nspden)
   nresid0(:,1:dtset%nspden)=nresid(:,1:dtset%nspden)
 else if (nfft==nfftmix) then
   do ispden=1,dtset%nspden
     call fourdp(1,nresid0(:,ispden),nresid(:,ispden),-1,mpi_enreg,nfft,ngfft,dtset%paral_kgb,tim_fourdp)
   end do
   rhomag(:,1)=reshape(rhog,(/2*nfft/))
   if (dtset%nspden>1) then
     do ispden=2,dtset%nspden
       call fourdp(1,rhomag(:,ispden),rhor(:,ispden),-1,mpi_enreg,nfft,ngfft,dtset%paral_kgb,tim_fourdp)
     end do
   end if
 else
   fact=dielar(4)-1._dp
   ABI_ALLOCATE(nreswk,(2,nfft,dtset%nspden))
   do ispden=1,dtset%nspden
     call fourdp(1,nreswk(:,:,ispden),nresid(:,ispden),-1,mpi_enreg,nfft,ngfft,dtset%paral_kgb,tim_fourdp)
   end do
   do ifft=1,nfft
     if (ffttomix(ifft)>0) then
       jfft=2*ffttomix(ifft)
       rhomag (jfft-1:jfft,1)=rhog(1:2,ifft)
       nresid0(jfft-1:jfft,1)=nreswk(1:2,ifft,1)
     else
       rhog(:,ifft)=rhog(:,ifft)+fact*nreswk(:,ifft,1)
     end if
   end do
   if (dtset%nspden>1) then
     ABI_ALLOCATE(magng,(2,nfft,dtset%nspden-1))
     do ispden=2,dtset%nspden
       call fourdp(1,magng(:,:,ispden-1),rhor(:,ispden),-1,mpi_enreg,nfft,ngfft,dtset%paral_kgb,tim_fourdp)
       do ifft=1,nfft
         if (ffttomix(ifft)>0) then
           jfft=2*ffttomix(ifft)
           rhomag (jfft-1:jfft,ispden)=magng (1:2,ifft,ispden-1)
           nresid0(jfft-1:jfft,ispden)=nreswk(1:2,ifft,ispden)
         else
           magng(:,ifft,ispden-1)=magng(:,ifft,ispden-1)+fact*nreswk(:,ifft,ispden)
           if (dtset%nspden==2) magng(:,ifft,1)=two*magng(:,ifft,1)-rhog(:,ifft)
         end if
       end do
     end do
   end if
   ABI_DEALLOCATE(nreswk)
 end if

!Retrieve "input" density from "output" density and density residual
 rhomag(:,1:dtset%nspden)=rhomag(:,1:dtset%nspden)-nresid0(:,1:dtset%nspden)

!If nspden==2, separate density and magnetization
 if (dtset%nspden==2) then
   rhomag (:,2)=two*rhomag (:,2)-rhomag (:,1)
   nresid0(:,2)=two*nresid0(:,2)-nresid0(:,1)
 end if
 if (usepaw==1) then
   if (pawrhoij(1)%nspden==2) then
     do iatom=1,dtset%natom
       jrhoij=1
       do irhoij=1,pawrhoij(iatom)%nrhoijsel
         ro(1:1+dplex)=pawrhoij(iatom)%rhoijp(jrhoij:jrhoij+dplex,1)
         pawrhoij(iatom)%rhoijp(jrhoij:jrhoij+dplex,1)=ro(1:1+dplex)+pawrhoij(iatom)%rhoijp(jrhoij:jrhoij+dplex,2)
         pawrhoij(iatom)%rhoijp(jrhoij:jrhoij+dplex,2)=ro(1:1+dplex)-pawrhoij(iatom)%rhoijp(jrhoij:jrhoij+dplex,2)
         jrhoij=jrhoij+cplex
       end do
       do kmix=1,pawrhoij(iatom)%lmnmix_sz
         klmn=cplex*pawrhoij(iatom)%kpawmix(kmix)-dplex
         ro(1:1+dplex)=pawrhoij(iatom)%rhoijres(klmn:klmn+dplex,1)
         pawrhoij(iatom)%rhoijres(klmn:klmn+dplex,1)=ro(1:1+dplex)+pawrhoij(iatom)%rhoijres(klmn:klmn+dplex,2)
         pawrhoij(iatom)%rhoijres(klmn:klmn+dplex,2)=ro(1:1+dplex)-pawrhoij(iatom)%rhoijres(klmn:klmn+dplex,2)
       end do
     end do
   end if
 end if

!Choice of preconditioner governed by iprcel, iprcch and iprcfc
 ABI_ALLOCATE(nrespc,(ispmix*nfftmix,dtset%nspden))
 ABI_ALLOCATE(npaw,(npawmix*usepaw))
 if (usepaw==1)  then
   ABI_ALLOCATE(rhoijrespc,(npawmix))
 end if
 call prcref(atindx,dielar,dielinv,&
& dielstrt,dtn_pc,dtset,etotal,fcart,ffttomix,gmet,gsqcut,&
& istep,kg_diel,kxc,&
& mgfft,moved_atm_inside,mpi_enreg,&
& nattyp,nfft,nfftmix,ngfft,ngfftmix,nkxc,npawmix,npwdiel,ntypat,n1xccc,&
& ispmix,1,pawrhoij,pawtab,ph1d,psps,rhog,rhoijrespc,rhor,rprimd,&
& susmat,vhartr_dum,vpsp_dum,nresid0,nrespc,vxc_dum,wvl,xred)

!------Compute new trial density and eventual new atomic positions

 i_vresid1=mix%i_vresid(1)
 i_vrespc1=mix%i_vrespc(1)

!Initialise working arrays for the mixing object.
 if (moved_atm_inside == 1) then
   call ab6_mixing_use_moving_atoms(mix, dtset%natom, xred, dtn_pc)
 end if
 call ab6_mixing_eval_allocate(mix, istep)
!Copy current step arrays.
 if (moved_atm_inside == 1) then
   call ab6_mixing_copy_current_step(mix, nresid0, errid, message, &
&   arr_respc = nrespc, arr_atm = grhf)
 else
   call ab6_mixing_copy_current_step(mix, nresid0, errid, message, &
&   arr_respc = nrespc)
 end if
 if (errid /= AB6_NO_ERROR) then
   call wrtout(std_out, message, 'COLL')
   call leave_new('COLL')
 end if
 ABI_DEALLOCATE(nresid0)
 ABI_DEALLOCATE(nrespc)

!PAW: either use the array f_paw or the array f_paw_disk
 if (usepaw==1) then
   indx=-dplex
   do iatom=1,dtset%natom
     do ispden=1,pawrhoij(iatom)%nspden
       ABI_ALLOCATE(rhoijtmp,(cplex*pawrhoij(iatom)%lmn2_size,1))
       rhoijtmp=zero
       jrhoij=1
       do irhoij=1,pawrhoij(iatom)%nrhoijsel
         klmn=cplex*pawrhoij(iatom)%rhoijselect(irhoij)-dplex
         rhoijtmp(klmn:klmn+dplex,1)=pawrhoij(iatom)%rhoijp(jrhoij:jrhoij+dplex,ispden)
         jrhoij=jrhoij+cplex
       end do
       do kmix=1,pawrhoij(iatom)%lmnmix_sz
         indx=indx+cplex;klmn=cplex*pawrhoij(iatom)%kpawmix(kmix)-dplex
         npaw(indx:indx+dplex)=rhoijtmp(klmn:klmn+dplex,1)-pawrhoij(iatom)%rhoijres(klmn:klmn+dplex,ispden)
         mix%f_paw(indx:indx+dplex,i_vresid1)=pawrhoij(iatom)%rhoijres(klmn:klmn+dplex,ispden)
         mix%f_paw(indx:indx+dplex,i_vrespc1)=rhoijrespc(indx:indx+dplex)
       end do
       ABI_DEALLOCATE(rhoijtmp)
     end do
   end do
 end if

!------Prediction of the components of the density

!Init mpi_comm
 if(mpi_enreg%paral_compil_fft==1)then
   old_paral_level=mpi_enreg%paral_level
   mpi_enreg%paral_level=3
   call xcomm_init(mpi_enreg,mpi_comm,spaceComm_bandfft=mpi_enreg%comm_fft)
   mpi_enreg%paral_level=old_paral_level
   mpi_summarize=.true.
 else
   mpi_comm=0
   mpi_summarize=.false.
 end if

 reset = .false.
 if (initialized == 0) reset = .true.
 call ab6_mixing_eval(mix, rhomag, istep, nfftot, ucvol, &
& mpi_comm, mpi_summarize, errid, message, &
& reset = reset, isecur = dtset%isecur, &
& pawopt = dtset%pawoptmix, pawarr = npaw, &
& etotal = etotal, potden = vtrial)
 if (errid == AB6_ERROR_MIXING_INC_NNSLOOP) then
   dbl_nnsclo = 1
 else if (errid /= AB6_NO_ERROR) then
   call wrtout(std_out, message, 'COLL')
   call leave_new('COLL')
 end if

!PAW: apply a simple mixing to rhoij (this is temporary)
 if(dtset%iscf==15 .or. dtset%iscf==16)then
   if (usepaw==1) then
     indx=-dplex
     do iatom=1,dtset%natom
       ABI_ALLOCATE(rhoijtmp,(cplex*pawrhoij(iatom)%lmn2_size,pawrhoij(iatom)%nspden))
       rhoijtmp=zero
       if (pawrhoij(iatom)%lmnmix_sz<pawrhoij(iatom)%lmn2_size) then
         do ispden=1,pawrhoij(iatom)%nspden
           do kmix=1,pawrhoij(iatom)%lmnmix_sz
             indx=indx+cplex;klmn=cplex*pawrhoij(iatom)%kpawmix(kmix)-dplex
             rhoijtmp(klmn:klmn+dplex,ispden)=rhoijrespc(indx:indx+dplex) &
&             -pawrhoij(iatom)%rhoijres(klmn:klmn+dplex,ispden)
           end do
         end do
       end if
       if (pawrhoij(iatom)%nspden/=2) then
         do ispden=1,pawrhoij(iatom)%nspden
           jrhoij=1
           do irhoij=1,pawrhoij(iatom)%nrhoijsel
             klmn=cplex*pawrhoij(iatom)%rhoijselect(irhoij)-dplex
             rhoijtmp(klmn:klmn+dplex,ispden)=rhoijtmp(klmn:klmn+dplex,ispden) &
&             +pawrhoij(iatom)%rhoijp(jrhoij:jrhoij+dplex,ispden)
             jrhoij=jrhoij+cplex
           end do
         end do
       else
         jrhoij=1
         do irhoij=1,pawrhoij(iatom)%nrhoijsel
           klmn=cplex*pawrhoij(iatom)%rhoijselect(irhoij)-dplex
           ro(1:1+dplex)=rhoijtmp(klmn:klmn+dplex,1)
           rhoijtmp(klmn:klmn+dplex,1)=half*(ro(1:1+dplex)+rhoijtmp(klmn:klmn+dplex,2)) &
&           +pawrhoij(iatom)%rhoijp(jrhoij:jrhoij+dplex,1)
           rhoijtmp(klmn:klmn+dplex,2)=half*(ro(1:1+dplex)-rhoijtmp(klmn:klmn+dplex,2)) &
&           +pawrhoij(iatom)%rhoijp(jrhoij:jrhoij+dplex,2)
           jrhoij=jrhoij+cplex
         end do
       end if
       nselect=0
       do klmn=1,pawrhoij(iatom)%lmn2_size
         if (any(abs(rhoijtmp(cplex*klmn-dplex:cplex*klmn,:))>tol10)) then
           nselect=nselect+1
           pawrhoij(iatom)%rhoijselect(nselect)=klmn
           do ispden=1,pawrhoij(iatom)%nspden
             pawrhoij(iatom)%rhoijp(cplex*nselect-dplex:cplex*nselect,ispden)=&
&             rhoijtmp(cplex*klmn-dplex:cplex*klmn,ispden)
           end do
         end if
       end do
       pawrhoij(iatom)%nrhoijsel=nselect
       ABI_DEALLOCATE(rhoijtmp)
     end do
   end if
 end if

 if (usepaw==1)  then
   ABI_DEALLOCATE(rhoijrespc)
 end if

!PAW: restore rhoij from compact storage
 if (usepaw==1.and.dtset%iscf/=15.and.dtset%iscf/=16) then
   indx=-dplex
   do iatom=1,dtset%natom
     ABI_ALLOCATE(rhoijtmp,(cplex*pawrhoij(iatom)%lmn2_size,pawrhoij(iatom)%nspden))
     rhoijtmp=zero
     if (pawrhoij(iatom)%lmnmix_sz<pawrhoij(iatom)%lmn2_size) then
       do ispden=1,pawrhoij(iatom)%nspden
         jrhoij=1
         do irhoij=1,pawrhoij(iatom)%nrhoijsel
           klmn=cplex*pawrhoij(iatom)%rhoijselect(irhoij)-dplex
           rhoijtmp(klmn:klmn+dplex,ispden)=pawrhoij(iatom)%rhoijp(jrhoij:jrhoij+dplex,ispden)
           jrhoij=jrhoij+cplex
         end do
       end do
     end if
     do ispden=1,pawrhoij(iatom)%nspden
       do kmix=1,pawrhoij(iatom)%lmnmix_sz
         indx=indx+cplex;klmn=cplex*pawrhoij(iatom)%kpawmix(kmix)-dplex
         rhoijtmp(klmn:klmn+dplex,ispden)=npaw(indx:indx+dplex)
       end do
     end do
     if (pawrhoij(iatom)%nspden==2) then
       jrhoij=1
       do irhoij=1,pawrhoij(iatom)%nrhoijsel
         klmn=cplex*pawrhoij(iatom)%rhoijselect(irhoij)-dplex
         ro(1:1+dplex)=rhoijtmp(klmn:klmn+dplex,1)
         rhoijtmp(klmn:klmn+dplex,1)=half*(ro(1:1+dplex)+rhoijtmp(klmn:klmn+dplex,2))
         rhoijtmp(klmn:klmn+dplex,2)=half*(ro(1:1+dplex)-rhoijtmp(klmn:klmn+dplex,2))
         jrhoij=jrhoij+cplex
       end do
     end if
     nselect=0
     if (cplex==1) then
       do klmn=1,pawrhoij(iatom)%lmn2_size
         if (any(abs(rhoijtmp(klmn,:))>tol10)) then
           nselect=nselect+1
           pawrhoij(iatom)%rhoijselect(nselect)=klmn
           do ispden=1,pawrhoij(iatom)%nspden
             pawrhoij(iatom)%rhoijp(nselect,ispden)=rhoijtmp(klmn,ispden)
           end do
         end if
       end do
     else
       do klmn=1,pawrhoij(iatom)%lmn2_size
         if (any(abs(rhoijtmp(2*klmn-1:2*klmn,:))>tol10)) then
           nselect=nselect+1
           pawrhoij(iatom)%rhoijselect(nselect)=klmn
           do ispden=1,pawrhoij(iatom)%nspden
             pawrhoij(iatom)%rhoijp(2*nselect-1:2*nselect,ispden)=rhoijtmp(2*klmn-1:2*klmn,ispden)
           end do
         end if
       end do
     end if
     pawrhoij(iatom)%nrhoijsel=nselect
     ABI_DEALLOCATE(rhoijtmp)
   end do
 end if
 ABI_DEALLOCATE(npaw)

!Eventually write the data on disk and deallocate f_fftgr_disk
 call ab6_mixing_eval_deallocate(mix)

!Fourier transform the density
 if (ispmix==1.and.nfft==nfftmix) then
   rhor(:,1:dtset%nspden)=rhomag(:,1:dtset%nspden)
   call fourdp(1,rhog,rhor(:,1),-1,mpi_enreg,nfft,ngfft,dtset%paral_kgb,tim_fourdp)
 else if (nfft==nfftmix) then
   do ispden=1,dtset%nspden
     call fourdp(1,rhomag(:,ispden),rhor(:,ispden),+1,mpi_enreg,nfft,ngfft,dtset%paral_kgb,tim_fourdp)
   end do
   rhog(:,:)=reshape(rhomag(:,1),(/2,nfft/))
 else
   do ifft=1,nfftmix
     jfft=mixtofft(ifft)
     rhog(1:2,jfft)=rhomag(2*ifft-1:2*ifft,1)
   end do
   call fourdp(1,rhog,rhor(:,1),+1,mpi_enreg,nfft,ngfft,dtset%paral_kgb,tim_fourdp)
   if (dtset%nspden>1) then
     do ispden=2,dtset%nspden
       do ifft=1,nfftmix
         jfft=mixtofft(ifft)
         magng(1:2,jfft,ispden-1)=rhomag(2*ifft-1:2*ifft,ispden)
       end do
       call fourdp(1,magng(:,:,ispden-1),rhor(:,ispden),+1,mpi_enreg,nfft,ngfft,dtset%paral_kgb,tim_fourdp)
     end do
     ABI_DEALLOCATE(magng)
   end if
 end if
 ABI_DEALLOCATE(rhomag)

!Set back rho in (up+dn,up) form if nspden=2
 if (dtset%nspden==2) rhor(:,2)=half*(rhor(:,1)+rhor(:,2))

 call timab(94,2,tsec)

!DEBUG
!write(std_out,*)' newrho : exit '
!stop
!ENDDEBUG

end subroutine newrho
!!***
