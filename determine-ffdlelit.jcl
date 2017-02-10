//FFDLELIT JOB (B4),'RELEASE FFFLELIT',MSGCLASS=J,CLASS=P                    
//*                                                                     
//*****************************************************************
//*   THIS JCL WILL BE SUBMITTED TO OUR JES2 READER FROM THE FTP 
//*   SERVER, SEAVVFTP. THIS JOB CREATES A MESSAGE ON THE MVS
//*   CONSOLES TO ADVISE PRODUCTION CONTROL THE FF DELATAAIR ELITE 
//*   FILE WAS RETRIEVED FROM DELATA AND DEMANDS IN JOB FFDLELIT.  
//*****************************************************************
//*                                                                     
//STEP0001 EXEC PGM=OP998ARP                                            
//SYSIN  DD   *                                                         
  THE FF DELTA AIR ELITE FILE WAS RECEIVED
  JOB FFDLELIT SHOULD NOW PROCESS...
/*                                                                      
//*****************************************************************
//*   THE FOLLOWING STEP EXECUTE A CA7 COMMAND IN BATCH MODE;
//*   USUALLY USED FOR DEMANDING IN JOBS
//*****************************************************************
//BTERM EXEC BTIFACE
//SYSIN DD  DSN=CA7.BTI.CMND(LOGON),DISP=SHR
//      DD *
DEMAND,JOB=FFDLELIT,SCHID=10
/LOGOFF
/*              
//*                    
//*****************************************************************
//* CONDITION CODE TEST AND NOTIFICATION STEPS                    *
//*****************************************************************
//JS0980  EXEC PGM=IEFBR14,COND=(4,LT)
//JS0990  EXEC PGM=OP999PRP,COND=(0,EQ,JS0980),
//        PARM='+++ JOB FFDLELIT FAILED CONTACT PROD CONTROL +++'
//*
//
