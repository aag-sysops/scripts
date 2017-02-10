//SRRECATX JOB (B4),'DLIEBRI',MSGCLASS=J,CLASS=P
//*
//*****************************************************************
//*   THE FOLLOWING STEP WILL POST A DATASET DEPENDENCY
//*****************************************************************
//*   THE FOLLOWING STEP EXECUTE A CA7 COMMAND IN BATCH MODE;
//*   USUALLY USED FOR DEMANDING IN JOBS
//*****************************************************************
//BTERM EXEC BTIFACE
//SYSIN DD  DSN=CA7.BTI.CMND(LOGON),DISP=SHR
//      DD *
DEMAND,JOB=SRRECATX
/LOGOFF
/*                    
//
