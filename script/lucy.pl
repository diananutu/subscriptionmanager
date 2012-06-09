use strict;
use warnings;

use DBI;
use Lucy::Plan::Schema;
use Lucy::Plan::FullTextType;
use Lucy::Analysis::PolyAnalyzer;
use Lucy::Index::Indexer;
use Lucy::Document::Doc;
use File::Basename 'dirname';
use File::Spec::Functions qw/catdir splitdir/;
use Data::Dumper;

my @base = (splitdir(dirname(__FILE__)), '..');
my $dbh = DBI->connect('dbi:mysql:subscription','root','123-qwe'); 
my $sql = "SELECT uid, email, name,country,county, signup_date from users;";
my $subs = "SELECT *, t2.name from subscriptions AS t1 JOIN products AS t2 ON t1.pid=t2.pid where uid=? order by start_date DESC;";

my $st = $dbh->prepare($sql);
my $st2 = $dbh->prepare($subs);
$st->execute();
my $schema = Lucy::Plan::Schema->new;
my $polyanalyzer = Lucy::Analysis::PolyAnalyzer->new(
    language => 'en',
);
my $type = Lucy::Plan::FullTextType->new(
    analyzer => $polyanalyzer,
);

$schema->spec_field( name => 'uid',   type => $type );
$schema->spec_field( name => 'email', type => $type );
$schema->spec_field( name => 'name',   type => $type );
$schema->spec_field( name => 'country', type => $type );
$schema->spec_field( name => 'county', type => $type );
$schema->spec_field( name => 'signup_date', type => $type );
$schema->spec_field( name => 'start_date', type => $type );
$schema->spec_field( name => 'end_date', type => $type );
$schema->spec_field( name => 'renew', type => $type );
$schema->spec_field( name => 'prod_name', type => $type );
$schema->spec_field( name => 'active', type => $type );

my $path_to_index = join('/',@base,'index');

my $indexer = Lucy::Index::Indexer->new(
        schema => $schema,   
        index  => $path_to_index,
        create => 1,
    );

while ( my $row = $st->fetchrow_hashref()) {
  
    $st2->execute($row->{uid});
    my $row2 = $st2->fetchrow_hashref();

    
    my $doc = Lucy::Document::Doc->new(
                fields => {uid => $row->{uid},
                           email => $row->{email},
                           name => $row->{name},
                           country => $row->{country},
                           county => $row->{county},
                           signup_date => $row->{signup_date},
                           start_date => $row2->{start_date},
                           end_date => $row2->{end_date},
                           renew => $row2->{renew},
                           prod_name => $row2->{name},
                           active => $row2->{active_sub},                        
                           });
    
    $indexer->add_doc($doc);
}

$indexer->commit();
