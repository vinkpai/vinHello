/* Formatted on 2008/09/15 15:36 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY apps.xxcca_caf_main_consolid_pkg
AS
   /*
    REM ============================================================================================================
    REM $Header:   /apps/pvcs/archive/bv/xxcca/11.5.0/admin/sql/XXCCACAFMAIN_PB.sql_v   1.4   10 Sep 2008 11:57:12   akishore  $
    REM Package Name    : xxcca_caf_main_consolid_pkg
    REM PVCSFile Name   : XXCCACAFMAIN_PB.sql
    REM Purpose         :    REM Purpose         : This purpose of this package is to call  all programs lke Creat Batches, Load and Consolidation
    REM
    REM
    REM  CALLING FORMAT : start $XXCCA_TOP/admin/sql/XXCCACAFMAIN_PB.sql
    REM
    REM  History
    REM  Date          Name            Changes Notes
    REM  -----------   --------------  -------------------------------------------
    REM  01-Apr-2008   Vin Pai        Initial version
    REM  08-SEP-2008   ayarragu       Issue Id - 252205
    REM  15-SEP-2008   ayarragu       Issue ID - 252816
    REM
    REM ============

    */
     
   PROCEDURE main (
      p_errbuf                   OUT      VARCHAR2,
      p_retcode                  OUT      NUMBER,
      p_request_id               IN       NUMBER,
      p_match_method             IN       VARCHAR2,
      p_within_business_entity   IN       VARCHAR2 DEFAULT 'Y',
      p_business_entity          IN       VARCHAR2,
      p_recent_customer          IN       NUMBER DEFAULT 60,
      p_recent_stats             IN       NUMBER DEFAULT 7,
      --Issue Id - 252205
      p_country                  IN       VARCHAR2,
      p_customer_number          IN       VARCHAR2 DEFAULT NULL,
      p_cust_name_prefix         IN       VARCHAR2 DEFAULT NULL,
      p_retry_records            IN       VARCHAR2 DEFAULT 'N',
      p_sa_threshold             IN       NUMBER DEFAULT 0,
      p_ib_threshold             IN       NUMBER DEFAULT 0,
      p_qot_threshold            IN       NUMBER DEFAULT 0,
                                                          --Issue ID - 252816
      p_max_batches              IN       NUMBER DEFAULT 0,
      p_max_accounts             IN       NUMBER DEFAULT 0,
      p_max_ib_updates           IN       NUMBER DEFAULT 0,
      p_bid_notif_email_addr     IN       VARCHAR2,
      p_report_email             IN       VARCHAR2 DEFAULT NULL
   )
   AS
      l_request_id      NUMBER;
      l_argument_text   VARCHAR2 (2000);
      l_user_id         NUMBER;
      l_sql_point       NUMBER;
      l_caf_proc_name   VARCHAR2 (100)  := 'xxcca_caf_main_consolid_pkg.main';
   BEGIN
      p_errbuf := NULL;
      p_retcode := NULL;
      l_user_id := fnd_global.user_id;
      l_sql_point := 100;
      fnd_file.put_line (fnd_file.LOG,
                            l_caf_proc_name
                         || 'CC PGM Started at '
                         || TO_CHAR (SYSDATE, 'MM/DD/YYYY HH24:MI:SS')
                        );
      l_argument_text :=
            ' P_request_id= '
         || p_request_id
         || CHR (10)
         || ' P_MATCH_METHOD= '
         || p_match_method
         || CHR (10)
         || ' P_WITHIN_BUSINESS_ENTITY= '
         || p_within_business_entity
         || CHR (10)
         || ' P_BUSINESS_ENTITY= '
         || p_business_entity
         || CHR (10)
         || ' P_COUNTRY= '
         || p_country
         || CHR (10)
         || ' P_RECENT_CUSTOMER= '
         || p_recent_customer
         || CHR (10)
         || ' P_RECENT_STATS= '
         || p_recent_stats
         || CHR (10)
         || ' P_CUSTOMER_NUMBER= '
         || p_customer_number
         || CHR (10)
         || ' P_CUST_NAME_PREFIX= '
         || p_cust_name_prefix
         || CHR (10)
         || ' P_RETRY_RECORDS= '
         || p_retry_records
         || CHR (10)
         || ' P_SA_Threshold= '
         || p_sa_threshold
         || CHR (10)
         || ' P_IB_Threshold= '
         || p_ib_threshold
         || CHR (10)
         || ' P_MAX_BATCHES= '
         || p_max_batches
         || CHR (10)
         || ' P_MAX_ACCOUNTS= '
         || p_max_accounts
         || CHR (10)
         || ' P_MAX_IB_UPDATES= '
         || p_max_ib_updates;
      fnd_file.put_line (fnd_file.LOG,
                            ' Arguments to the cc pgm are '
                         || CHR (10)
                         || l_argument_text
                        );

      IF p_request_id IS NULL
      THEN
         SELECT cca.xxcca_mrg_request_s.NEXTVAL
           INTO l_request_id
           FROM DUAL;
      ELSE
         l_request_id := p_request_id;
      END IF;

      -- Calling concurrent program to create customer batches.
      xxcca_caf_batch_util_pkg.main (p_errbuf,
                                     p_retcode,
                                     l_request_id,
                                     p_match_method,
                                     p_within_business_entity,
                                     p_business_entity,
                                     p_country,
                                     p_recent_customer,
                                     p_recent_stats,
                                     p_customer_number,
                                     p_cust_name_prefix,
                                     p_retry_records,
                                     p_sa_threshold,
                                     p_ib_threshold,
                                     p_qot_threshold,
                                     p_max_batches,
                                     p_max_accounts,
                                     p_max_ib_updates
                                    );

      IF p_errbuf IS NOT NULL
      THEN
         p_retcode := 2;
         fnd_file.put_line (fnd_file.LOG,
                            ' Create Batches Failed ' || p_errbuf
                           );
         RETURN;
      END IF;

              -- Calling concurrent program to load child entities mapping tables for
      -- all batches that were created as part of this run.
      xxcca_stc_load_pkg.main (p_errbuf,
                               p_retcode,
                               l_request_id,
                               p_recent_customer,
                               p_qot_threshold,
                               p_sa_threshold,
                               p_ib_threshold ,
                               p_retry_records,
                                112,
                               112 
                              );

      IF p_errbuf IS NOT NULL
      THEN
         p_retcode := 2;
         fnd_file.put_line (fnd_file.LOG, ' Load Pm Failed ' || p_errbuf);
         RETURN;
      END IF;

      -- Calling concurrent program to consolidate duplicate customers and
      -- copy child  entities into corresponding Keeper customer.
      xxcca_stc_consold_pkg.main (p_errbuf,
                                  p_retcode,
                                  l_request_id,
                                  p_retry_records,
                                  112,
                                  112,
                                  1,
                                  p_bid_notif_email_addr,
                                  'Y'
                                 );
                                 
        

      IF p_errbuf IS NOT NULL
      THEN
         p_retcode := 2;
         fnd_file.put_line (fnd_file.LOG,
                            ' Consolidation Pgm Failed ' || p_errbuf
                           );
         RETURN;
      END IF;

      IF p_report_email IS NOT NULL
      THEN
         xxcca_caf_stat_reports_pkg.ins_caf_statreps_by_request
                                                              (p_errbuf,
                                                               p_retcode,
                                                               l_request_id,
                                                               p_report_email
                                                              );
      END IF;
   END main;
END xxcca_caf_main_consolid_pkg;
/