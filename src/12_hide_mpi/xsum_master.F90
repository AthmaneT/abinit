!{\src2tex{textfont=tt}}
!!****f* ABINIT/xsum_master
!! NAME
!!  xsum_master
!!
!! FUNCTION
!!  This module contains functions that calls MPI routine,
!!  if we compile the code using the MPI  CPP flags.
!!  xsum_master is the generic function.
!!
!! COPYRIGHT
!!  Copyright (C) 2001-2012 ABINIT group (AR,XG,MB)
!!  This file is distributed under the terms of the
!!  GNU General Public License, see ~ABINIT/COPYING
!!  or http://www.gnu.org/copyleft/gpl.txt .
!!
!! TODO
!!
!! SOURCE

#if defined HAVE_CONFIG_H
#include "config.h"
#endif

!!***

!!****f* ABINIT/xsum_master_int
!! NAME
!!  xsum_master_int
!!
!! FUNCTION
!!  Reduces values on all processes to a single value.
!!  Target: integer scalars.
!!
!! INPUTS
!!  master= master MPI node
!!  spaceComm= MPI communicator
!!
!! OUTPUT
!!  ier= exit status, a non-zero value meaning there is an error
!!
!! SIDE EFFECTS
!!  xval= buffer array
!!
!! PARENTS
!!
!! CHILDREN
!!      mpi_comm_size,mpi_reduce
!!
!! SOURCE

subroutine xsum_master_int(xval,master,spaceComm,ier)

 use defs_basis

#if defined HAVE_MPI && defined HAVE_MPI2 && ! defined HAVE_MPI_INCLUDED_ONCE
 use mpi
#endif

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'xsum_master_int'
!End of the abilint section

 implicit none

#if defined HAVE_MPI && defined HAVE_MPI1
 include 'mpif.h'
#endif

!Arguments-------------------------
 integer,intent(inout) :: xval
 integer ,intent(in) :: master
 integer ,intent(in) :: spaceComm
 integer ,intent(out)   :: ier

!Local variables-------------------
#if defined HAVE_MPI
 integer :: xsum
 integer :: nproc_space_comm
#endif

! *************************************************************************

 ier=0
#if defined HAVE_MPI
 if (spaceComm /= MPI_COMM_NULL) then
   call MPI_COMM_SIZE(spaceComm,nproc_space_comm,ier)
   if (nproc_space_comm /= 1) then
!    Accumulate xval on all proc. in spaceComm
     call MPI_REDUCE(xval,xsum,1,MPI_INTEGER,MPI_SUM,master,spaceComm,ier)
     xval = xsum
   end if
 end if
#endif
end subroutine xsum_master_int
!!***

!!****f* ABINIT/xsum_master_dp1d
!! NAME
!!  xsum_master_dp1d
!!
!! FUNCTION
!!  Reduces values on all processes to a single value.
!!  Target: double precision one-dimensional arrays.
!!
!! INPUTS
!!  master= master MPI node
!!  spaceComm= MPI communicator
!!
!! OUTPUT
!!  ier= exit status, a non-zero value meaning there is an error
!!
!! SIDE EFFECTS
!!  xval= buffer array
!!
!! PARENTS
!!
!! CHILDREN
!!      mpi_comm_size,mpi_reduce
!!
!! SOURCE

subroutine xsum_master_dp1d(xval,master,spaceComm,ier)

 use defs_basis

#if defined HAVE_MPI2 && ! defined HAVE_MPI_INCLUDED_ONCE
 use mpi
#endif

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'xsum_master_dp1d'
!End of the abilint section

 implicit none

#if defined HAVE_MPI1
 include 'mpif.h'
#endif

!Arguments-------------------------
 real(dp),intent(inout) :: xval(:)
 integer ,intent(in) :: master
 integer ,intent(in) :: spaceComm
 integer ,intent(out)   :: ier

!Local variables-------------------
#if defined HAVE_MPI
 integer :: n1
 real(dp) , allocatable :: xsum(:)
 integer :: nproc_space_comm
#endif

! *************************************************************************

 ier=0
#if defined HAVE_MPI
 if (spaceComm /= MPI_COMM_NULL) then
   call MPI_COMM_SIZE(spaceComm,nproc_space_comm,ier)
   if (nproc_space_comm /= 1) then
     n1 = size(xval,dim=1)
!    Accumulate xval on all proc. in spaceComm
     ABI_ALLOCATE(xsum,(n1))
     call MPI_REDUCE(xval,xsum,n1,MPI_DOUBLE_PRECISION,MPI_SUM,master,spaceComm,ier)
     xval (:) = xsum(:)
     ABI_DEALLOCATE(xsum)
   end if
 end if
#endif
end subroutine xsum_master_dp1d
!!***

!!****f* ABINIT/xsum_master_dp2d
!! NAME
!!  xsum_master_dp2d
!!
!! FUNCTION
!!  Reduces values on all processes to a single value.
!!  Target: double precision two-dimensional arrays.
!!
!! INPUTS
!!  master= master MPI node
!!  spaceComm= MPI communicator
!!
!! OUTPUT
!!  ier= exit status, a non-zero value meaning there is an error
!!
!! SIDE EFFECTS
!!  xval= buffer array
!!
!! PARENTS
!!
!! CHILDREN
!!      mpi_comm_size,mpi_reduce
!!
!! SOURCE

subroutine xsum_master_dp2d(xval,master,spaceComm,ier)

 use defs_basis
#if defined HAVE_MPI2 && ! defined HAVE_MPI_INCLUDED_ONCE
 use mpi
#endif

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'xsum_master_dp2d'
!End of the abilint section

 implicit none

#if defined HAVE_MPI1
 include 'mpif.h'
#endif

!Arguments-------------------------
 real(dp),intent(inout) :: xval(:,:)
 integer ,intent(in) :: master
 integer ,intent(in) :: spaceComm
 integer ,intent(out)   :: ier

!Local variables-------------------
#if defined HAVE_MPI
 integer :: n1,n2
 real(dp) , allocatable :: xsum(:,:)
 integer :: nproc_space_comm
#endif

! *************************************************************************

 ier=0
#if defined HAVE_MPI
 if (spaceComm /= MPI_COMM_NULL) then
   call MPI_COMM_SIZE(spaceComm,nproc_space_comm,ier)
   if (nproc_space_comm /= 1) then
     n1 = size(xval,dim=1)
     n2 = size(xval,dim=2)
!    Accumulate xval on all proc. in spaceComm
     ABI_ALLOCATE(xsum,(n1,n2))
     call MPI_REDUCE(xval,xsum,n1*n2,MPI_DOUBLE_PRECISION,MPI_SUM,master,spaceComm,ier)
     xval (:,:) = xsum(:,:)
     ABI_DEALLOCATE(xsum)
   end if
 end if
#endif
end subroutine xsum_master_dp2d
!!***

!!****f* ABINIT/xsum_master_dp3d
!! NAME
!!  xsum_master_dp3d
!!
!! FUNCTION
!!  Reduces values on all processes to a single value.
!!  Target: double precision three-dimensional arrays.
!!
!! INPUTS
!!  master= master MPI node
!!  spaceComm= MPI communicator
!!
!! OUTPUT
!!  ier= exit status, a non-zero value meaning there is an error
!!
!! SIDE EFFECTS
!!  xval= buffer array
!!
!! PARENTS
!!
!! CHILDREN
!!      mpi_comm_size,mpi_reduce
!!
!! SOURCE
subroutine xsum_master_dp3d(xval,master,spaceComm,ier)

 use defs_basis
#if defined HAVE_MPI2 && ! defined HAVE_MPI_INCLUDED_ONCE
 use mpi
#endif

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'xsum_master_dp3d'
!End of the abilint section

 implicit none

#if defined HAVE_MPI1
 include 'mpif.h'
#endif

!Arguments-------------------------
 real(dp),intent(inout) :: xval(:,:,:)
 integer ,intent(in) :: master
 integer ,intent(in) :: spaceComm
 integer ,intent(out)   :: ier

!Local variables-------------------
#if defined HAVE_MPI
 integer :: n1,n2,n3
 real(dp) , allocatable :: xsum(:,:,:)
 integer :: nproc_space_comm
#endif

! *************************************************************************

 ier=0
#if defined HAVE_MPI
 if (spaceComm /= MPI_COMM_NULL) then
   call MPI_COMM_SIZE(spaceComm,nproc_space_comm,ier)
   if (nproc_space_comm /= 1) then
     n1 = size(xval,dim=1)
     n2 = size(xval,dim=2)
     n3 = size(xval,dim=3)
!    Accumulate xval on all proc. in spaceComm
     ABI_ALLOCATE(xsum,(n1,n2,n3))
     call MPI_REDUCE(xval,xsum,n1*n2*n3,MPI_DOUBLE_PRECISION,MPI_SUM,master,spaceComm,ier)
     xval (:,:,:) = xsum(:,:,:)
     ABI_DEALLOCATE(xsum)
   end if
 end if
#endif
end subroutine xsum_master_dp3d
!!***

!!****f* ABINIT/xsum_master_dp4d
!! NAME
!!  xsum_master_dp4d
!!
!! FUNCTION
!!  Reduces values on all processes to a single value.
!!  Target: double precision four-dimensional arrays.
!!
!! INPUTS
!!  master= master MPI node
!!  spaceComm= MPI communicator
!!
!! OUTPUT
!!  ier= exit status, a non-zero value meaning there is an error
!!
!! SIDE EFFECTS
!!  xval= buffer array
!!
!! PARENTS
!!
!! CHILDREN
!!      mpi_comm_size,mpi_reduce
!!
!! SOURCE
subroutine xsum_master_dp4d(xval,master,spaceComm,ier)

 use defs_basis
#if defined HAVE_MPI2 && ! defined HAVE_MPI_INCLUDED_ONCE
 use mpi
#endif

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'xsum_master_dp4d'
!End of the abilint section

 implicit none

#if defined HAVE_MPI1
 include 'mpif.h'
#endif

!Arguments-------------------------
 real(dp),intent(inout) :: xval(:,:,:,:)
 integer ,intent(in) :: master
 integer ,intent(in) :: spaceComm
 integer ,intent(out)   :: ier

!Local variables-------------------
#if defined HAVE_MPI
 integer :: n1,n2,n3,n4
 real(dp) , allocatable :: xsum(:,:,:,:)
 integer :: nproc_space_comm
#endif

! *************************************************************************

 ier=0
#if defined HAVE_MPI
 if (spaceComm /= MPI_COMM_NULL) then
   call MPI_COMM_SIZE(spaceComm,nproc_space_comm,ier)
   if (nproc_space_comm /= 1) then
     n1 = size(xval,dim=1)
     n2 = size(xval,dim=2)
     n3 = size(xval,dim=3)
     n4 = size(xval,dim=4)
!    Accumulate xval on all proc. in spaceComm
     ABI_ALLOCATE(xsum,(n1,n2,n3,n4))
     call MPI_REDUCE(xval,xsum,n1*n2*n3*n4,MPI_DOUBLE_PRECISION,MPI_SUM,master,spaceComm,ier)
     xval (:,:,:,:) = xsum(:,:,:,:)
     ABI_DEALLOCATE(xsum)
   end if
 end if
#endif

end subroutine xsum_master_dp4d
!!***

!!****f* ABINIT/xsum_master_dp5d
!! NAME
!!  xsum_master_dp5d
!!
!! FUNCTION
!!  Reduces values on all processes to a single value.
!!  Target: double precision five-dimensional arrays.
!!
!! INPUTS
!!  master= master MPI node
!!  spaceComm= MPI communicator
!!
!! OUTPUT
!!  ier= exit status, a non-zero value meaning there is an error
!!
!! SIDE EFFECTS
!!  xval= buffer array
!!
!! PARENTS
!!
!! CHILDREN
!!      mpi_comm_size,mpi_reduce
!!
!! SOURCE
subroutine xsum_master_dp5d(xval,master,spaceComm,ier)

 use defs_basis

#if defined HAVE_MPI2 && ! defined HAVE_MPI_INCLUDED_ONCE
 use mpi
#endif

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'xsum_master_dp5d'
!End of the abilint section

 implicit none

#if defined HAVE_MPI1
 include 'mpif.h'
#endif

!Arguments ------------------------------------
 real(dp),intent(inout) :: xval(:,:,:,:,:)
 integer ,intent(in) :: master
 integer ,intent(in) :: spaceComm
 integer ,intent(out)   :: ier
!Local variables-------------------------------
#if defined HAVE_MPI
 integer :: n1,n2,n3,n4,n5
 real(dp), allocatable :: xsum(:,:,:,:,:)
 integer :: nproc_space_comm
#endif

! *************************************************************************

 ier=0
#if defined HAVE_MPI
 if (spaceComm /= MPI_COMM_NULL) then
   call MPI_COMM_SIZE(spaceComm,nproc_space_comm,ier)
   if (nproc_space_comm /= 1) then
     n1 = size(xval,dim=1)
     n2 = size(xval,dim=2)
     n3 = size(xval,dim=3)
     n4 = size(xval,dim=4)
     n5 = size(xval,dim=5)
!    Accumulate xval on all proc. in spaceComm
     ABI_ALLOCATE(xsum,(n1,n2,n3,n4,n5))
     call MPI_reduce(xval,xsum,n1*n2*n3*n4*n5,MPI_DOUBLE_PRECISION,MPI_SUM,master,spaceComm,ier)
     xval (:,:,:,:,:) = xsum(:,:,:,:,:)
     ABI_DEALLOCATE(xsum)
   end if
 end if
#endif

end subroutine xsum_master_dp5d
!!***

!!****f* ABINIT/xsum_master_dp6d
!! NAME
!!  xsum_master_dp6d
!!
!! FUNCTION
!!  Reduces values on all processes to a single value.
!!  Target: double precision six-dimensional arrays.
!!
!! INPUTS
!!  master= master MPI node
!!  spaceComm= MPI communicator
!!
!! OUTPUT
!!  ier= exit status, a non-zero value meaning there is an error
!!
!! SIDE EFFECTS
!!  xval= buffer array
!!
!! PARENTS
!!
!! CHILDREN
!!      mpi_comm_size,mpi_reduce
!!
!! SOURCE
subroutine xsum_master_dp6d(xval,master,spaceComm,ier)

 use defs_basis

#if defined HAVE_MPI2 && ! defined HAVE_MPI_INCLUDED_ONCE
 use mpi
#endif

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'xsum_master_dp6d'
!End of the abilint section

 implicit none

#if defined HAVE_MPI1
 include 'mpif.h'
#endif

!Arguments ------------------------------------
 real(dp),intent(inout) :: xval(:,:,:,:,:,:)
 integer ,intent(in) :: master
 integer ,intent(in) :: spaceComm
 integer ,intent(out)   :: ier
!Local variables-------------------------------
#if defined HAVE_MPI
 integer :: n1,n2,n3,n4,n5,n6
 real(dp), allocatable :: xsum(:,:,:,:,:,:)
 integer :: nproc_space_comm
#endif

! *************************************************************************

 ier=0
#if defined HAVE_MPI
 if (spaceComm /= MPI_COMM_NULL) then
   call MPI_COMM_SIZE(spaceComm,nproc_space_comm,ier)
   if (nproc_space_comm /= 1) then
     n1 = size(xval,dim=1)
     n2 = size(xval,dim=2)
     n3 = size(xval,dim=3)
     n4 = size(xval,dim=4)
     n5 = size(xval,dim=5)
     n6 = size(xval,dim=6)
!    Accumulate xval on all proc. in spaceComm
     ABI_ALLOCATE(xsum,(n1,n2,n3,n4,n5,n6))
     call MPI_reduce(xval,xsum,n1*n2*n3*n4*n5*n6,MPI_DOUBLE_PRECISION,MPI_SUM,master,spaceComm,ier)
     xval (:,:,:,:,:,:) = xsum(:,:,:,:,:,:)
     ABI_DEALLOCATE(xsum)
   end if
 end if
#endif

end subroutine xsum_master_dp6d
!!***

!!****f* ABINIT/xsum_master_dp7d
!! NAME
!!  xsum_master_dp7d
!!
!! FUNCTION
!!  Reduces values on all processes to a single value.
!!  Target: double precision seven-dimensional arrays.
!!
!! INPUTS
!!  master= master MPI node
!!  spaceComm= MPI communicator
!!
!! OUTPUT
!!  ier= exit status, a non-zero value meaning there is an error
!!
!! SIDE EFFECTS
!!  xval= buffer array
!!
!! PARENTS
!!
!! CHILDREN
!!      mpi_comm_size,mpi_reduce
!!
!! SOURCE
subroutine xsum_master_dp7d(xval,master,spaceComm,ier)

 use defs_basis

#if defined HAVE_MPI2 && ! defined HAVE_MPI_INCLUDED_ONCE
 use mpi
#endif

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'xsum_master_dp7d'
!End of the abilint section

 implicit none

#if defined HAVE_MPI1
 include 'mpif.h'
#endif
!Arguments ------------------------------------
 real(dp),intent(inout) :: xval(:,:,:,:,:,:,:)
 integer ,intent(in) :: master
 integer ,intent(in) :: spaceComm
 integer ,intent(out)   :: ier
!Local variables-------------------------------
#if defined HAVE_MPI
 integer :: n1,n2,n3,n4,n5,n6,n7
 real(dp), allocatable :: xsum(:,:,:,:,:,:,:)
 integer :: nproc_space_comm
#endif

! *************************************************************************

 ier=0
#if defined HAVE_MPI
 if (spaceComm /= MPI_COMM_NULL) then
   call MPI_COMM_SIZE(spaceComm,nproc_space_comm,ier)
   if (nproc_space_comm /= 1) then
     n1 = size(xval,dim=1)
     n2 = size(xval,dim=2)
     n3 = size(xval,dim=3)
     n4 = size(xval,dim=4)
     n5 = size(xval,dim=5)
     n6 = size(xval,dim=6)
     n7 = size(xval,dim=7)
!    Accumulate xval on all proc. in spaceComm
     ABI_ALLOCATE(xsum,(n1,n2,n3,n4,n5,n6,n7))
     call MPI_reduce(xval,xsum,n1*n2*n3*n4*n5*n6*n7,MPI_DOUBLE_PRECISION,MPI_SUM,master,spaceComm,ier)
     xval (:,:,:,:,:,:,:) = xsum(:,:,:,:,:,:,:)
     ABI_DEALLOCATE(xsum)
   end if
 end if
#endif

end subroutine xsum_master_dp7d
!!***

!!****f* ABINIT/xsum_master_int4d
!! NAME
!!  xsum_master_int4d
!!
!! FUNCTION
!!  Reduces values on all processes to a single value.
!!  Target: four-diemnsional integer arrays.
!!
!! INPUTS
!!  master= master MPI node
!!  spaceComm= MPI communicator
!!
!! OUTPUT
!!  ier= exit status, a non-zero value meaning there is an error
!!
!! SIDE EFFECTS
!!  xval= buffer array
!!
!! PARENTS
!!
!! CHILDREN
!!      mpi_comm_size,mpi_reduce
!!
!! SOURCE
subroutine xsum_master_int4d(xval,master,spaceComm,ier)

 use defs_basis

#if defined HAVE_MPI2 && ! defined HAVE_MPI_INCLUDED_ONCE
 use mpi
#endif

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'xsum_master_int4d'
!End of the abilint section

 implicit none

#if defined HAVE_MPI1
 include 'mpif.h'
#endif
!Arguments ------------------------------------
 integer ,intent(inout) :: xval(:,:,:,:)
 integer ,intent(in) :: master
 integer ,intent(in) :: spaceComm
 integer ,intent(out)   :: ier

!Local variables-------------------------------
#if defined HAVE_MPI
 integer :: n1,n2,n3,n4
 integer, allocatable :: xsum(:,:,:,:)
 integer :: nproc_space_comm
#endif

! *************************************************************************

 ier=0
#if defined HAVE_MPI
 if (spaceComm /= MPI_COMM_NULL) then
   call MPI_COMM_SIZE(spaceComm,nproc_space_comm,ier)
   if (nproc_space_comm /= 1) then
     n1 = size(xval,dim=1)
     n2 = size(xval,dim=2)
     n3 = size(xval,dim=3)
     n4 = size(xval,dim=4)
!    Accumulate xval on all proc. in spaceComm
     ABI_ALLOCATE(xsum,(n1,n2,n3,n4))
     call MPI_reduce(xval,xsum,n1*n2*n3*n4,MPI_INTEGER,MPI_SUM,master,spaceComm,ier)
     xval (:,:,:,:) = xsum(:,:,:,:)
     ABI_DEALLOCATE(xsum)
   end if
 end if
#endif

end subroutine xsum_master_int4d
!!***

!!****f* ABINIT/xsum_master_c1cplx
!! NAME
!!  xsum_master_c1cplx
!!
!! FUNCTION
!!  Reduces values on all processes to a single value.
!!  Target: one-dimensional complex arrays.
!!
!! INPUTS
!!  master= master MPI node
!!  spaceComm= MPI communicator
!!
!! OUTPUT
!!  ier= exit status, a non-zero value meaning there is an error
!!
!! SIDE EFFECTS
!!  xval= buffer array
!!
!! PARENTS
!!
!! CHILDREN
!!      mpi_comm_size,mpi_reduce
!!
!! SOURCE

subroutine xsum_master_c1cplx(xval,master,spaceComm,ier)

 use defs_basis

#if defined HAVE_MPI2 && ! defined HAVE_MPI_INCLUDED_ONCE
 use mpi
#endif

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'xsum_master_c1cplx'
!End of the abilint section

 implicit none

#if defined HAVE_MPI1
 include 'mpif.h'
#endif

!Arguments-------------------------
 complex(spc),intent(inout) :: xval(:)
 integer ,intent(in) :: master
 integer ,intent(in) :: spaceComm
 integer ,intent(out)   :: ier

!Local variables-------------------
#if defined HAVE_MPI
 integer :: n1,nproc_space_comm
 complex(spc),allocatable :: xsum(:)
#endif

! *************************************************************************

 ier=0
#if defined HAVE_MPI
 if (spaceComm /= MPI_COMM_NULL) then
   call MPI_COMM_SIZE(spaceComm,nproc_space_comm,ier)
   if (nproc_space_comm /= 1) then
     n1 = size(xval,dim=1)
!    Collect xval from processors on master in spaceComm
     ABI_ALLOCATE(xsum,(n1))
     call MPI_REDUCE(xval,xsum,n1,MPI_COMPLEX,MPI_SUM,master,spaceComm,ier)
     xval = xsum
     ABI_DEALLOCATE(xsum)
   end if
 end if
#endif

end subroutine xsum_master_c1cplx
!!***

!!****f* ABINIT/xsum_master_c2cplx
!! NAME
!!  xsum_master_c2cplx
!!
!! FUNCTION
!!  Reduces values on all processes to a single value.
!!  Target: two-dimensional complex arrays.
!!
!! INPUTS
!!  master= master MPI node
!!  spaceComm= MPI communicator
!!
!! OUTPUT
!!  ier= exit status, a non-zero value meaning there is an error
!!
!! SIDE EFFECTS
!!  xval= buffer array
!!
!! PARENTS
!!
!! CHILDREN
!!      mpi_comm_size,mpi_reduce
!!
!! SOURCE

subroutine xsum_master_c2cplx(xval,master,spaceComm,ier)

 use defs_basis

#if defined HAVE_MPI2 && ! defined HAVE_MPI_INCLUDED_ONCE
 use mpi
#endif

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'xsum_master_c2cplx'
!End of the abilint section

 implicit none

#if defined HAVE_MPI1
 include 'mpif.h'
#endif

!Arguments-------------------------
 complex(spc),intent(inout) :: xval(:,:)
 integer ,intent(in) :: master
 integer ,intent(in) :: spaceComm
 integer ,intent(out)   :: ier

!Local variables-------------------
#if defined HAVE_MPI
 integer :: n1,n2
 integer :: nproc_space_comm
 complex(spc),allocatable :: xsum(:,:)
#endif

! *************************************************************************

 ier=0
#if defined HAVE_MPI
 if (spaceComm /= MPI_COMM_NULL) then
   call MPI_COMM_SIZE(spaceComm,nproc_space_comm,ier)
   if (nproc_space_comm /= 1) then
     n1 = size(xval,dim=1)
     n2 = size(xval,dim=2)
!    Collect xval from processors on master in spaceComm
     ABI_ALLOCATE(xsum,(n1,n2))
     call MPI_REDUCE(xval,xsum,n1*n2,MPI_COMPLEX,MPI_SUM,master,spaceComm,ier)
     xval (:,:) = xsum(:,:)
     ABI_DEALLOCATE(xsum)
   end if
 end if
#endif
end subroutine xsum_master_c2cplx
!!***

!!****f* ABINIT/xsum_master_c3cplx
!! NAME
!!  xsum_master_c3cplx
!!
!! FUNCTION
!!  Reduces values on all processes to a single value.
!!  Target: three-dimensional complex arrays.
!!
!! INPUTS
!!  master= master MPI node
!!  spaceComm= MPI communicator
!!
!! OUTPUT
!!  ier= exit status, a non-zero value meaning there is an error
!!
!! SIDE EFFECTS
!!  xval= buffer array
!!
!! PARENTS
!!
!! CHILDREN
!!      mpi_comm_size,mpi_reduce
!!
!! SOURCE
subroutine xsum_master_c3cplx(xval,master,spaceComm,ier)

 use defs_basis

#if defined HAVE_MPI2 && ! defined HAVE_MPI_INCLUDED_ONCE
 use mpi
#endif

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'xsum_master_c3cplx'
!End of the abilint section

 implicit none

#if defined HAVE_MPI1
 include 'mpif.h'
#endif

!Arguments-------------------------
 complex(spc),intent(inout) :: xval(:,:,:)
 integer ,intent(in) :: master
 integer ,intent(in) :: spaceComm
 integer ,intent(out)   :: ier

!Local variables-------------------
#if defined HAVE_MPI
 integer :: n1,n2,n3
 complex(spc), allocatable :: xsum(:,:,:)
 integer :: nproc_space_comm
#endif

! *************************************************************************

 ier=0
#if defined HAVE_MPI
 if (spaceComm /= MPI_COMM_NULL) then
   call MPI_COMM_SIZE(spaceComm,nproc_space_comm,ier)
   if (nproc_space_comm /= 1) then
     n1 = size(xval,dim=1)
     n2 = size(xval,dim=2)
     n3 = size(xval,dim=3)
!    Collect xval from processors on master in spaceComm
     ABI_ALLOCATE(xsum,(n1,n2,n3))
     call MPI_REDUCE(xval,xsum,n1*n2*n3,MPI_COMPLEX,MPI_SUM,master,spaceComm,ier)
     xval (:,:,:) = xsum(:,:,:)
     ABI_DEALLOCATE(xsum)
   end if
 end if
#endif
end subroutine xsum_master_c3cplx
!!***

!!****f* ABINIT/xsum_master_c4cplx
!! NAME
!!  xsum_master_c4cplx
!!
!! FUNCTION
!!  Reduces values on all processes to a single value.
!!  Target: four-dimensional complex arrays.
!!
!! INPUTS
!!  master= master MPI node
!!  spaceComm= MPI communicator
!!
!! OUTPUT
!!  ier= exit status, a non-zero value meaning there is an error
!!
!! SIDE EFFECTS
!!  xval= buffer array
!!
!! PARENTS
!!
!! CHILDREN
!!      mpi_comm_size,mpi_reduce
!!
!! SOURCE
subroutine xsum_master_c4cplx(xval,master,spaceComm,ier)

 use defs_basis

#if defined HAVE_MPI2 && ! defined HAVE_MPI_INCLUDED_ONCE
 use mpi
#endif

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'xsum_master_c4cplx'
!End of the abilint section

 implicit none
#if defined HAVE_MPI1
 include 'mpif.h'
#endif

!Arguments-------------------------
 complex(spc),intent(inout) :: xval(:,:,:,:)
 integer ,intent(in) :: master
 integer ,intent(in) :: spaceComm
 integer ,intent(out)   :: ier

!Local variables-------------------
#if defined HAVE_MPI
 integer :: n1,n2,n3,n4
 integer :: nproc_space_comm
 complex(spc), allocatable :: xsum(:,:,:,:)
#endif

! *************************************************************************

 ier=0
#if defined HAVE_MPI
 if (spaceComm /= MPI_COMM_NULL) then
   call MPI_COMM_SIZE(spaceComm,nproc_space_comm,ier)
   if (nproc_space_comm /= 1) then
     n1 = size(xval,dim=1)
     n2 = size(xval,dim=2)
     n3 = size(xval,dim=3)
     n4 = size(xval,dim=4)
!    Collect xval from processors on master in spaceComm
     ABI_ALLOCATE(xsum,(n1,n2,n3,n4))
     call MPI_REDUCE(xval,xsum,n1*n2*n3*n4,MPI_COMPLEX,MPI_SUM,master,spaceComm,ier)
     xval (:,:,:,:) = xsum(:,:,:,:)
     ABI_DEALLOCATE(xsum)
   end if
 end if
#endif
end subroutine xsum_master_c4cplx
!!***

!----------------------------------------------------------------------

!!****f* ABINIT/xsum_master_c5cplx
!! NAME
!!  xsum_master_c5cplx
!!
!! FUNCTION
!!  Reduces values on all processes to a single value.
!!  Target: five-dimensional single precision complex arrays.
!!
!! INPUTS
!!  master= master MPI node
!!  spaceComm= MPI communicator
!!
!! OUTPUT
!!  ier= exit status, a non-zero value meaning there is an error
!!
!! SIDE EFFECTS
!!  xval= buffer array
!!
!! PARENTS
!!
!! CHILDREN
!!      mpi_comm_size,mpi_reduce
!!
!! SOURCE
subroutine xsum_master_c5cplx(xval,master,spaceComm,ier)


 use defs_basis

#if defined HAVE_MPI2 && ! defined HAVE_MPI_INCLUDED_ONCE
 use mpi
#endif

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'xsum_master_c5cplx'
!End of the abilint section

 implicit none
#if defined HAVE_MPI1
 include 'mpif.h'
#endif

!Arguments-------------------------
 complex(spc) ,intent(inout) :: xval(:,:,:,:,:)
 integer,intent(in) :: master
 integer,intent(in) :: spaceComm
 integer,intent(out)   :: ier

!Local variables-------------------
#if defined HAVE_MPI
 integer :: n1,n2,n3,n4,n5
 complex(spc),allocatable :: xsum(:,:,:,:,:)
 integer :: nproc_space_comm
#endif

! *************************************************************************

 ier=0
#if defined HAVE_MPI
 if (spaceComm /= MPI_COMM_NULL) then
   call MPI_COMM_SIZE(spaceComm,nproc_space_comm,ier)
   if (nproc_space_comm /= 1) then
     n1 = size(xval,dim=1)
     n2 = size(xval,dim=2)
     n3 = size(xval,dim=3)
     n4 = size(xval,dim=4)
     n5 = size(xval,dim=5)
!    Collect xval from processors on master in spaceComm
     ABI_ALLOCATE(xsum,(n1,n2,n3,n4,n5))
     call MPI_REDUCE(xval,xsum,n1*n2*n3*n4*n5,MPI_COMPLEX,MPI_SUM,master,spaceComm,ier)
     xval = xsum
     ABI_DEALLOCATE(xsum)
   end if
 end if
#endif
end subroutine xsum_master_c5cplx
!!***

!!****f* ABINIT/xsum_master_c1dpc
!! NAME
!!  xsum_master_c1dpc
!!
!! FUNCTION
!!  Reduces values on all processes to a single value.
!!  Target: one-dimensional double complex arrays.
!!
!! INPUTS
!!  master= master MPI node
!!  spaceComm= MPI communicator
!!
!! OUTPUT
!!  ier= exit status, a non-zero value meaning there is an error
!!
!! SIDE EFFECTS
!!  xval= buffer array
!!
!! PARENTS
!!
!! CHILDREN
!!      mpi_comm_size,mpi_reduce
!!
!! SOURCE
subroutine xsum_master_c1dpc(xval,master,spaceComm,ier)

 use defs_basis

#if defined HAVE_MPI2 && ! defined HAVE_MPI_INCLUDED_ONCE
 use mpi
#endif

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'xsum_master_c1dpc'
!End of the abilint section

 implicit none
#if defined HAVE_MPI1
 include 'mpif.h'
#endif

!Arguments-------------------------
 complex(dpc) ,intent(inout) :: xval(:)
 integer,intent(in) :: master
 integer,intent(in) :: spaceComm
 integer,intent(out) :: ier

!Local variables-------------------
#if defined HAVE_MPI
 integer :: n1
 integer :: nproc_space_comm
 complex(dpc),allocatable :: xsum(:)
#endif

! *************************************************************************

 ier=0
#if defined HAVE_MPI
 if (spaceComm /= MPI_COMM_NULL) then
   call MPI_COMM_SIZE(spaceComm,nproc_space_comm,ier)
   if (nproc_space_comm /= 1) then
     n1 = size(xval,dim=1)
!    Collect xval from processors on master in spaceComm
     ABI_ALLOCATE(xsum,(n1))
     call MPI_REDUCE(xval,xsum,n1,MPI_DOUBLE_COMPLEX,MPI_SUM,master,spaceComm,ier)
     xval (:) = xsum(:)
     ABI_DEALLOCATE(xsum)
   end if
 end if
#endif

end subroutine xsum_master_c1dpc
!!***

!!****f* ABINIT/xsum_master_c2dpc
!! NAME
!!  xsum_master_c2dpc
!!
!! FUNCTION
!!  Reduces values on all processes to a single value.
!!  Target: two-dimensional double complex arrays.
!!
!! INPUTS
!!  master= master MPI node
!!  spaceComm= MPI communicator
!!
!! OUTPUT
!!  ier= exit status, a non-zero value meaning there is an error
!!
!! SIDE EFFECTS
!!  xval= buffer array
!!
!! PARENTS
!!
!! CHILDREN
!!      mpi_comm_size,mpi_reduce
!!
!! SOURCE
subroutine xsum_master_c2dpc(xval,master,spaceComm,ier)

 use defs_basis

#if defined HAVE_MPI2 && ! defined HAVE_MPI_INCLUDED_ONCE
 use mpi
#endif

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'xsum_master_c2dpc'
!End of the abilint section

 implicit none
#if defined HAVE_MPI1
 include 'mpif.h'
#endif

!Arguments-------------------------
 complex(dpc) ,intent(inout) :: xval(:,:)
 integer ,intent(in) :: master
 integer ,intent(in) :: spaceComm
 integer ,intent(out)   :: ier

!Local variables-------------------
#if defined HAVE_MPI
 integer :: n1,n2
 complex(dpc) , allocatable :: xsum(:,:)
 integer :: nproc_space_comm
#endif

! *************************************************************************

 ier=0
#if defined HAVE_MPI
 if (spaceComm /= MPI_COMM_NULL) then
   call MPI_COMM_SIZE(spaceComm,nproc_space_comm,ier)
   if (nproc_space_comm /= 1) then
     n1 = size(xval,dim=1)
     n2 = size(xval,dim=2)
!    Collect xval from processors on master in spaceComm
     ABI_ALLOCATE(xsum,(n1,n2))
     call MPI_REDUCE(xval,xsum,n1*n2,MPI_DOUBLE_COMPLEX,MPI_SUM,master,spaceComm,ier)
     xval (:,:) = xsum(:,:)
     ABI_DEALLOCATE(xsum)
   end if
 end if
#endif
end subroutine xsum_master_c2dpc
!!***

!!****f* ABINIT/xsum_master_c3dpc
!! NAME
!!  xsum_master_c3dpc
!!
!! FUNCTION
!!  Reduces values on all processes to a single value.
!!  Target: three-dimensional double complex arrays.
!!
!! INPUTS
!!  master= master MPI node
!!  spaceComm= MPI communicator
!!
!! OUTPUT
!!  ier= exit status, a non-zero value meaning there is an error
!!
!! SIDE EFFECTS
!!  xval= buffer array
!!
!! PARENTS
!!
!! CHILDREN
!!      mpi_comm_size,mpi_reduce
!!
!! SOURCE
subroutine xsum_master_c3dpc(xval,master,spaceComm,ier)

 use defs_basis

#if defined HAVE_MPI2 && ! defined HAVE_MPI_INCLUDED_ONCE
 use mpi
#endif

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'xsum_master_c3dpc'
!End of the abilint section

 implicit none
#if defined HAVE_MPI1
 include 'mpif.h'
#endif

!Arguments-------------------------
 complex(dpc) ,intent(inout) :: xval(:,:,:)
 integer ,intent(in) :: master
 integer ,intent(in) :: spaceComm
 integer ,intent(out)   :: ier

!Local variables-------------------
#if defined HAVE_MPI
 integer :: n1,n2,n3
 complex(dpc) , allocatable :: xsum(:,:,:)
 integer :: nproc_space_comm
#endif

! *************************************************************************

 ier=0
#if defined HAVE_MPI
 if (spaceComm /= MPI_COMM_NULL) then
   call MPI_COMM_SIZE(spaceComm,nproc_space_comm,ier)
   if (nproc_space_comm /= 1) then
     n1 = size(xval,dim=1)
     n2 = size(xval,dim=2)
     n3 = size(xval,dim=3)
!    Collect xval from processors on master in spaceComm
     ABI_ALLOCATE(xsum,(n1,n2,n3))
     call MPI_REDUCE(xval,xsum,n1*n2*n3,MPI_DOUBLE_COMPLEX,MPI_SUM,master,spaceComm,ier)
     xval (:,:,:) = xsum(:,:,:)
     ABI_DEALLOCATE(xsum)
   end if
 end if
#endif
end subroutine xsum_master_c3dpc
!!***

!!****f* ABINIT/xsum_master_c4dpc
!! NAME
!!  xsum_master_c4dpc
!!
!! FUNCTION
!!  Reduces values on all processes to a single value.
!!  Target: four-dimensional double complex arrays.
!!
!! INPUTS
!!  master= master MPI node
!!  spaceComm= MPI communicator
!!
!! OUTPUT
!!  ier= exit status, a non-zero value meaning there is an error
!!
!! SIDE EFFECTS
!!  xval= buffer array
!!
!! PARENTS
!!
!! CHILDREN
!!      mpi_comm_size,mpi_reduce
!!
!! SOURCE
subroutine xsum_master_c4dpc(xval,master,spaceComm,ier)

 use defs_basis

#if defined HAVE_MPI2 && ! defined HAVE_MPI_INCLUDED_ONCE
 use mpi
#endif

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'xsum_master_c4dpc'
!End of the abilint section

 implicit none
#if defined HAVE_MPI1
 include 'mpif.h'
#endif

!Arguments-------------------------
 complex(dpc) ,intent(inout) :: xval(:,:,:,:)
 integer ,intent(in) :: master
 integer ,intent(in) :: spaceComm
 integer ,intent(out)   :: ier

!Local variables-------------------
#if defined HAVE_MPI
 integer :: n1,n2,n3,n4
 complex(dpc) , allocatable :: xsum(:,:,:,:)
 integer :: nproc_space_comm
#endif

! *************************************************************************

 ier=0
#if defined HAVE_MPI
 if (spaceComm /= MPI_COMM_NULL) then
   call MPI_COMM_SIZE(spaceComm,nproc_space_comm,ier)
   if (nproc_space_comm /= 1) then
     n1 = size(xval,dim=1)
     n2 = size(xval,dim=2)
     n3 = size(xval,dim=3)
     n4 = size(xval,dim=4)
!    Collect xval from processors on master in spaceComm
     ABI_ALLOCATE(xsum,(n1,n2,n3,n4))
     call MPI_REDUCE(xval,xsum,n1*n2*n3*n4,MPI_DOUBLE_COMPLEX,MPI_SUM,master,spaceComm,ier)
     xval (:,:,:,:) = xsum(:,:,:,:)
     ABI_DEALLOCATE(xsum)
   end if
 end if
#endif
end subroutine xsum_master_c4dpc
!!***

!!****f* ABINIT/xsum_master_c5dpc
!! NAME
!!  xsum_master_c5dpc
!!
!! FUNCTION
!!  Reduces values on all processes to a single value.
!!  Target: five-dimensional double complex arrays.
!!
!! INPUTS
!!  master= master MPI node
!!  spaceComm= MPI communicator
!!
!! OUTPUT
!!  ier= exit status, a non-zero value meaning there is an error
!!
!! SIDE EFFECTS
!!  xval= buffer array
!!
!! PARENTS
!!
!! CHILDREN
!!      mpi_comm_size,mpi_reduce
!!
!! SOURCE
subroutine xsum_master_c5dpc(xval,master,spaceComm,ier)


 use defs_basis

#if defined HAVE_MPI2 && ! defined HAVE_MPI_INCLUDED_ONCE
 use mpi
#endif

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'xsum_master_c5dpc'
!End of the abilint section

 implicit none
#if defined HAVE_MPI1
 include 'mpif.h'
#endif

!Arguments-------------------------
 complex(dpc) ,intent(inout) :: xval(:,:,:,:,:)
 integer,intent(in) :: master
 integer,intent(in) :: spaceComm
 integer,intent(out)   :: ier

!Local variables-------------------
#if defined HAVE_MPI
 integer :: n1,n2,n3,n4,n5
 complex(dpc),allocatable :: xsum(:,:,:,:,:)
 integer :: nproc_space_comm
#endif

! *************************************************************************

 ier=0
#if defined HAVE_MPI
 if (spaceComm /= MPI_COMM_NULL) then
   call MPI_COMM_SIZE(spaceComm,nproc_space_comm,ier)
   if (nproc_space_comm /= 1) then
     n1 = size(xval,dim=1)
     n2 = size(xval,dim=2)
     n3 = size(xval,dim=3)
     n4 = size(xval,dim=4)
     n5 = size(xval,dim=5)
!    Collect xval from processors on master in spaceComm
     ABI_ALLOCATE(xsum,(n1,n2,n3,n4,n5))
     call MPI_REDUCE(xval,xsum,n1*n2*n3*n4*n5,MPI_DOUBLE_COMPLEX,MPI_SUM,master,spaceComm,ier)
     xval (:,:,:,:,:) = xsum(:,:,:,:,:)
     ABI_DEALLOCATE(xsum)
   end if
 end if
#endif
end subroutine xsum_master_c5dpc
!!***
