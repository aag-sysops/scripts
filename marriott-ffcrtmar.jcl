//FFCRTMAR JOB (B4),'RELEASE FFCRTMAR',MSGCLASS=J,CLASS=P                    
//*                                                                     
//*****************************************************************
//*   THIS JCL WILL BE SUBMITTED TO OUR JES2 READER FROM THE FTP 
//*   SERVER, SEAVVDMZFTP.                                         
//*   THIS JOB CREATES A MESSAGE ON THE MVS CONSOLES TO ADVISE
//*   PRODUCTION CONTROL THE FF MARRIOTT CRT FEED FILE WAS RECEIVED
//*   FROM MARRIOTT, AND POSTS AN EXTERNAL DATASET WITHIN CA7.
//*   THIS WILL RELEASE FFCRTC3 FOR PROCESSING.                 
//*****************************************************************
//*                                                                     
//STEP0001 EXEC PGM=OP998ARP                                            
//SYSIN  DD   *                                                         
  THE MARRIOTT CRT FEED FILE WAS RECEIVED
  JOB FFCRTMAR SHOULD NOW RELEASE...
/*
//STEP0002 EXEC CA7SVC,PARM='D=FF.FFCRTMAR.START,,1'              
//*
//*****************************************************************
//* CONDITION CODE TEST AND NOTIFICATION STEPS                    *
//*****************************************************************
//JS0980  EXEC PGM=IEFBR14,COND=(4,LT)
//JS0990  EXEC PGM=OP999PRP,COND=(0,EQ,JS0980),
//        PARM='+++ JOB FFCRTMAR FAILED CONTACT PROD CONTROL +++'
//
