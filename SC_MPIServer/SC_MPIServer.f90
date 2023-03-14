program SC_MPIserver
    !use MPIServerSubs   !Use this to build SC_MPIServer.exe
    use SCSubs
    use, intrinsic                                          :: ISO_C_Binding
    implicit none

    interface ! Use this to build SC_MPIServer_DLL.exe
        subroutine MPIServer_Init(filename_len, filename, nT, nc, ierror) BIND(C,NAME='MPIServer_Init')
            use, intrinsic                                  :: ISO_C_Binding
            !!! GCC$ ATTRIBUTES DLLIMPORT                      :: MPIServer_Init    ! This is an alternative to C binding to import procedure stored in DLL
            integer(C_SIZE_T), intent(in)                   :: filename_len
            character(len=1,kind=C_CHAR), intent(in)        :: filename(:)
            integer(C_SIZE_T), intent(out)                  :: nT, nc
            integer(C_INT)                                  :: ierror
        endsubroutine MPIServer_Init
        subroutine MPIServer_AllReceive(msg, ierror) BIND(C,NAME='MPIServer_AllReceive')
            use, intrinsic                                  :: ISO_C_Binding
            real(C_FLOAT)                                   :: msg(:,:)
            integer(C_INT)                                  :: ierror
        endsubroutine MPIServer_AllReceive
        subroutine MPIServer_AllSend(msg,ierror) BIND(C,NAME='MPIServer_AllSend')
            use, intrinsic                                  :: ISO_C_Binding
            real(C_FLOAT)                                   :: msg(:,:)
            integer(C_INT)                                  :: ierror
        endsubroutine MPIServer_AllSend
        subroutine MPIServer_Stop(ierror) BIND(C,NAME='MPIServer_Stop')
            use, intrinsic                                  :: ISO_C_Binding      
            integer(C_INT)                                  :: ierror
        endsubroutine MPIServer_Stop
    end interface

    character(256)                                          :: MPI_sharedfile, SC_inputfile
    character(len=1, kind=C_CHAR), dimension(256)           :: C_MPI_sharedfile
    integer(C_SIZE_T) nc
    integer(C_SIZE_T) nT
    real(C_FLOAT), allocatable, dimension(:,:)              :: avrSWAP           ! Swap array for each turbine, dimension (nT,nc)
    integer ierror
    logical verbose
    integer lb

    verbose=.true.
    
    
    call get_command_argument(1,MPI_sharedfile)
    call get_command_argument(2,SC_inputfile)
    !print*, 'SC_MPIServer: Number of command line arguments:', COMMAND_ARGUMENT_COUNT(), ', MPI_sharedfile:', MPI_sharedfile, ', SC_inputfile:', SC_inputfile
    C_MPI_sharedfile(1:255)=transfer(MPI_sharedfile(1:255),C_MPI_sharedfile(1:255))
    C_MPI_sharedfile(256)=C_NULL_CHAR
    print*, MPI_sharedfile
    print*, C_MPI_sharedfile
    call MPIServer_Init( int(size(C_MPI_sharedfile),C_SIZE_T), C_MPI_sharedfile, nT, nc, ierror)
    call SC_init(int(nT), SC_inputfile)
    allocate( avrSWAP(nT,nc), stat=ierror)

    do while(.true.)
        call MPIServer_AllReceive(avrSWAP, ierror)
        lb=LBOUND(avrSWAP,2) ! For some reason the C-binded array becomes 0-indexed after going through MPIServer_AllReceive (but it remains 1-indexed in the MPI subroutines) ?!?
        if(verbose) print*, 'Server main: messages received, status: ', nint(avrSWAP(:,lb))
        !if(verbose) print*, 'Server main: message: ', avrSWAP(:,:)
        if (all(avrSWAP(:,lb).LE.-1)) exit
        !call SC_step(avrSWAP)
        if(verbose) print*, 'Server main: command updated, status: ', nint(avrSWAP(:,lb))
        call MPIServer_AllSend(avrSWAP, ierror)
        if(verbose) print*, 'Server main: messages sent, status: ', nint(avrSWAP(:,lb))
        if(ierror/=0) then
            if(verbose) print*, 'Server main: An error occured in mpi communication with error code: ', &
                ierror, ', the program will abort'
            exit
        endif
    enddo

    if(verbose) print*, 'Server main: terminating'
    call MPIServer_Stop(ierror)
    call SC_terminate()
    call cleanup()
    if(verbose) print*, 'Server main: finished'

    contains
        !-----------------------------------------------------------
        ! Cleans up allocated memory
        subroutine cleanup()
            if(allocated(avrSWAP)     )     deallocate(avrSWAP     )
        endsubroutine cleanup

end program SC_MPIserver