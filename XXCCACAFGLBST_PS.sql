CREATE OR REPLACE PACKAGE XXCCA_CAF_GLOBAL_STATS_PKG 

AS
 /*
 REM ============================================================================================================
 REM $Header:    
 REM Package Name    : XXCCA_CAF_GLOBAL_STATS_PKG 
 REM PVCSFile Name   : XXCCACAFGLBST_PS.sql
 REM Purpose         : This purpose of this package is to gather Global Stats for all
 REM			Customer, Address and Site Use records
 REM                    
 REM  CALLING FORMAT : start $XXCCA_TOP/admin/sql/XXCCACAFGLBST_PS.sql
 REM
 REM  History
 REM  Date          Name            Changes Notes
 REM  -----------   --------------  -------------------------------------------
 REM  01-Apr-2008   Vin Pai        Initial version
 REM
 REM
 REM ============
 
 */ 
--populate stats tables with customer,site use and adress data
 PROCEDURE gather_xn_stats (
       errbuf              OUT NOCOPY   VARCHAR2,
       retcode             OUT NOCOPY   NUMBER,
       p_run_in_parallel                VARCHAR2 DEFAULT 'Y',
       p_recent_customer                NUMBER DEFAULT 60,
        p_recent_ib_data		NUMBER DEFAULT 7,
        p_enable_archiving       varchar2 default 'N'
    );
   
   PROCEDURE update_final (
         errbuf              OUT NOCOPY   VARCHAR2,
         retcode             OUT NOCOPY   NUMBER,
         p_recent_customer                NUMBER DEFAULT 60,
        p_enable_archiving       varchar2 default 'N'
    );
      PROCEDURE update_ib_cnts (
          errbuf    OUT NOCOPY   VARCHAR2,
          retcode   OUT NOCOPY   NUMBER
   );
                                        
END XXCCA_CAF_GLOBAL_STATS_PKG;
/
