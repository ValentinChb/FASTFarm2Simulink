! Written by Valentin Chabaud (SINTEF) on 12-05-2022 (GPL 3.0 licence)

module MPIServerSubs
    use mpi
    use, intrinsic  :: ISO_C_Binding
    use, intrinsic  :: ISO_FORTRAN_ENV, only : stdout=>output_unit ! get output unit for stdout, see https://stackoverflow.com/questions/8508590/standard-input-and-output-units-in-fortran-90
    implicit none

    integer                                         :: client_comm ! client-server communicator ID
    character(MPI_MAX_PORT_NAME)                    :: port_name
    integer(C_INT)                                  :: msg_status(MPI_STATUS_SIZE)
    integer, allocatable, dimension(:)              :: count ! number of calls for each turbine, increasing incrementallly
    integer                                         :: nc, nT
    integer                                         :: globcount
    integer                                         :: nF_T ! Ratio between farm- and turbine-level step sizes 
    real                                            :: DTF, DTT
    real(C_FLOAT), allocatable, dimension(:)        :: msg_temp
    logical                                         :: verbose = .true.
    logical                                         :: textout = .true.
    integer                                         :: output_unit_eff
    logical                                         :: firstcall

    ! MPI error handling
    integer                                         :: MPI_error_code, MPI_error_length, MPI_error_tempcode
    character(len = MPI_MAX_ERROR_STRING)           :: MPI_error_message


    private             
    public                                          :: MPIServer_Init, MPIServer_AnyReceive, MPIServer_OneReceive, MPIServer_OneSend, MPIServer_AllReceive, MPIServer_AllSend, MPIServer_Stop
    
    contains

    !-------------------------------------------------------------------------
    !Tests linking and calling
    subroutine MPIServer_DLLTest(len_ary,ary,len_str,str,sze_mat,mat) BIND(C, NAME='MPIServer_DLLTest')
        integer(C_SIZE_T)                                   :: len_ary
        integer(C_INT)                                      :: ary(len_ary)
        integer(C_SIZE_T)                                   :: len_str
        character(len=1,kind=C_CHAR)                        :: str(len_str)
        integer(C_SIZE_T)                                   :: sze_mat(2)
        real(C_FLOAT)                                       :: mat(sze_mat(1),sze_mat(2))
        print*, "Server dll test: printing array of ints: length:", len_ary, ", value: ", ary
        print*, "Server dll test: printing string: length:", len_str, ", value: ", str
        print '(A,2i4,A,10f12.4)', " Server dll test: printing matrix of reals: size:", sze_mat, ", value: ", mat(1,:), mat(2,:)
    endsubroutine MPIServer_DLLTest

    !-------------------------------------------------------------------------
    !Sets up MPI communication
    subroutine MPIServer_Init(C_filename_len, C_filename, nTout, ncout, ierror) BIND(C, NAME='MPIServer_Init')
        !!! GCC$ ATTRIBUTES DLLEXPORT :: MPIServer_init
        integer(C_SIZE_T), intent(in)                       :: C_filename_len
        character(len=1,kind=C_CHAR), intent(in)            :: C_filename(C_filename_len) ! Syntax if this is to be called by Julia  
        ! character(len=1,kind=C_CHAR), intent(in)            :: C_filename(:) ! Syntax if this is to be called by Fortran   
        integer(C_SIZE_T), intent(out)                      :: nTout, ncout
        integer(C_INT)                                      :: ierror
        logical                                             :: file_exists
        character(:), allocatable                           :: filename
        integer                                             :: l_str
        character(kind=C_CHAR)                              :: c
        character(len=3), dimension(2)                      :: status
         
        status(1)='old'
        status(2)='new'
		
        output_unit_eff = stdout
        if (textout) then ! Print to text file instead of stdout
            output_unit_eff=10 
            inquire( file="stdout_MPIServerSubs.txt", exist=file_exists)
            open( unit=output_unit_eff, file="stdout_MPIServerSubs.txt", status=status(merge(1,2,file_exists)))
        endif
        
        if(verbose) write(output_unit_eff,*) 'Server init (dll): started, filename=', C_filename(1:C_filename_len-1), ", length=", C_filename_len
        if(textout) call flush(output_unit_eff)
        call MPI_INIT(MPI_error_code) ! Init mpi protocol
        if(MPI_error_code/=MPI_SUCCESS) then
            call MPI_ERROR_STRING (MPI_error_code, MPI_error_message, MPI_error_length, MPI_error_tempcode)
            write(output_unit_eff,*) 'Server init (dll): MPI error in MPI_INIT, message=',MPI_error_message(1:MPI_error_length)
            goto 1001
        endif
        call MPI_COMM_SET_ERRHANDLER(MPI_COMM_WORLD,MPI_ERRORS_RETURN,MPI_error_code)
        if(MPI_error_code/=MPI_SUCCESS) then
            call MPI_ERROR_STRING (MPI_error_code, MPI_error_message, MPI_error_length, MPI_error_tempcode)
            write(output_unit_eff,*) 'Server init (dll): MPI error setting error handler for global comm, message=',MPI_error_message(1:MPI_error_length)
            goto 1001
        endif
        call MPI_OPEN_PORT( MPI_INFO_NULL, port_name, MPI_error_code) ! Open port
        if(MPI_error_code/=MPI_SUCCESS) then
            call MPI_ERROR_STRING (MPI_error_code, MPI_error_message, MPI_error_length, MPI_error_tempcode)
            write(output_unit_eff,*) 'Server init (dll): MPI error opening port, message=',MPI_error_message(1:MPI_error_length)
            goto 1001
        endif
        if(verbose) write(output_unit_eff,*) 'Server init (dll): port name =', port_name
        if(textout) call flush(output_unit_eff)
        
        !Convert input file name from array of C_CHAR to string
        c=''
        l_str=1
        do while (c/=C_NULL_CHAR)
            c=C_filename(l_str)
            l_str=l_str+1
        enddo
        l_str=l_str-2 !Do not count C_NULL_CHAR in the end
        allocate (character(len=l_str) :: filename)
        filename = transfer(C_filename(1:l_str), filename)

        !Broadcast port name in textfile
        inquire( file=trim(adjustl(filename)), exist=file_exists)
        open( 11, file=trim(adjustl(filename)), status=status(merge(1,2,file_exists)), iostat=ierror)
            write(11,*) port_name
            if (ierror/=0) then
                write(output_unit_eff,*) "Error writing port name to MPI shared file"
                goto 1001
            endif
        close(11)

        ! Establish connection with first turbine and update MPI_shared.dat
        call MPI_COMM_ACCEPT(port_name, MPI_INFO_NULL, 0, MPI_COMM_WORLD, client_comm, MPI_error_code)  
        if(MPI_error_code/=MPI_SUCCESS) then
            call MPI_ERROR_STRING (MPI_error_code, MPI_error_message, MPI_error_length, MPI_error_tempcode)
            write(output_unit_eff,*) 'Server init (dll): MPI error establishing connection, message=',MPI_error_message(1:MPI_error_length)
            goto 1001
        endif
        if(verbose) write(output_unit_eff,*) "Server init (dll): Connection established with communicators: ", client_comm, " (client/server)",  MPI_COMM_WORLD,"(global)"
        if(textout) call flush(output_unit_eff)
        call MPI_COMM_SET_ERRHANDLER(client_comm,MPI_ERRORS_RETURN,MPI_error_code)
        if(MPI_error_code/=MPI_SUCCESS) then
            call MPI_ERROR_STRING (MPI_error_code, MPI_error_message, MPI_error_length, MPI_error_tempcode)
            write(output_unit_eff,*) 'Server init (dll): MPI error setting error handler for client/server comm, message=',MPI_error_message(1:MPI_error_length)
            goto 1000
        endif

        ! Read in number of turbines and message dimension
        open( 11, file=trim(adjustl(filename)), status='old', iostat=ierror)
            if (ierror/=0) then
                write(output_unit_eff,*) "Error opening MPI shared file"
                goto 1000
            endif
            read(11,*, iostat=ierror)
            read(11,*, iostat=ierror)
            read(11,'(i8)', iostat=ierror) nT
            if (ierror/=0) then
                write(output_unit_eff,*) "Error reading number of turbines from MPI shared file"
                goto 1000
            endif
            read(11,'(i8)', iostat=ierror) nc
            if (ierror/=0) then
                write(output_unit_eff,*) "Error reading length of control message from MPI shared file"
                goto 1000
            endif
            read(11,'(e13.4)', iostat=ierror) DTF
            if (ierror/=0) then
                write(output_unit_eff,*) "Error reading timestep from MPI shared file"
                goto 1000
            endif
        close( 11 )
        deallocate(filename)


        nTout=nT
        ncout=nc
        if(verbose) write(output_unit_eff,*) 'Server init (dll):nTout:',nTout,'ncout:',ncout
        if(textout) call flush(output_unit_eff)
        
        ! Allocate and initialize
        allocate( msg_temp(nc), stat=ierror)
        allocate( count(nT), stat=ierror)
        count=0
        globcount=0
        firstcall=.true.

        1000 continue
        if (MPI_error_code/=MPI_SUCCESS) call MPI_Abort(client_comm,MPI_error_code,MPI_error_tempcode)

        1001 continue
        if (MPI_error_code/=MPI_SUCCESS) then
            call MPI_Abort(MPI_COMM_WORLD,MPI_error_code,MPI_error_tempcode)
            ierror=-10
        endif
        if (textout) call flush(output_unit_eff)
        if (ierror/=0) call cleanup()
    endsubroutine MPIServer_Init

    !-------------------------------------------------------------------------
    !Receive from any turbine. To be used with centralized server (e.g. supercontroller).
    subroutine MPIServer_AnyReceive(iT,msg,flag,ierror) BIND(C, NAME='MPIServer_AnyReceive')
        !!! GCC$ ATTRIBUTES DLLEXPORT :: MPIServer_AnyReceive
        integer(C_INT), intent(out)         :: iT
        real(C_FLOAT), intent(inout)        :: msg(nT,nc)   ! Julia syntax
        ! real(C_FLOAT), intent(inout)        :: msg(:,:)     ! Fortran syntax
        logical(C_BOOL), intent(out)        :: flag
        integer(C_INT), intent(inout)       :: ierror
        integer                             :: source
        integer                             :: count_loc
        
        call MPI_RECV(msg_temp, nc, MPI_FLOAT, MPI_ANY_SOURCE, MPI_ANY_TAG, client_comm, msg_status, MPI_error_code) !Receive from any turbine controller instance
        if (MPI_error_code/=MPI_SUCCESS) then
            call MPI_ERROR_STRING (MPI_error_code, MPI_error_message, MPI_error_length, MPI_error_tempcode)
            write(output_unit_eff,*) 'Server receive (dll): MPI error for turbine nr:', iT, 'turb timestep nr :', count(iT), 'farm timestep nr :', globcount,'; message=',MPI_error_message(1:MPI_error_length)
            goto 1000
        endif
        iT=msg_status(4) !Extract turbine ID
        source=msg_status(3)
        if  (firstcall) then
            DTT=real(msg_temp(3))
            nF_T=nint(DTF/DTT)
            firstcall=.false.
        endif
        count(iT)=nint(msg_temp(2)/DTT) !Time starts at DTT (FAST outputs initialization values at init, but does not forwards them through MPI, the first excahnge occurs in practice at the first timestep)
        msg(iT,1:nc)=msg_temp
        if(msg(iT,1)==-1) count(iT)=count(iT)+1 !Increment at termination message eventhough the time has not changed
        count_loc=modulo(count(iT)-1,nF_T)+1
        globcount=floor(real(count(iT)-1)/nF_T)+1
        if(verbose) write(output_unit_eff,*) 'Server receive (dll): turbine nr:', iT, 'turb timestep nr :', count(iT), 'farm timestep nr :', globcount, 'status :', nint(msg(iT,1)), count_loc, nF_T, sum(count), source , client_comm   
        if(verbose) write(output_unit_eff,*) 'Server receive (dll): count status:', count-globcount*nF_T
        if(msg(iT,1)==-1) then !Termination status is received. If all instances have confirmed termination, send back gobal termination command.
            if(all(msg(:,1)==-1)) msg(iT,1)=-2
            if(verbose) write(output_unit_eff,*) 'Server receive (dll): send confirmation termination command turbine nr:', iT, 'status:', nint(msg(iT,1))
            if(textout) call flush(output_unit_eff)
        endif
        if(verbose) write(output_unit_eff,*) 'Server receive (dll): turbine nr:', iT, 'msg :', msg(iT,:)

        flag=any(count/=globcount*nF_T) .and. .not. all(msg(:,1)<0) ! stops at one turbine-level timestep before farm-level update, or at termination

        !print*, ierror, msg, count, globcount, flag           
        1000 continue
        if (MPI_error_code/=MPI_SUCCESS) then
            call MPI_Abort(client_comm,MPI_error_code,MPI_error_tempcode)
            call MPI_Abort(MPI_COMM_WORLD,MPI_error_code,MPI_error_tempcode)
            ierror=-10
        endif
        if (textout) call flush(output_unit_eff)
        if (ierror/=0) call cleanup()        
    endsubroutine MPIServer_AnyReceive

    !-------------------------------------------------------------------------
    !Receive message from one specific turbine. To be used with distributed servers (e.g. drivetrain model, typically preferred to centralized controller to keep distinct environments and/or enable parallel computing).
    subroutine MPIServer_OneReceive(iT,msg,flag,ierror) BIND(C, NAME='MPIServer_OneReceive')
        !!! GCC$ ATTRIBUTES DLLEXPORT :: MPIServer_OneReceive
        integer(C_INT), intent(in)      :: iT
        real(C_FLOAT), intent(inout)    :: msg(nT,nc)  !Julia syntax
        logical(C_BOOL), intent(out)    :: flag
        ! real(C_FLOAT), intent(inout)    :: msg(:,:)    !Fortran syntax
        integer(C_INT), intent(inout)   :: ierror

        if(verbose) write(output_unit_eff,*) 'Server receive (dll): waiting for turbine nr:', iT, 'timestep nr :', count(iT)

        call MPI_RECV(msg_temp, nc, MPI_FLOAT, MPI_ANY_SOURCE, iT, client_comm, msg_status, MPI_error_code) !Receive from turbine controller instance number iT
        if (MPI_error_code/=MPI_SUCCESS) then
            call MPI_ERROR_STRING (MPI_error_code, MPI_error_message, MPI_error_length, MPI_error_tempcode)
            write(output_unit_eff,*) 'Server receive (dll): MPI error for turbine nr:', iT, 'turb timestep nr :', count(iT), 'farm timestep nr :', globcount,'; message=',MPI_error_message(1:MPI_error_length)
            goto 1000
        endif
        msg(iT,1:nc)=msg_temp

        if  (firstcall) then
            DTT=real(msg_temp(3))
            nF_T=nint(DTF/DTT)
            firstcall=.false.
        endif
        count(iT)=nint(msg_temp(2)/DTT) !Time starts at DTT (FAST outputs initialization values at init, but does not forwards them through MPI, the first excahnge occurs in practice at the first timestep)
        if(msg(iT,1)==-1) count(iT)=count(iT)+1 !Increment at termination message eventhough the time has not changed
        
        if(msg(iT,1)==-1) then !Termination status is received. If all instances have confirmed termination, send back gobal termination command.
            if(all(msg(:,1)==-1)) msg(iT,1)=-2
            if(verbose) write(output_unit_eff,*) 'Server receive (dll): send confirmation termination command turbine nr:', iT, 'status:', nint(msg(iT,1))
            if(textout) call flush(output_unit_eff)
        endif

        globcount=floor(real(count(iT)-1)/nF_T)+1
        flag=any(count/=globcount*nF_T) .and. .not. all(msg(:,1)<0) ! Stops at one turbine-level timestep before farm-level update, or at termination

        if(verbose) write(output_unit_eff,*) 'Server receive (dll): turbine nr:', iT, 'msg :', msg(iT,:)

        1000 continue
        if (MPI_error_code/=MPI_SUCCESS) then
            call MPI_Abort(client_comm,MPI_error_code,MPI_error_tempcode)
            call MPI_Abort(MPI_COMM_WORLD,MPI_error_code,MPI_error_tempcode)
            ierror=-10
        endif
        if (textout) call flush(output_unit_eff)
        if (ierror/=0) call cleanup()  
    endsubroutine MPIServer_OneReceive   

    !-------------------------------------------------------------------------
    !Send message to one specific turbine; typically one from which a message was just received, waiting for an answer.
    subroutine MPIServer_OneSend(iT,msg,ierror) BIND(C, NAME='MPIServer_OneSend')
        !!! GCC$ ATTRIBUTES DLLEXPORT :: MPIServer_OneSend
        integer(C_INT), intent(in)      :: iT
        real(C_FLOAT), intent(in)       :: msg(nT,nc)  !Julia syntax
        ! real(C_FLOAT)       :: msg(:,:)    !Fortran syntax
        integer(C_INT), intent(inout)   :: ierror
        logical, parameter              :: blocking = .true.
        integer(C_INT)                  :: request
        integer(C_INT)                  :: send_status(MPI_STATUS_SIZE)

        if(verbose) write(output_unit_eff,*) 'Server send (dll): turbine nr:', iT, 'timestep nr :', count(iT), 'status :', nint(msg(iT,1)), 'client_comm :', client_comm
        if(textout) call flush(output_unit_eff)
        if(blocking) then
            call MPI_SEND(msg(iT,1:nc), nc, MPI_FLOAT, 0, iT, client_comm, MPI_error_code) 
        else ! Alternative if non-blocking communication should be used. Currently calling MPI_WAIT right after MPI_ISEND is in practice the same as calling MPI_SEND (i.e. blocking)
            call MPI_ISEND(msg(iT,1:nc), nc, MPI_FLOAT, 0, iT, client_comm, request, MPI_error_code) 
            call MPI_WAIT(request, send_status, MPI_error_code) 
        endif
        if (MPI_error_code/=MPI_SUCCESS) then
            call MPI_ERROR_STRING (MPI_error_code, MPI_error_message, MPI_error_length, MPI_error_tempcode)
            write(output_unit_eff,*) 'Server send (dll): MPI for turbine nr:', iT, 'turb timestep nr :', count(iT), 'farm timestep nr :', globcount,'; message=',MPI_error_message(1:MPI_error_length)
            goto 1000
        endif
        if(verbose) write(output_unit_eff,*) 'Server send (dll): turbine nr:', iT, 'sending complete' ! Warning: completed MPI_SEND does not mean the message is received on the other side, it may just have been buffered https://docs.microsoft.com/en-us/message-passing-interface/mpi-send-function 

        1000 continue
        if (MPI_error_code/=MPI_SUCCESS) then
            call MPI_Abort(client_comm,MPI_error_code,MPI_error_tempcode)
            call MPI_Abort(MPI_COMM_WORLD,MPI_error_code,MPI_error_tempcode)
            ierror=-10
        endif
        if (textout) call flush(output_unit_eff)
        if (ierror/=0) call cleanup()
    endsubroutine MPIServer_OneSend    

    ! !-------------------------------------------------------------------------
    ! !Send and Receive to/from all turbines. Allows for multiple messages per farm-level timestep, recorded in packets.
    ! subroutine MPI_AllReceiveAndSend(msg,ierror)
    !     real(C_FLOAT), intent(out)        :: msg(nT,nc,nF_T)   ! Julia syntax
    !     ! real(C_FLOAT), intent(out)        :: msg(:,:,:)     ! Fortran syntax
    !     integer(C_INT), intent(inout)       :: ierror

    !     integer                             :: count_loc
    !     integer                             :: iT

    !     flag=.true.
    !     globcount=globcount+1 ! This routine is called once per farm-level timestep
    !     msg=0.0

    !     do while(flag) !Wait for all instances to update for each turbine-level timestep (or multiple of it) during this farm-level timestep
    !         call MPI_RECV(msg_temp, nc, MPI_FLOAT, MPI_ANY_SOURCE, MPI_ANY_TAG, client_comm, msg_status, ierror) !Receive from any turbine controller instance
    !         iT=msg_status(4) !Extract turbine ID
    !         if  (firstcall) then
    !             DTT=real(msg_temp(3))
    !             nF_T=nint(DTF/DTT)
    !             firstcall=.false.
    !         endif
    !         !print*, iT, LBOUND(msg_temp), LBOUND(msg,2)
    !         count(iT)=nint(msg_temp(2)/DTT) !Time starts at DTT
    !         if(msg_temp(1)==-1) count(iT)=count(iT)+1 !Increment at termination message eventhough the time has not changed
    !         count_loc=modulo(count(iT)-1,nF_T)+1
    !         msg(iT,1:nc,count_loc)=msg_temp
            
    !         if(verbose) write(output_unit_eff,*) 'Server receive (dll): turbine nr:', iT, 'timestep nr :', count(iT), 'globcount :', globcount, 'status :', nint(msg(iT,1,count_loc))
    !         if(verbose) write(output_unit_eff,*) 'Server receive (dll): count status:', count-globcount*nF_T-1

    !         if(msg(iT,1,count_loc)==-1) then !Termination status is received. 
    !             if(all(msg(:,1,count_loc)==-1)) msg(iT,1,count_loc)=-2 !If all instances have confirmed termination, send back global termination command.
    !             if(verbose) write(output_unit_eff,*) 'Server receive (dll): send confirmation termination command turbine nr:', iT, 'status:', nint(msg(iT,1,count_loc))
    !             if(textout) call flush(output_unit_eff)
    !         endif
    !         if(verbose) write(output_unit_eff,*) 'Server receive (dll): turbine nr:', iT, 'local timestep nr :', count_loc, 'msg :', msg(:,:,count_loc)

    !         call MPI_SEND(msg(iT,1:nc,count_loc), nc, MPI_FLOAT, 0, iT, client_comm, ierror) !The turbine controller instance iT should be waiting for an answer after having sent a message itself
    !         !print*, ierror, msg, count, globcount, count_loc

    !         flag=any(count/=globcount*nF_T) ! one turbine-level timestep before farm-level update
    !     enddo

    !     if (ierror/=0) call cleanup()    
    ! end subroutine MPI_AllReceiveAndSend

    !-------------------------------------------------------------------------
    !Receives from all turbines. To be used only if send/receive occurs once per farm-level timestep.
    subroutine MPIServer_AllReceive(msg,ierror) BIND(C, NAME='MPIServer_AllReceive')
        !!! GCC$ ATTRIBUTES DLLEXPORT :: MPIServer_AllReceive
        real(C_FLOAT), intent(inout)        :: msg(nT,nc)   ! Julia syntax
        ! real(C_FLOAT), intent(inout)        :: msg(:,:)     ! Fortran syntax
        integer(C_INT), intent(inout)       :: ierror
        logical                             :: flag
        integer                             :: iT

        flag=.true.
        globcount=globcount+1
        do while(flag) !Wait for all instances to update
            call MPI_RECV(msg_temp, nc, MPI_FLOAT, MPI_ANY_SOURCE, MPI_ANY_TAG, client_comm, msg_status, MPI_error_code) !Receive from any turbine controller instance
            if (MPI_error_code/=MPI_SUCCESS) then
                call MPI_ERROR_STRING (MPI_error_code, MPI_error_message, MPI_error_length, MPI_error_tempcode)
                write(output_unit_eff,*) 'Server receive (dll): MPI error for farm timestep nr :', globcount,'; message=',MPI_error_message(1:MPI_error_length)
                goto 1000
            endif
            iT=msg_status(4) !Extract turbine ID
            msg(iT,1:nc)=msg_temp
            !print*, iT, LBOUND(msg_temp), LBOUND(msg,2)
            count(iT)=nint(msg(iT,2)/DTF)
            if(msg(iT,1)==-1) count(iT)=count(iT)+1 !Increment at termination message eventhough the time has not changed
            flag=any(count/=globcount)

            if(verbose) write(output_unit_eff,*) 'Server receive (dll): turbine nr:', iT, 'timestep nr :', count(iT), 'globcount :', globcount, 'status :', nint(msg(iT,1))
            if(verbose) write(output_unit_eff,*) 'Server receive (dll): count status:', count-globcount

            if(msg(iT,1)==-1) then !Termination status is received. If all instances have confirmed termination, send back gobal termination command.
                if(.not. flag) msg(iT,1)=-2
                if(verbose) write(output_unit_eff,*) 'Server receive (dll): send confirmation termination command turbine nr:', iT, 'status:', nint(msg(iT,1))
                if(textout) call flush(output_unit_eff)
                call MPI_SEND(msg(iT,1:nc), nc, MPI_FLOAT, 0, iT, client_comm, ierror)
            endif
            if(verbose) write(output_unit_eff,*) 'Server receive (dll): turbine nr:', iT, 'msg :', msg
            !print*, ierror, msg, count, globcount

        enddo

        1000 continue
        if (MPI_error_code/=MPI_SUCCESS) then
            call MPI_Abort(client_comm,MPI_error_code,MPI_error_tempcode)
            call MPI_Abort(MPI_COMM_WORLD,MPI_error_code,MPI_error_tempcode)
            ierror=-10
        endif
        if (textout) call flush(output_unit_eff)
        if (ierror/=0) call cleanup()        
    endsubroutine MPIServer_AllReceive

    !-------------------------------------------------------------------------
    ! Sends to all turbines. To be used only if send/receive occurs once per farm-level timestep.
    subroutine MPIServer_AllSend(msg,ierror) BIND(C, NAME='MPIServer_AllSend')
        !!! GCC$ ATTRIBUTES DLLEXPORT :: MPIServer_AllSend
        real(C_FLOAT), intent(in)           :: msg(nT,nc)  !Julia syntax
        ! real(C_FLOAT), intent(in)           :: msg(:,:)    !Fortran syntax
        integer(C_INT), intent(inout)       :: ierror
        integer                             :: iT

        do iT=1,nT
            if(verbose) write(output_unit_eff,*) 'Server send (dll): turbine nr:', IT, 'timestep nr :', count(iT), 'status :', nint(msg(iT,1))
            if(textout) call flush(output_unit_eff)
            call MPI_SEND(msg(iT,1:nc), nc, MPI_FLOAT, 0, iT, client_comm, MPI_error_code) 
            if (MPI_error_code/=MPI_SUCCESS) then
                call MPI_ERROR_STRING (MPI_error_code, MPI_error_message, MPI_error_length, MPI_error_tempcode)
                write(output_unit_eff,*) 'Server send (dll): MPI error for turbine nr:', iT, 'turb timestep nr :', count(iT), 'farm timestep nr :', globcount,'; message=',MPI_error_message(1:MPI_error_length)
                goto 1000
            endif
        enddo

        1000 continue
        if (MPI_error_code/=MPI_SUCCESS) then
            call MPI_Abort(client_comm,MPI_error_code,MPI_error_tempcode)
            call MPI_Abort(MPI_COMM_WORLD,MPI_error_code,MPI_error_tempcode)
            ierror=-10
        endif
        if (textout) call flush(output_unit_eff)
        if (ierror/=0) call cleanup()
    endsubroutine MPIServer_AllSend

    !-------------------------------------------------------------------------
    ! Terminates MPI communication
    subroutine MPIServer_Stop(ierror) BIND(C, NAME='MPIServer_Stop')
        !!! GCC$ ATTRIBUTES DLLEXPORT :: MPIServer_stop
        integer(C_INT), intent(inout)       :: ierror
        if(verbose) write(output_unit_eff,*) 'Server stop (dll): terminating' 
        if(textout) call flush(output_unit_eff)
        call MPI_CLOSE_PORT(port_name, MPI_error_code)
        if (MPI_error_code/=MPI_SUCCESS) then
            call MPI_ERROR_STRING (MPI_error_code, MPI_error_message, MPI_error_length, MPI_error_tempcode)
            write(output_unit_eff,*) 'Server stop (dll): MPI error while closing port, ; message=',MPI_error_message(1:MPI_error_length)
            goto 1001
        endif
        call MPI_COMM_DISCONNECT(client_comm, MPI_error_code) 
        if (MPI_error_code/=MPI_SUCCESS) then
            call MPI_ERROR_STRING (MPI_error_code, MPI_error_message, MPI_error_length, MPI_error_tempcode)
            write(output_unit_eff,*) 'Server stop (dll): MPI error while disconnecting, ; message=',MPI_error_message(1:MPI_error_length)
            goto 1000
        endif
        call MPI_FINALIZE(MPI_error_code)
        if (MPI_error_code/=MPI_SUCCESS) then
            call MPI_ERROR_STRING (MPI_error_code, MPI_error_message, MPI_error_length, MPI_error_tempcode)
            write(output_unit_eff,*) 'Server stop (dll): MPI error while finalizing, ; message=',MPI_error_message(1:MPI_error_length)
            goto 1000
        endif
        if(verbose) write(output_unit_eff,*) 'Server stop (dll): disconnected'   

        1001 continue
        if (MPI_error_code/=MPI_SUCCESS) call MPI_Abort(client_comm,MPI_error_code,MPI_error_tempcode)

        1000 continue
        if (MPI_error_code/=MPI_SUCCESS) then
            call MPI_Abort(MPI_COMM_WORLD,MPI_error_code,MPI_error_tempcode)
            ierror=-10
        endif
        if(textout) call flush(output_unit_eff)  
        call cleanup()
    endsubroutine MPIServer_Stop

    !-------------------------------------------------------------------------
    ! Cleans up allocated memory
    subroutine cleanup()
        if(allocated(msg_temp)) deallocate(msg_temp)
        if(allocated(count)) deallocate(count)
    endsubroutine cleanup

end module MPIServerSubs
