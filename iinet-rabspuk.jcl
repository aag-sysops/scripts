//RABSPUK JOB (B4),'SEAVV',MSGCLASS=J,CLASS=E
//*
//*****************************************************************
//*   THIS JCL WILL BE SUBMITTED TO OUR JES2 READER FROM THE FTP 
//*   SERVER, SEAVVFTP.  THIS JOB CREATES A MESSAGE ON THE MVS
//*   CONSOLE TO ADVISE PRODUCTION SUPPORT THAT THE UK BSP 
//*   FILE WAS RETRIEVED FROM IINET AND DEMANDS IN JOB RABSPUK.
//*****************************************************************
//*
//STEP0001 EXEC PGM=OP998ARP
//SYSIN  DD   *
  RABSPUK SHOULD BEGIN PROCESSING.
/*
//*****************************************************************
//*   THE FOLLOWING STEP EXECUTE A CA7 COMMAND IN BATCH MODE;
//*   USUALLY USED FOR DEMANDING IN JOBS
//*****************************************************************
//BTERM EXEC BTIFACE
//SYSIN DD  DSN=CA7.BTI.CMND(LOGON),DISP=SHR
//      DD *
DEMAND,JOB=RABSPUK,SCHID=2
/LOGOFF
/*              
//*                    
//*****************************************************************
//* CONDITION CODE TEST AND NOTIFICATION STEPS                    *
//*****************************************************************
//JS0980  EXEC PGM=IEFBR14,COND=(4,LT)
//JS0990  EXEC PGM=OP999PRP,COND=(0,EQ,JS0980),
//        PARM='+++ JOB RABSPUK FAILED CONTACT PROD CONTROL +++'
//*
//
