#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use English qw(-no_match_vars);
use Test::More tests => 9;

require "../WatchServer.pm";

use Data::Dumper;
$Data::Dumper::Indent    = 1;
$Data::Dumper::Sortkeys  = 1;
$Data::Dumper::Quotekeys = 0;

# ###########################################################################
# Test parsing vmstat output.
# ###########################################################################

my $vmstat_output ="procs -----------memory---------- ---swap-- -----io---- -system-- ----cpu----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa
  1  0      0 664668 130452 566588    0    0     8    11  237  351  5  1 93  1
";

is_deeply(
   WatchServer::_parse_vmstat($vmstat_output),
   {
      b     => '0',
      r     => '1',
      swpd  => '0',
      free  => '664668',
      buff  => '130452',
      cache => '566588',
      si    => '0',
      so    => '0',
      bi    => '8',
      bo    => '11',
      in    => '237',
      cs    => '351',
      us    => '5',
      sy    => '1',
      id    => '93',
      wa    => '1'
   },
   'Parse vmstat output'
);

# ###########################################################################
# Test watching loadavg (uptime).
# ###########################################################################

my $uptime = ' 14:14:53 up 23:59,  5 users,  load average: 0.08, 0.05, 0.04';
sub get_uptime { return $uptime };

my $w = new WatchServer(
   params => 'loadavg:1:=:0.08',
);
$w->set_callbacks( uptime => \&get_uptime );

is(
   $w->ok(),
   1,
   'Loadavg 1 min'
);

$w = new WatchServer(
   params => 'loadavg:5:=:0.05',
);
$w->set_callbacks( uptime => \&get_uptime );

is(
   $w->ok(),
   1,
   'Loadavg 5 min'
);

$w = new WatchServer(
   params => 'loadavg:15:=:0.04',
);
$w->set_callbacks( uptime => \&get_uptime );

is(
   $w->ok(),
   1,
   'Loadavg 15 min'
);

# ###########################################################################
# Test watching vmstat.
# ###########################################################################

sub get_vmstat { return $vmstat_output};

$w = new WatchServer(
   params => 'vmstat:free:>:0',
);
$w->set_callbacks( uptime => \&get_vmstat );

is(
   $w->ok(),
   1,
   'vmstat free'
);

$w = new WatchServer(
   params => 'vmstat:swpd:=:0',
);
$w->set_callbacks( uptime => \&get_vmstat );

is(
   $w->ok(),
   1,
   'vmstat swpd'
);

# ###########################################################################
# Live tests.
# ###########################################################################

# This test may fail because who knows what the loadavg is like on
# your box right now.

$w = new WatchServer(
   params => 'loadavg:15:>:0.00'
);

is(
   $w->ok(),
   1,
   'Loadavg 15 min > 0.00 (live)'
);


$w = new WatchServer(
   params => 'vmstat:cache:>:1',
);

is(
   $w->ok(),
   1,
   'vmstat cache > 1 (live)'
);

# #############################################################################
# Done.
# #############################################################################
my $output = '';
{
   local *STDERR;
   open STDERR, '>', \$output;
   $w->_d('Complete test coverage');
}
like(
   $output,
   qr/Complete test coverage/,
   '_d() works'
);
exit;
