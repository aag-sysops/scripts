//RARECNPC JOB (B4),'RELEASE RARECNPC',MSGCLASS=J,CLASS=P
//*
//*****************************************************************   
//*   THIS JCL WILL BE SUBMITTED TO OUR JES2 READER FROM THE FTP      
//*   SERVER, SEAVVFTP.  THIS JOB POSTS AN EXTERNAL DATASET WITHIN
//*   CA7 THIS WILL RELEASE RARENPC FOR PROCESSING.                       
//*****************************************************************   
//*
//STEP0001 EXEC PGM=OP998ARP 
//SYSIN  DD   *              
***********************************************************
*   THE RA SCANNER LIFT FILE WAS RECEIVED FROM            *
*   ACSINC, JOB RACEPNPC SHOULD NOW RELEASE...            *
***********************************************************
/*
//*****************************************************************
//*   THE FOLLOWING STEP WILL POST A DATASET DEPENDENCY
//*         RA.RARECNPC.START
//*****************************************************************
//STEP0002 EXEC CA7SVC,PARM='D=RA.RARECNPC.START,,1'
//*****************************************************************
//*                    
//*****************************************************************
//* CONDITION CODE TEST AND NOTIFICATION STEPS                    *
//*****************************************************************
//JS0980  EXEC PGM=IEFBR14,COND=(4,LT)
//JS0990  EXEC PGM=OP999PRP,COND=(0,EQ,JS0980),
//        PARM='+++ JOB RARECNPC FAILED CONTACT PROD CONTROL +++'
//*
//
