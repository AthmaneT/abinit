!{\src2tex{textfont=tt}}
!!****f* ABINIT/pred_srkna14
!! NAME
!! pred_srkna14
!!
!! FUNCTION
!! Ionmov predictors (14) Srkna14 molecular dynamics
!!
!! IONMOV 14:
!! Simple molecular dynamics with a symplectic algorithm proposed
!! by S.Blanes and P.C.Moans [called SRKNa14 in Practical symplectic partitioned
!! Runge--Kutta and Runge--Kutta--Nystrom methods, Journal of Computational
!! and Applied Mathematics archive, volume 142,  issue 2  (May 2002), pages 313 - 330]
!! of the kind first published by H. Yoshida [Construction of higher order symplectic
!! integrators, Physics Letters A, volume 150, number 5 to 7, pages 262 - 268].
!! This algorithm requires at least 14 evaluation of the forces (actually 15 are done
!! within Abinit) per time step. At this cost it usually gives much better
!! energy conservation than the verlet algorithm (ionmov 6) for a 30 times bigger
!! value of <a href="varrlx.html#dtion">dtion</a>. Notice that the potential
!! energy of the initial atomic configuration is never evaluated using this
!! algorithm.
!!
!! COPYRIGHT
!! Copyright (C) 1998-2012 ABINIT group (DCA, XG, GMR, JCC, SE)
!! This file is distributed under the terms of the
!! GNU General Public License, see ~abinit/COPYING
!! or http://www.gnu.org/copyleft/gpl.txt .
!! For the initials of contributors,
!! see ~abinit/doc/developers/contributors.txt .
!!
!! INPUTS
!! ab_mover <type(ab_movetype)> : Datatype with all the information
!!                                needed by the preditor
!! itime  : Index of the present iteration
!! ntime  : Maximal number of iterations
!! icycle : Index of the present cycle
!! ncycle : Maximal number of cycles
!! zDEBUG : if true print some debugging information
!!
!! OUTPUT
!!
!! SIDE EFFECTS
!! hist <type(ab_movehistory)> : History of positions,forces
!!                               acell, rprimd, stresses
!!
!! NOTES
!!
!! PARENTS
!!      mover
!!
!! CHILDREN
!!      hist2var,metric,var2hist,xredxcart
!!
!! SOURCE

#if defined HAVE_CONFIG_H
#include "config.h"
#endif

#include "abi_common.h"


subroutine pred_srkna14(ab_mover,hist,icycle,ncycle,zDEBUG,iexit)

 use m_profiling

! define dp,sixth,third,etc...
 use defs_basis
! type(ab_movetype), type(ab_movehistory)
 use defs_mover

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'pred_srkna14'
 use interfaces_42_geometry
 use interfaces_45_geomoptim, except_this_one => pred_srkna14
!End of the abilint section

 implicit none

!Arguments ------------------------------------
!scalars
 type(ab_movetype),intent(in)       :: ab_mover
 type(ab_movehistory),intent(inout) :: hist
 integer,intent(inout) :: icycle
 integer,intent(in)    :: ncycle
 integer,intent(in)    :: iexit
 logical,intent(in)    :: zDEBUG

!Local variables-------------------------------
!scalars
 integer  :: ii,jj,kk
 real(dp) :: ucvol,ucvol0,ucvol_next,amass_tot
 real(dp),parameter :: v2tol=tol8
 real(dp) :: etotal
 real(dp) :: favg
 logical  :: jump_end_of_cycle=.FALSE.
! character(len=5000) :: message
!arrays
 real(dp),save :: aa(15),bb(15)
 real(dp) :: acell(3),acell0(3),acell_next(3)
 real(dp) :: rprimd(3,3),rprimd0(3,3),rprim(3,3),rprimd_next(3,3),rprim_next(3,3)
 real(dp) :: gprimd(3,3)
 real(dp) :: gmet(3,3)
 real(dp) :: rmet(3,3)
 real(dp) :: fcart(3,ab_mover%natom),fcart_m(3,ab_mover%natom)
 real(dp) :: fred(3,ab_mover%natom),fred_corrected(3,ab_mover%natom)
 real(dp) :: xcart(3,ab_mover%natom)
 real(dp) :: xred(3,ab_mover%natom)
 real(dp) :: vel(3,ab_mover%natom)
 real(dp) :: strten(6)

!***************************************************************************
!Beginning of executable session
!***************************************************************************

 if(iexit/=0)then
   return
 end if

 jump_end_of_cycle=.FALSE.
 fcart_m(:,:)=zero

!write(std_out,*) 'srkna14 03',jump_end_of_cycle
!##########################################################
!### 03. Obtain the present values from the history

 call hist2var(acell,hist,ab_mover%natom,rprim,rprimd,xcart,xred,zDEBUG)

 fcart(:,:) =hist%histXF(:,:,3,hist%ihist)
 fred(:,:)  =hist%histXF(:,:,4,hist%ihist)
 vel(:,:)   =hist%histV(:,:,hist%ihist)
 strten(:)  =hist%histS(:,hist%ihist)
 etotal     =hist%histE(hist%ihist)

 if(zDEBUG)then
   write (std_out,*) 'fcart:'
   do kk=1,ab_mover%natom
     write (std_out,*) fcart(:,kk)
   end do
   write (std_out,*) 'fred:'
   do kk=1,ab_mover%natom
     write (std_out,*) fred(:,kk)
   end do
   write (std_out,*) 'vel:'
   do kk=1,ab_mover%natom
     write (std_out,*) vel(:,kk)
   end do
   write (std_out,*) 'strten:'
   write (std_out,*) strten(1:3),ch10,strten(4:6)
   write (std_out,*) 'etotal:'
   write (std_out,*) etotal
 end if

 call metric(gmet,gprimd,-1,rmet,rprimd,ucvol)
 write(std_out,*) 'RMET'
 do ii=1,3
   write(std_out,*) rmet(ii,:)
 end do

!Save initial values
 acell0(:)=acell(:)
 rprimd0(:,:)=rprimd(:,:)
 ucvol0=ucvol

!Get rid of mean force on whole unit cell, but only if no
!generalized constraints are in effect
 if(ab_mover%nconeq==0)then
   amass_tot=sum(ab_mover%amass(:)) 
   do ii=1,3
     favg=sum(fred(ii,:))/dble(ab_mover%natom)
!    Note that the masses are used, in order to weight the repartition of the average force. 
!    This procedure is adequate for dynamics, as pointed out by Hichem Dammak (2012 Jan 6)..
     fred_corrected(ii,:)=fred(ii,:)-favg*ab_mover%amass(:)/amass_tot
     if(ab_mover%jellslab/=0.and.ii==3)&
&     fred_corrected(ii,:)=fred(ii,:)
   end do
 else
   fred_corrected(:,:)=fred(:,:)
 end if

!write(std_out,*) 'srkna14 04',jump_end_of_cycle
!##########################################################
!### 04. Compute the next values (Only for the first cycle)

 if (icycle==1) then

   if(zDEBUG) then
     write(std_out,*) 'Entering only for first cycle'
   end if

   aa(1) =  0.0378593198406116_dp;
   aa(2) =  0.102635633102435_dp;
   aa(3) = -0.0258678882665587_dp;
   aa(4) =  0.314241403071447_dp;
   aa(5) = -0.130144459517415_dp;
   aa(6) =  0.106417700369543_dp;
   aa(7) = -0.00879424312851058_dp;
   aa(8) =  1._dp -&
&   2._dp*(aa(1)+aa(2)+aa(3)+aa(4)+aa(5)+aa(6)+aa(7));
   aa(9) =  aa(7);
   aa(10)=  aa(6);
   aa(11)=  aa(5);
   aa(12)=  aa(4);
   aa(13)=  aa(3);
   aa(14)=  aa(2);
   aa(15)=  aa(1);

   bb(1) =  0.0_dp
   bb(2) =  0.09171915262446165_dp;
   bb(3) =  0.183983170005006_dp;
   bb(4) = -0.05653436583288827_dp;
   bb(5) =  0.004914688774712854_dp;
   bb(6) =  0.143761127168358_dp;
   bb(7) =  0.328567693746804_dp;
   bb(8) =  0.5_dp - (bb(1)+bb(2)+bb(3)+bb(4)+bb(5)+bb(6)+bb(7));
   bb(9) =  0.5_dp - (bb(1)+bb(2)+bb(3)+bb(4)+bb(5)+bb(6)+bb(7));
   bb(10)=  bb(7);
   bb(11)=  bb(6);
   bb(12)=  bb(5);
   bb(13)=  bb(4);
   bb(14)=  bb(3);
   bb(15)=  bb(2);

   acell_next(:)=acell(:)
   ucvol_next=ucvol
   rprim_next(:,:)=rprim(:,:)
   rprimd_next(:,:)=rprimd(:,:)

!  step 1 of 15

!  Convert input xred (reduced coordinates) to xcart (cartesian)
   call xredxcart(ab_mover%natom,1,rprimd,xcart,xred)

   vel(:,:) = vel(:,:) + bb(1) * ab_mover%dtion * fcart_m(:,:)

   do ii=1,3
     do jj=1,ab_mover%natom
       write(std_out,*) xcart(ii,jj), ab_mover%dtion, aa(1), vel(ii,jj)
       xcart(ii,jj) = xcart(ii,jj) + ab_mover%dtion * aa(1) * vel(ii,jj)
       write(std_out,*) xcart(ii,jj)
     end do
   end do

!  xcart(:,:) = xcart(:,:) + ab_mover%dtion * aa(1) * vel(:,:);

!  Convert back to xred (reduced coordinates)
   call xredxcart(ab_mover%natom,-1,rprimd,xcart,xred)

 end if ! if (icycle==1)

!write(std_out,*) 'srkna14 05',jump_end_of_cycle
!##########################################################
!### 05. Compute the next values (Only for extra cycles)

 if (icycle>1) then

   do ii=1,ab_mover%natom
     do jj=1,3
       fcart_m(jj,ii) = fcart(jj,ii)/ab_mover%amass(ii)
     end do
   end do

   if (icycle<16)then

!    Update of velocities and positions
     vel(:,:) = vel(:,:) + bb(icycle) * ab_mover%dtion * fcart_m(:,:)
     xcart(:,:) = xcart(:,:) +&
&     aa(icycle) * ab_mover%dtion * vel(:,:)
!    Convert xcart_next to xred_next (reduced coordinates)
!    for scfcv
     call xredxcart(ab_mover%natom, -1, rprimd, xcart,&
&     xred)

   end if ! (ii<16)

 end if ! if (icycle>1)

!write(std_out,*) 'srkna14 06',jump_end_of_cycle
!##########################################################
!### 06. Compute the next values (Only for the last cycle)

 if(jump_end_of_cycle)then
   icycle=ncycle
   if(zDEBUG) write(std_out,*) 'This is the last cycle, avoid the others and continue'
 end if

!write(std_out,*) 'srkna14 07',jump_end_of_cycle
!##########################################################
!### 07. Update the history with the prediction

!Increase indexes
 hist%ihist=hist%ihist+1

!Compute rprimd from rprim and acell
 do kk=1,3
   do jj=1,3
     rprimd(jj,kk)=rprim(jj,kk)*acell(jj)
   end do
 end do

!Compute xcart from xred, and rprimd
 call xredxcart(ab_mover%natom,1,rprimd,xcart,xred)

!Fill the history with the variables
!xcart, xred, acell, rprimd
 call var2hist(acell,hist,ab_mover%natom,rprim,rprimd,xcart,xred,zDEBUG)

 hist%histV(:,:,hist%ihist)=vel(:,:)
 hist%histT(hist%ihist)=hist%histT(hist%ihist-1)+ab_mover%dtion

end subroutine pred_srkna14
!!***
