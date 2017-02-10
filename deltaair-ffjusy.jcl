//FFJUSY JOB (B4),'RELEASE FFJUSY',MSGCLASS=J,CLASS=P                    
//*                                                                     
//*****************************************************************
//*   THIS JCL WILL BE SUBMITTED TO OUR JES2 READER FROM THE FTP 
//*   SERVER, SEAVVDMZFTP.  THIS JOB CREATES A MESSAGE ON THE MVS
//*   CONSOLES TO ADVISE PRODUCTION CONTROL THE FF SAFEWAY CRT 
//*   FEED FILE WAS RETRIEVED FROM SAFEWAY AND DEMANDS IN JOB FFJUSY.  
//*****************************************************************
//*                                                                     
//STEP0001 EXEC PGM=OP998ARP                                            
//SYSIN  DD   *                                                         
  THE SAFEWAY CRT FEED FILE WAS RECEIVED
  JOB FFJUSY  SHOULD NOW PROCESS...                                    X
/*                                                                      
//STEP0002 EXEC CA7SVC,PARM='D=FF.FFJUSY.START,,1'                    
//*
//*****************************************************************
//* CONDITION CODE TEST AND NOTIFICATION STEPS                    *
//*****************************************************************
//JS0980  EXEC PGM=IEFBR14,COND=(4,LT)
//JS0990  EXEC PGM=OP999PRP,COND=(0,EQ,JS0980),
//        PARM='+++ JOB FFCRTSY FAILED CONTACT PROD CONTROL +++'
//*
//
