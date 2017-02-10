//FTRAARC JOB (B4),'RELEASE RARECARC',MSGCLASS=J,CLASS=P                    
//*                                                                     
//*****************************************************************
//*   THIS JCL WILL BE SUBMITTED TO OUR JES2 READER FROM THE FTP 
//*   SERVER, SEAVVFTP.                                         
//*   THIS JOB CREATES A MESSAGE ON THE MVS CONSOLES TO ADVISE
//*   PRODUCTION CONTROL THE RARECARC BANK FILES WERE RECEIVED
//*   FROM ARC, AND POSTS AN EXTERNAL DATASET WITHIN CA7.  THIS	
//*   WILL RELEASE RARECARC FOR PROCESSING.                 
//*****************************************************************
//*                                                                     
//STEP0001 EXEC PGM=OP998ARP                                            
//SYSIN  DD   *                                                         
  THE ARC BANK FILES WERE RECEIVED
  JOB RARECARC SHOULD NOW RELEASE...                                       
/*                                                                      
//STEP0002 EXEC CA7SVC,PARM='D=RA.RARECARC.START,,1'              
//*
//*****************************************************************
//* CONDITION CODE TEST AND NOTIFICATION STEPS                    *
//*****************************************************************
//JS0980  EXEC PGM=IEFBR14,COND=(4,LT)
//JS0990  EXEC PGM=OP999PRP,COND=(0,EQ,JS0980),
//        PARM='+++ JOB FTFFALC FAILED CONTACT PROD CONTROL +++'
//*
//
