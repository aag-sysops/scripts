//FFJUBAB5 JOB (B4),'RELEASE FFJUBAB5',MSGCLASS=J,CLASS=P                    
//*                                                                     
//*****************************************************************
//*   THIS JCL WILL BE SUBMITTED TO OUR JES2 READER FROM THE FTP 
//*   SERVER, SEAVVDMZFTP (MAESTRO CPU AGEXTFTP).                       
//*   THIS JOB CREATES A MESSAGE ON THE MVS CONSOLES TO ADVISE
//*   PRODUCTION CONTROL THE FF BOA B5 FEED FILE WAS RECEIVED  
//*   FROM BOFA, AND POSTS AN EXTERNAL DATASET WITHIN CA7.  THIS	
//*   WILL RELEASE FFJUBAB5 FOR PROCESSING.                 
//*****************************************************************
//*                                                                     
//STEP0001 EXEC PGM=OP998ARP                                            
//SYSIN  DD   *                                                         
  THE BANK OF AMERICA BAB5 FEED FILE WAS RECEIVED
  JOB FFJUBAB5  SHOULD NOW RELEASE...
/*                                                                      
//STEP0002 EXEC CA7SVC,PARM='D=FF.FFJUBAB5.START,,1'              
//*
//*****************************************************************
//* CONDITION CODE TEST AND NOTIFICATION STEPS                    *
//*****************************************************************
//JS0980  EXEC PGM=IEFBR14,COND=(4,LT)
//JS0990  EXEC PGM=OP999PRP,COND=(0,EQ,JS0980),
//        PARM='+++ JOB FTFFBAB5 FAILED CONTACT PROD CONTROL +++'
//*
//
