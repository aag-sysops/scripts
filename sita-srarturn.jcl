//SRARTURN JOB (B4),'RELEASE SRARTURN',MSGCLASS=J,CLASS=P                    
//*                                                                     
//*****************************************************************
//*   THIS JCL WILL BE SUBMITTED TO OUR JES2 READER FROM THE FTP 
//*   SERVER, SEAVVFTP.  THIS JOB CREATES A MESSAGE ON THE MVS
//*   CONSOLE TO ADVISE PRODUCTION CONTROL THE SR UATP RECON AND
//*   SUMMARY FILES WERE RECEIVED FROM SITA AND POSTS AN EXTERNAL
//*   DATASET WITHIN CA7. THIS WILL RELEASE SRARTURN FOR PROCESSING.
//*****************************************************************
//*                                                                     
//STEP0001 EXEC PGM=OP998ARP                                            
//SYSIN  DD   *                                                         
  THE SR UATP RECON FILE HAS ARRIVED FROM SITA,
  JOB SRARTURN SHOULD NOW RELEASE...                                         X    
/*                                                                      
//STEP0002 EXEC CA7SVC,PARM='D=SR.SRARTURN.START,,1'              
//*
//*****************************************************************
//* CONDITION CODE TEST AND NOTIFICATION STEPS                    *
//*****************************************************************
//JS0980  EXEC PGM=IEFBR14,COND=(4,LT)
//JS0990  EXEC PGM=OP999PRP,COND=(0,EQ,JS0980),
//        PARM='+++ JOB SRARTURN FAILED CONTACT PROD CONTROL +++'
//*
//
