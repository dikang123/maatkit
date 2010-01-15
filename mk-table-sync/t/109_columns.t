#!/usr/bin/env perl

BEGIN {
   die "The MAATKIT_TRUNK environment variable is not set.  See http://code.google.com/p/maatkit/wiki/Testing"
      unless $ENV{MAATKIT_TRUNK} && -d $ENV{MAATKIT_TRUNK};
   unshift @INC, "$ENV{MAATKIT_TRUNK}/common";
};

use strict;
use warnings FATAL => 'all';
use English qw(-no_match_vars);
use Test::More;

use MaatkitTest;
use Sandbox;
require "$trunk/mk-table-sync/mk-table-sync";

my $output;
my $vp = new VersionParser();
my $dp = new DSNParser();
my $sb = new Sandbox(basedir => '/tmp', DSNParser => $dp);
my $master_dbh = $sb->get_dbh_for('master');
my $slave_dbh  = $sb->get_dbh_for('slave1');

if ( !$master_dbh ) {
   plan skip_all => 'Cannot connect to sandbox master';
}
elsif ( !$slave_dbh ) {
   plan skip_all => 'Cannot connect to sandbox slave';
}
else {
   plan tests => 5;
}

$sb->wipe_clean($master_dbh);
$sb->wipe_clean($slave_dbh);
$sb->create_dbs($master_dbh, [qw(test)]);

# #############################################################################
# Issue 313: Add --ignore-columns (and add tests for --columns).
# #############################################################################
$sb->load_file('master', 'mk-table-sync/t/samples/before.sql');
$output = `$trunk/mk-table-sync/mk-table-sync --print h=127.1,P=12345,u=msandbox,p=msandbox,D=test,t=test3 t=test4`;
# This test changed because the row sql now does ORDER BY key_col (id here)
is($output, <<EOF,
UPDATE `test`.`test4` SET `name`='001' WHERE `id`=1 LIMIT 1;
UPDATE `test`.`test4` SET `name`=51707 WHERE `id`=15034 LIMIT 1;
EOF
  'Baseline for --columns: found differences');

$output = `$trunk/mk-table-sync/mk-table-sync --columns=id --print h=127.1,P=12345,u=msandbox,p=msandbox,D=test,t=test3 t=test4`;
is($output, "", '--columns id: found no differences');

$output = `$trunk/mk-table-sync/mk-table-sync --ignore-columns name --print h=127.1,P=12345,u=msandbox,p=msandbox,D=test,t=test3 t=test4`;
is($output, "", '--ignore-columns name: found no differences');

$output = `$trunk/mk-table-sync/mk-table-sync --ignore-columns id --print h=127.1,P=12345,u=msandbox,p=msandbox,D=test,t=test3 t=test4`;
# This test changed for the same reason as above.
is($output, <<EOF,
UPDATE `test`.`test4` SET `name`='001' WHERE `id`=1 LIMIT 1;
UPDATE `test`.`test4` SET `name`=51707 WHERE `id`=15034 LIMIT 1;
EOF
  '--ignore-columns id: found differences');

$output = `$trunk/mk-table-sync/mk-table-sync --columns name --print h=127.1,P=12345,u=msandbox,p=msandbox,D=test,t=test3 t=test4`;
# This test changed for the same reason as above.
is($output, <<EOF,
UPDATE `test`.`test4` SET `name`='001' WHERE `id`=1 LIMIT 1;
UPDATE `test`.`test4` SET `name`=51707 WHERE `id`=15034 LIMIT 1;
EOF
  '--columns name: found differences');

# #############################################################################
# Done.
# #############################################################################
$sb->wipe_clean($master_dbh);
$sb->wipe_clean($slave_dbh);
exit;