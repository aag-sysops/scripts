//FFFTPDID JOB (B4),'FF XMIT END',MSGCLASS=J,CLASS=P
//*
//**********************************************************************
//*    THIS JCL WILL BE SUBMITTED TO OUR JES2 READER BY AN EXIT WITHIN
//*    THE FTP APPLICATION PROCESSING AT AMRIS IN TULSA, UPON THE
//*    SUCCESSFUL TRANSMISSION OF:
//*
//*    DSN = PROD.RECEIVE.FFRECPDI.PDIDATA.SABRE.COMP
//*
//*    THIS JOB WILL CREATE A WTO MESSAGE ON THE MVS CONSOLES IN THE
//*    COMPUTER ROOM TO ADVISE THE OPERATORS THAT THE FILE HAS ARRIVED
//*    AND THEN POST AN EXTERNAL DATASET WITHIN CA7. THIS WILL CAUSE
//*    CA7 TO RELEASE THE FOLLOWING JOB FOR PROCESSING.
//*
//*    JOB = FFRECPDI
//*********************************************************************
//* MODIFICATIONS:                                                    *
//*                                                                   *
//* 07-28-05  KHOWELL  ADDED JOB STEP TO COPY COMPRESSED FILE INTO A  *
//*                    GDG BACKUP DATA SET CLUSTER                    *
//* 09-27-05  GFOSTER  RENUMBERED JOB STEPS, ADDED DATASET POINTERS,  *
//*                    CLARIFIED COMMENTS, ADDED DSCB.MODEL AND DSORG *
//*                    CODING.                                        *
//* 12-12-06  DLIEBRI  MOVED COPY & DECOMP STEP TO FFRECPDI           *
//*********************************************************************
//***************************************************************
//*  SEND MESSAGE TO CONSOLE THAT FFRECPDI IS AVAILABLE TO RUN  *
//***************************************************************
//JS0020   EXEC PGM=OP998ARP,COND=(0,NE)
//SYSIN  DD *
MSG   THE FREQUENT FLYER PDI DATA HAS ARRIVED
MSG   FROM SABRE EDS. FFRECPDI WILL NOW RUN FROM CA7.                  X
/*
//******************************************
//*  CREATE THE FFRECPDI "TAG" START FILE  *
//******************************************
//JS0010   EXEC CA7SVC,PARM='D=FF.FFRECPDI.SABRE.START,,1'
//*
//OPABEND  EXEC PROC=OPABEND,JOBNAME=FFFTPDID
