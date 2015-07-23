
-- remove output if it already exists, to ensure idempotency if job is rerun 
fs -mkdir -p $LOGOUTPUT;
fs -touchz $LOGOUTPUT/_tmp;
fs -rmr -skipTrash $LOGOUTPUT;

-- load raw stats from appropriate partition 
HRRAWDATA = LOAD '$LOGINPUT' USING PigStorage(';') AS (MANDT:chararray, PERNR:chararray, SUBTY:chararray, OBJPS:chararray, SPRPS:chararray, ENDDA:chararray, BEGDA:datetime, SEQNR:chararray, AEDTM:chararray, UNAME:chararray, DAR01:chararray, DAT01:chararray, DAR02:chararray, DAT02:chararray, DAR03:chararray, DAT03:chararray, DAR04:chararray, DAT04:chararray, DAR05:chararray, DAT05:chararray, DAR06:chararray, DAT06:chararray, DAR07:chararray, DAT07:chararray, DAR08:chararray, DAT08:chararray, DAR09:chararray, DAT09:chararray, DAR10:chararray, DAT10:chararray, DAR11:chararray, DAT11:chararray, DAR12:chararray, DAT12:chararray); 

-- Filter the result set to the current 
HRDATAFILTERED = FILTER HRRAWDATA BY BEGDA >  ToDate('2005-01-01');

-- save results into appropriate partition 
STORE HRDATAFILTERED INTO '$LOGOUTPUT' USING PigStorage (','); 


