//SRAERRCK JOB (B4),'RELEASE SRAERRCK',MSGCLASS=J,CLASS=P                    
//*                                                                     
//*****************************************************************
//*   THIS JCL WILL BE SUBMITTED TO OUR JES2 READER FROM THE FTP 
//*   SERVER, SEAVVFTP.  THIS JOB CREATES A MESSAGE ON THE MVS
//*   CONSOLES TO ADVISE ECHD THE SR UATP RESULTS FILE
//*   WAS RECEIVED FROM NPC, AND POSTS AN EXTERNAL  
//*   DATASET WITHIN CA7.  THIS WILL RELEASE SRAERRCK FOR 	
//*   PROCESSING.                 
//*****************************************************************
//*                                                                     
//STEP0001 EXEC PGM=OP998ARP                                            
//SYSIN  DD   *                                                         
  THE SR UATP RECON AND SUMMARY FILES HAVE BEEN
  RECEIVED FROM SITA. JOB SRAERRCK SHOULD NOW RELEASE.                        X
/*
//STEP0002 EXEC CA7SVC,PARM='D=SR.SRAERRCK.START,,1'              
//*
//*****************************************************************
//* CONDITION CODE TEST AND NOTIFICATION STEPS                    *
//*****************************************************************
//JS0980  EXEC PGM=IEFBR14,COND=(4,LT)
//JS0990  EXEC PGM=OP999PRP,COND=(0,EQ,JS0980),
//        PARM='+++ JOB SRAERRCK FAILED CONTACT PROD CONTROL +++'
//
