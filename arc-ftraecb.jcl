//FTRAECB JOB (B4),'RELEASE RAECBRCV',MSGCLASS=J,CLASS=P                    
//*                                                                     
//*****************************************************************
//*   THIS JCL WILL BE SUBMITTED TO OUR JES2 READER FROM THE FTP 
//*   SERVER, SEAVVFTP.                                         
//*   THIS JOB CREATES A MESSAGE ON THE MVS CONSOLES TO ADVISE
//*   PRODUCTION CONTROL THE RAECBRCV BANK FILE WAS RECEIVED
//*   FROM ARC, AND POSTS AN EXTERNAL DATASET WITHIN CA7.  THIS	
//*   WILL RELEASE RAECBRCV FOR PROCESSING.                 
//*****************************************************************
//*                                                                     
//STEP0001 EXEC PGM=OP998ARP                                            
//SYSIN  DD   *                                                         
  THE ARC ECB BANK FILE WAS RECEIVED
  JOB RAECBRCV SHOULD NOW RELEASE...                                       
/*                                                                      
//STEP0002 EXEC CA7SVC,PARM='D=RA.RAECBRCV.START,,1'              
//*
//*****************************************************************
//* CONDITION CODE TEST AND NOTIFICATION STEPS                    *
//*****************************************************************
//JS0980  EXEC PGM=IEFBR14,COND=(4,LT)
//JS0990  EXEC PGM=OP999PRP,COND=(0,EQ,JS0980),
//        PARM='+++ JOB FTRAECB FAILED CONTACT PROD CONTROL +++'
//*
//
