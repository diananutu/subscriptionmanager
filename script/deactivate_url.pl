use strict;
use warnings;

use DBI;
use Data::Dumper;
use DateTime;

my $dbh = DBI->connect('dbi:mysql:subscription','root','123-qwe');

my $date = DateTime->now();

my $sql = "SELECT hid, active from password_hashes where expiry_date < ?;";
my $update = "UPDATE password_hashes SET active = 0 where hid = ? limit 1;";

my $st = $dbh->prepare($sql);
my $st_up = $dbh->prepare($update);
$st->execute($date);

while ( my $row = $st->fetchrow_hashref()) {
    $st_up->execute($row->{hid});   
}