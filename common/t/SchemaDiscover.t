#!/usr/bin/perl

# This program is copyright 2008 Percona Inc.
# Feedback and improvements are welcome.
#
# THIS PROGRAM IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, version 2; OR the Perl Artistic License.  On UNIX and similar
# systems, you can issue `man perlgpl' or `man perlartistic' to read these
# licenses.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place, Suite 330, Boston, MA  02111-1307  USA.

use strict;
use warnings FATAL => 'all';

use Test::More tests => 5;
use English qw(-no_match_vars);

use DBI;

require '../SchemaDiscover.pm';
require '../MySQLInstance.pm';
require '../DSNParser.pm';
require '../MySQLDump.pm';
require '../Quoter.pm';
require '../TableParser.pm';

use Data::Dumper;
$Data::Dumper::Indent    = 1;
$Data::Dumper::Quotekeys = 0;

# #############################################################################
# First, setup a MySQLInstance... 
# #############################################################################
my $cmd_01 = '/usr/sbin/mysqld --defaults-file=/tmp/5126/my.sandbox.cnf --basedir=/usr --datadir=/tmp/5126/data --pid-file=/tmp/5126/data/mysql_sandbox5126.pid --skip-external-locking --port=5126 --socket=/tmp/5126/mysql_sandbox5126.sock --long-query-time=3';
my $myi = new MySQLInstance($cmd_01);
my $dsn = $myi->get_DSN();
$dsn->{u} = 'msandbox';
$dsn->{p} = 'msandbox';
my $dbh;
my $dp = new DSNParser();
eval {
   $dbh = $dp->get_dbh($dp->get_cxn_params($dsn));
};
if ( $EVAL_ERROR ) {
   chomp $EVAL_ERROR;
   print "Cannot connect to " . $dp->as_string($dsn)
         . ": $EVAL_ERROR\n\n";
}
$myi->load_sys_vars($dbh);

# #############################################################################
# Now, begin checking SchemaDiscover
# #############################################################################
my $d = new MySQLDump();
my $q = new Quoter();
my $t = new TableParser();
my $params = { dbh         => $dbh,
               MySQLDump   => $d,
               Quoter      => $q,
               TableParser => $t,
             };

my $sd = new SchemaDiscover($params);
isa_ok($sd, 'SchemaDiscover');

ok(exists $sd->{dbs}->{test},     'test db exists'      );
ok(exists $sd->{dbs}->{mysql},    'mysql db exists'     );
ok(exists $sd->{counts}->{TOTAL}, 'TOTAL counts exists' );

$sd->discover_triggers_routines_events();
my @expect_tre_01 = ('sakila func 3', 'sakila proc 3');
is_deeply(
   \@{ $sd->{trigs_routines_events} },
   \@expect_tre_01,
   'discover_triggers_routines_events'
);

# print Dumper($sd);

$dbh->disconnect() if defined $dbh;

exit;
