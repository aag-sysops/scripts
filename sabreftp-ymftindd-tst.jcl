//YMFTINDD JOB (B4),'YM XMIT END',MSGCLASS=J,CLASS=P
//*
//**********************************************************************
//*    THIS JCL WILL BE SUBMITTED TO OUR JES2 READER BY AN EXIT WITHIN
//*    THE FTP APPLICATION PROCESSING AT AMRIS IN TULSA, UPON THE
//*    SUCCESSFUL TRANSMISSION OF:
//*
//*    DSN = PROD.YMRECEIV.RECEIVE.YLDDATA
//*
//*    THIS JOB WILL CREATE A WTO MESSAGE ON THE MVS CONSOLES IN THE
//*    COMPUTER ROOM TO ADVISE THE OPERATORS THAT THE FILE HAS ARRIVED
//*    AND THEN POST AN EXTERNAL DATASET WITHIN CA7. THIS WILL CAUSE
//*    CA7 TO RELEASE THE FOLLOWING JOB FOR PROCESSING.
//*
//*    JOB = YMRECDLY OR YMWEEKLY
//*
//**********************************************************************
//*
//STEP0002 EXEC CA7SVC,PARM='D=PROG.YM.YMRECEIV.SABRE.START,,1'
//*
//OPABEND  EXEC PROC=OPABEND,JOBNAME=YNFTINDD
