//FFCRTBAI JOB (B4),'RELEASE FFCRTBAI',MSGCLASS=J,CLASS=P                    
//*                                                                     
//*****************************************************************
//*   THIS JCL WILL BE SUBMITTED TO OUR JES2 READER FROM THE FTP 
//*   SERVER, SEAVVDMZFTP.                                         
//*   THIS JOB CREATES A MESSAGE ON THE MVS CONSOLES TO ADVISE
//*   PRODUCTION CONTROL THE FF BAI CRT FEED FILE WAS RECEIVED
//*   AND POSTS AN EXTERNAL DATASET WITHIN CA7.
//*   THIS WILL RELEASE FFCRTBAI FOR PROCESSING.                 
//*****************************************************************
//*                                                                     
//STEP0001 EXEC PGM=OP998ARP                                            
//SYSIN  DD   *                                                         
  THE BAI ACTIVITY FEED FILE WAS RECEIVED FROM 
  JOB FFCRTBAI SHOULD NOW RELEASE...                                   X    
/*                                                                      
//STEP0002 EXEC CA7SVC,PARM='D=FF.FFCRTBAI.START,,1'              
//*
//*****************************************************************
//* CONDITION CODE TEST AND NOTIFICATION STEPS                    *
//*****************************************************************
//JS0980  EXEC PGM=IEFBR14,COND=(4,LT)
//JS0990  EXEC PGM=OP999PRP,COND=(0,EQ,JS0980),
//        PARM='+++ JOB FTFFBAI FAILED CONTACT PROD CONTROL +++'
//*
//
