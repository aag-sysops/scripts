//RFASCRCV JOB (B4),'RELEASE RFASCRCV',MSGCLASS=J,CLASS=P
//*                                                                     
//*****************************************************************
//*   THIS JCL WILL BE SUBMITTED TO OUR JES2 READER BY TWS JOB 
//*   AGEXTFTP#RFASCMGT. THIS JOB WILL FTP AS REFUND COMMISSION
//*   DATA TO MVS DATASET RF.  
//*   THEN WRITES A MESSAGE ON THE MVS CONSOLES TO ADVISE
//*   PRODUCTION CONTROL THE AS REFUND COMMISSION DATA HAS BEEN  
//*   RECEIVED FROM TRISEPT, AND DEMANDS IN CA7 JOB RFASCRCV.
//*****************************************************************
//*                                                                     
//STEP0001 EXEC PGM=OP998ARP                                            
//SYSIN  DD   *                                                         
  THE AS REFUND REDEPMTION DATA HAS ARRIVED FROM
  TRISEPT, JOB RFASCRCV SHOULD NOW PROCESS...                             X     
/*                                                                      
//STEP0002 EXEC BTIFACE
//SYSIN DD DSN=CA7.BTI.CMND(LOGON),DISP=SHR
//      DD *
DEMAND,JOB=RFASCRCV,SCHID=15
/LOGOFF
/*              
//*
//*****************************************************************
//* CONDITION CODE TEST AND NOTIFICATION STEPS                    *
//*****************************************************************
//JS0980  EXEC PGM=IEFBR14,COND=(4,LT)
//JS0990  EXEC PGM=OP999PRP,COND=(0,EQ,JS0980),
//        PARM='+++ JOB RFASCRCV FAILED CONTACT PROD CONTROL +++'
//
