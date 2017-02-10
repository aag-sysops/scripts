//RAINLPLD JOB (B4),'RELEASE RAINLPLD',MSGCLASS=J,CLASS=P
//*
//*****************************************************************
//*   THE FOLLOWING STEP WILL POST A DATASET DEPENDENCY
//*         RA.RASISRVC.START
//*****************************************************************
//STEP0002 EXEC CA7SVC,PARM='D=RA.RASISRCV.START,,1'
//*****************************************************************
//*                    
//*****************************************************************
//* CONDITION CODE TEST AND NOTIFICATION STEPS                    *
//*****************************************************************
//JS0980  EXEC PGM=IEFBR14,COND=(4,LT)
//JS0990  EXEC PGM=OP999PRP,COND=(0,EQ,JS0980),
//        PARM='+++ JOB RAINLPLD FAILED CONTACT PROD CONTROL +++'
//*
//
