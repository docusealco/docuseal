/*
 * gvl_wrappers.c - Wrapper functions for locking/unlocking the Ruby GVL
 *
 */

#include "pg.h"


#ifndef HAVE_PQSETCHUNKEDROWSMODE
PGresult *PQclosePrepared(PGconn *conn, const char *stmtName){return NULL;}
PGresult *PQclosePortal(PGconn *conn, const char *portalName){return NULL;}
int PQsendClosePrepared(PGconn *conn, const char *stmtName){return 0;}
int PQsendClosePortal(PGconn *conn, const char *portalName){return 0;}
int PQsendPipelineSync(PGconn *conn){return 0;}
int PQcancelBlocking(PGcancelConn *cancelConn){return 0;}
int PQcancelStart(PGcancelConn *cancelConn){return 0;}
PostgresPollingStatusType PQcancelPoll(PGcancelConn *cancelConn){return PGRES_POLLING_FAILED;}
#endif
#ifndef HAVE_PQENTERPIPELINEMODE
int PQpipelineSync(PGconn *conn){return 0;}
#endif

#ifdef ENABLE_GVL_UNLOCK
FOR_EACH_BLOCKING_FUNCTION( DEFINE_GVL_WRAPPER_STRUCT );
FOR_EACH_BLOCKING_FUNCTION( DEFINE_GVL_SKELETON );
#endif
FOR_EACH_BLOCKING_FUNCTION( DEFINE_GVL_STUB );
#ifdef ENABLE_GVL_UNLOCK
FOR_EACH_CALLBACK_FUNCTION( DEFINE_GVL_WRAPPER_STRUCT );
FOR_EACH_CALLBACK_FUNCTION( DEFINE_GVLCB_SKELETON );
#endif
FOR_EACH_CALLBACK_FUNCTION( DEFINE_GVLCB_STUB );
