package Subscription::Product;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';
use Date::Calc qw (Today Add_Delta_Days);
use Data::Dumper;


sub display{
    my $self = shift;
    $self->stash(
            product => $self->all_products()
    );
}



1;