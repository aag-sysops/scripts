//FFCRTBD JOB (B4),'RELEASE FFCRTBD',MSGCLASS=J,CLASS=P                    
//*                                                                     
//*****************************************************************
//*   THIS JCL WILL BE SUBMITTED TO OUR JES2 READER FROM THE FTP 
//*   SERVER, SEAVVDMZFTP.                                         
//*   THIS JOB CREATES A MESSAGE ON THE MVS CONSOLES TO ADVISE
//*   PRODUCTION CONTROL THE FF BOFD DEBIT CARD FILE WAS RECEIVED  
//*   FROM B OF A, AND POSTS AN EXTERNAL DATASET WITHIN CA7.  THIS	
//*   WILL RELEASE FFCRTBD FOR PROCESSING.                 
//*****************************************************************
//*                                                                     
//STEP0001 EXEC PGM=OP998ARP                                            
//SYSIN  DD   *                                                         
  THE BANK OF AMERICA DEBIT CARD FILE WAS RECEIVED
  JOB FFCRTBD SHOULD NOW RELEASE...                                    X    
/*                                                                      
//STEP0002 EXEC CA7SVC,PARM='D=FF.FFCRTBD.START,,1'              
//*
//*****************************************************************
//* CONDITION CODE TEST AND NOTIFICATION STEPS                    *
//*****************************************************************
//JS0980  EXEC PGM=IEFBR14,COND=(4,LT)
//JS0990  EXEC PGM=OP999PRP,COND=(0,EQ,JS0980),
//        PARM='+++ JOB FFCRTBD FAILED CONTACT PROD CONTROL +++'
//*
//
