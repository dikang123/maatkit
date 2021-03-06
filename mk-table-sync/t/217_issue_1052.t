#!/usr/bin/env perl

BEGIN {
   die "The MAATKIT_WORKING_COPY environment variable is not set.  See http://code.google.com/p/maatkit/wiki/Testing"
      unless $ENV{MAATKIT_WORKING_COPY} && -d $ENV{MAATKIT_WORKING_COPY};
   unshift @INC, "$ENV{MAATKIT_WORKING_COPY}/common";
};

use strict;
use warnings FATAL => 'all';
use English qw(-no_match_vars);
use Test::More;

use MaatkitTest;
use Sandbox;
require "$trunk/mk-table-sync/mk-table-sync";

my $dp = new DSNParser(opts=>$dsn_opts);
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
   plan tests => 1;
}

my $output;
my @args = ('--sync-to-master', 'h=127.1,P=12346,u=msandbox,p=msandbox',
            qw(-d issue_1052 --print));

# #############################################################################
# Issue 1052: mk-table-sync inserts "0x" instead of "" for empty varchar column
# #############################################################################

# Re-using this table for this issue.  It has 100 pk rows.
$sb->load_file('master', 'mk-table-sync/t/samples/issue_1052.sql');
wait_until(
   sub {
      my $row;
      eval {
         $row = $slave_dbh->selectrow_hashref("select * from issue_1052.t");
      };
      return 1 if $row;
   },
);

$output = output(
   sub { mk_table_sync::main(@args) },
   trf => \&remove_traces,
);

is(
   $output,
"REPLACE INTO `issue_1052`.`t`(`opt_id`, `value`, `option`, `desc`) VALUES ('2', '', 'opt2', 'something else');
",
   "Insert '' for blank varchar"
);

# #############################################################################
# Done.
# #############################################################################
$sb->wipe_clean($master_dbh);
exit;
