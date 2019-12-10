#!/usr/bin/perl -w
use ServiceNow;
use ServiceNow::Configuration;
use ServiceNow::GlideRecord;
use ServiceNow::WSResult;
use Test::Harness;

@test_files = ('Tests/TestCreateTask.pl',
               'Tests/TestAppendJournal.pl',
               'Tests/TestApprove.pl',
               'Tests/TestCloseIncident.pl',
               'Tests/TestCloseTicket.pl',
               'Tests/TestCreateNotification.pl',
               'Tests/TestCreateIncident.pl',
               'Tests/TestCreateRequestedItem.pl',
               'Tests/TestCreateTicket.pl',
               'Tests/TestQueryApproval.pl',
               'Tests/TestQueryFields.pl',
               'Tests/TestQueryIncident.pl',
               'Tests/TestQueryJournal.pl',
               'Tests/TestQueryRequestedItem.pl',
               'Tests/TestQueryTask.pl',
               'Tests/TestQueryTicket.pl',
               'Tests/TestReassignTicket.pl',
               'Tests/TestReassignIncident.pl',
               'Tests/TestReassignTask.pl',
               'Tests/TestReopenIncident.pl',
               'Tests/TestReopenTicket.pl',
               'Tests/TestReopenTask.pl',
               'Tests/TestUpdateIncident.pl',
               'Tests/TestUpdateTask.pl',
               'Tests/TestUpdateTicket.pl',
               'Tests/TestQueryRequest.pl',
               'Tests/TestGlideRecord.pl',
               'Tests/TestAttachment.pl'
               );

runtests(@test_files);