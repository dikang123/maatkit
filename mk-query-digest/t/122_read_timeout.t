#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use English qw(-no_match_vars);
use Test::More tests => 2;

require '../../common/MaatkitTest.pm';
MaatkitTest->import(qw(wait_for));

# #########################################################################
# Issue 226: Fix mk-query-digest signal handling
# #########################################################################
diag(`rm -rf /tmp/mqd.pid`);

my ($start, $end, $waited);
my $timeout = wait_for(
   sub {
      $start = time;
      `../mk-query-digest --read-timeout 2 --pid /tmp/mqd.pid 2>/dev/null`;
      return;
   },
   4,
);
$end    = time;
$waited = $end - $start;
if ( $timeout ) {
   # mqd ran longer than --read-timeout
   my $pid = `cat /tmp/mqd.pid`;
   `kill $pid`;
}

ok(
   $waited >= 2 && $waited <= 3,
   "--read-timeout waited $waited seconds reading STDIN"
);

diag(`rm -rf /tmp/mqd.pid`);
diag(`rm -rf /tmp/mqd.fifo; mkfifo /tmp/mqd.fifo`);
system('samples/write-to-fifo.pl /tmp/mqd.fifo 4 &');

$timeout = wait_for(
   sub {
      $start = time;
      `../mk-query-digest --read-timeout 2 --pid /tmp/mqd.pid /tmp/mqd.fifo`;
      return;
   },
   4,
);
$end    = time;
$waited = $end - $start;
if ( $timeout ) {
   # mqd ran longer than --read-timeout
   my $pid = `cat /tmp/mqd.pid`;
   `kill $pid`;
}

ok(
   $waited >= 2 && $waited <= 3,
   "--read-timeout waited $waited seconds reading a file"
);

diag(`rm -rf /tmp/mqd.pid`);
diag(`rm -rf /tmp/mqd.fifo`);

# #############################################################################
# Done.
# #############################################################################
exit;