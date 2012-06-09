package Subscription::Admin;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';

use Data::Page;
use DateTime;
use DateTime::Format::Strptime;
use YAML::Tiny;
use Lucy::Search::IndexSearcher;
use Lucy::Search::QueryParser;
use Lucy::Search::TermQuery;
use Lucy::Search::ANDQuery;
use FileHandle;
use DateTime::Format::MySQL;

=head1 NAME

    Subscription::Admin - module for subscripton application, admin part
=cut    

=head2 index
    sub index {
        
    }
    Displays the home page for admin
=cut

sub index {
    my $self = shift;
}

=head2 user_managemet
    sub user_management{
        
    }
    
    Takes all users from database and sends them to template.
=cut

sub user_management {
    my $self = shift;

    my $model      = $self->app->model;
    my $user_page  = $self->param('page')            || 1;
    my $admin_page = $self->param('apage')           || 1;
    my $associates = $self->param('view_associates') || '';
    my $order_by   = $self->param('order_by')        || 'uid';
    my $order      = $self->param('dir')             || 'ASC';
    my $subscribers= $self->param('subscribers')     || '';
    
    if ( $associates eq '' && $subscribers eq '' ) {

        my $users = $model->resultset('User')->search( { access => 'user' },
            { rows => 10, page => $user_page, order_by => "$order_by $order" } );
        my $admins = $model->resultset('User')->search( { access => 'admin' },
            { rows => 10, page => $admin_page, order_by => "$order_by $order" } );

        my $user_pages  = $users->pager()->total_entries()
                        / $users->pager()->entries_per_page()
                        + 1;
        
        my $admin_pages = $admins->pager()->total_entries()
                        / $admins->pager()->entries_per_page()
                        + 1;

        my $subscription_details = $self->_subscription_details($users);

        $self->stash(
            users         => $users->reset,
            admins        => $admins,
            user_pages    => $user_pages,
            admin_pages   => $admin_pages,
            subscriptions => $subscription_details,
            user_page     => $user_page,
            admin_page    => $admin_page,
            associates    => 0,
            subscribers   => 0,
            order_by      => $order_by,
            dir           => $order
        );

    } elsif( $subscribers ne '') {
        my $all_subscribers = $model->resultset('Subscription')->search({ pid => $subscribers,
                                                                       end_date => { '>=', DateTime->now() }
                                                                    });
        $self->stash(
            users         => 0,
            admins        => 0,
            user_pages    => 0,
            admin_pages   => 0,
            user_page     => $user_page,
            admin_page    => $admin_page,
            subscriptions => 0,
            subscribers   => $all_subscribers,
            associates    => 0,
            order_by      => $order_by,
            dir           => $order
        );
        
    } else {

        my $associated_users = $model->resultset('ExtraUser')->search( { parent_id => $associates } );

        $self->stash(
            users         => 0,
            admins        => 0,
            user_pages    => 0,
            admin_pages   => 0,
            user_page     => $user_page,
            admin_page    => $admin_page,
            subscriptions => 0,
            subscribers => 0,
            associates    => $associated_users,
            order_by      => $order_by,
            dir           => $order
        );
    }

}

sub search {
    my $self = shift;

    my $model          = $self->app->model;
    my $incoming_query = $self->req->params->to_hash;

    my $full_query;
    $incoming_query->{active} eq 'on' ? $incoming_query->{active} = 1 : $incoming_query->{active} = 0;
    if( $incoming_query->{start_date} ) {
            my $strp = new DateTime::Format::Strptime( pattern => '%m/%d/%Y' );
            my $dt = $strp->parse_datetime( $incoming_query->{start_date} );
            $incoming_query->{start_date} = $dt->ymd;
    }
    if( $incoming_query->{end_date} ) {
            my $strp = new DateTime::Format::Strptime( pattern => '%m/%d/%Y' );
            my $dt = $strp->parse_datetime( $incoming_query->{end_date} );
            $incoming_query->{end_date} = $dt->ymd;
    }

    foreach my $key ( sort ( keys( %{$incoming_query} ) ) ) {
        $full_query = $full_query . ' ' .$incoming_query->{$key};
    }

    my $searcher =
      Lucy::Search::IndexSearcher->new( index => $self->app->home . '/index', );
    my $qparser =
      Lucy::Search::QueryParser->new( schema => $searcher->get_schema, );

    my $query  = $qparser->parse($full_query);
    my $hits   = $searcher->hits( query => $query, );
    my $report = [];
    while ( my $hit = $hits->next ) {
        my $rep;
        $rep->{uid}     = $hit->{uid};
        $rep->{name}    = $hit->{name};
        $rep->{email}   = $hit->{email};
        $rep->{country} = $hit->{country};
        $rep->{state}   = $hit->{county};
        $rep->{sub}     = $hit->{prod_name};
        $rep->{s_date}  = $hit->{start_date};
        $rep->{e_date}  = $hit->{end_date};
        $rep->{renew}   = $hit->{renew};

        push( @$report, $rep );
    }
    $self->stash( hits => $report );

}

=head2 update_delete_user
    sub update_delete_user {
         my $self = shift;
    
        my $model = $self->app->model;
        my $new_usr = $self->req->params->to_hash;  #parameters got from the form put into a hashref
        my $user = 0;
    }
    
    Update an existing user/Create a new user/Delete existing user
=cut

sub update_delete_user {
    my $self = shift;

    my $model   = $self->app->model;
    my $new_usr = $self->req->params->to_hash;

    my $user = 0;

    if ( $self->req->body_params->param('details') ) {
        $self->redirect_to('user_details');

    }
    elsif ( $self->req->body_params->param('update') ) {

        $user =
          $model->resultset('User')
          ->find( { uid => $self->req->body_params->param('update') } );
        $self->stash( user => $user );

    }
    elsif ( %{$new_usr} ) {
        
        if( $new_usr->{birthday} ) {
            my $strp = new DateTime::Format::Strptime( pattern => '%m/%d/%Y' );
            my $dt = $strp->parse_datetime( $new_usr->{birthday} );
            $new_usr->{birthday} = $dt->ymd;
        }
        my $updated_user =
          $model->resultset('User')->update_or_create($new_usr);
        
        my $upload = $self->upload_file($self->req->upload('photo'), $updated_user->uid);
        $updated_user = $updated_user->update({ photo => $upload});
        $self->redirect_to('/admin/user_management');
    }
    else {
        $self->stash( user => $user );
    }
}

sub user_details {
    my $self = shift;

    my $uid   = $self->param('uid');
    my $model = $self->app->model;

    my $user = $model->resultset('User')->find( { uid => $uid } );
    my $subscription = $model->resultset('Subscription')->search(
        {
            uid      => $uid,
            end_date => { '>=', DateTime->now() }
        },
        { order_by => 'end_date DESC' }
    );
    my $sub = $subscription->next;
    my $downgrade = 0;
    my $upgrade = 0;
    if ( defined($sub)){
        $downgrade = $model->resultset('ProductDowngrade')->search({parent_pid => $sub->pid->pid})->first;
        $upgrade = $model->resultset('ProductUpgrade')->search({ parent_pid => $sub->pid->pid } )->first;
    }
    my $renew = 1;
    while( my $subscr = $subscription->next) {
        my $down = $model->resultset('ProductDowngrade')->search({parent_pid => $subscr->pid->pid,downgraded_pid=>$sub->pid->pid} )->first;
        if (defined ($down) ) {
            $renew = 0; 
        }
    }
    my $all_invoices = $model->resultset('Subscription')->search( { uid => $uid } );
    my $total_spent = 0;
    my $total_periods={};
    if ( defined($all_invoices) ) {
        while ( my $invoice = $all_invoices->next ) {
            
            $total_spent += $invoice->pid->subscription_cost;
        }
    }
    my $active_subscriptions = $model->resultset('Subscription')->search({active=>1});
    my $active_subs = $active_subscriptions->count();
    $subscription->reset;
    $self->stash(
        user         => $user,
        downgrade    => $downgrade,
        upgrade      => $upgrade,
        active_subs  => $active_subs,
        subscription => $subscription->next,
        all_invoices => $all_invoices->reset,
        total_spent  => $total_spent,
        renew        => $renew
    );

}

=head2 product_managemet
    sub product_management{
        
    }
    
    Takes all products and their number of subscriptions from database and sends them to template.
=cut

sub product_management {
    my $self = shift;

    my $model = $self->app->model;

    my $products = $model->resultset('Product')->search( {} );
    my $prods = {};

    while ( my $product = $products->next ) {
        
        my $number_of_subscriptions = $model->resultset('Subscription')->search({ pid=> $product->pid});

        my $number_of_active_subscriptions = $model->resultset('Subscription')->search(
            {
                pid      => $product->pid,
                end_date => { '>=', DateTime->now() }
            }
        );
        $prods->{ $product->name }->{total} = $number_of_subscriptions->count();
        $prods->{ $product->name }->{active} = $number_of_active_subscriptions->count();
    }

    $self->stash( products => $products->reset, subscriptions => $prods );

}

=head2 update_delete_product
    sub update_delete_product {
         my $self = shift;
    
        my $model = $self->app->model;
        my $new_usr = $self->req->params->to_hash;  #parameters got from the form put into a hashref
        my $product = 0;
    }
    
    Update an existing product/Create a new product/Delete or deactivate an existing product
=cut

sub update_delete_product {
    my $self = shift;

    my $model    = $self->app->model;
    my $new_prod = $self->req->params->to_hash;
    my $product  = 0;

    my $products = $model->resultset('Product')->search( { active => 1 } );
    my $features = $model->resultset('Feature')->search({});
    
    if ( $self->req->body_params->param('delete') ) {

        my $product =
          $model->resultset('Product')
          ->find( { pid => $self->req->body_params->param('delete') } );
        $product->delete();
        $self->redirect_to('/admin/product_management');

    }
    elsif ( $self->req->body_params->param('deactivate') ) {
        my $product =
          $model->resultset('Product')
          ->find( { pid => $self->req->body_params->param('deactivate') } );
       # my $old_actions = $product->actions;
        my $actions = $product->actions . DateTime->now() .' '. $self->session->{user}->email() .' deactivated' . ' | ';
        $product->update( { active => 0, actions => $actions } );
        $self->redirect_to('/admin/product_management');

    }
    elsif ( $self->req->body_params->param('activate') ) {
        my $product =
          $model->resultset('Product')->find( { pid => $self->req->body_params->param('activate') } );
        my $old_actions = $product->actions;
        my $actions = $old_actions . DateTime->now() .' '. $self->session->{user}->email() .' activated' . ' | ';
        $product->update( { active => 1, actions => $actions } );
        $self->redirect_to('/admin/product_management');

    }
    elsif ( $self->req->body_params->param('update') ) {

        $product =
          $model->resultset('Product')
          ->find( { pid => $self->req->body_params->param('update') } );
        $self->stash( product => $product );

    }
    elsif ( %{$new_prod} ) {
        if (   $new_prod->{requires_card} eq 'on'
            && $new_prod->{subscription_cost} == 0 )
        {
            push @{ $self->session->{error_messages} },
              'You cannot ask a credit card for a free subscription ';
        }
        else {
            
            my $product_to_insert = {
                pid               => defined($new_prod->{pid}) ? $new_prod->{pid} : 'NULL',
                name              => $new_prod->{name},
                no_periods        => $new_prod->{no_periods},
                period_type       => $new_prod->{period_type},
                trial_period_type => $new_prod->{trial_period_type},
                trial_period      => $new_prod->{trial_period},
                subscription_cost => $new_prod->{subscription_cost},
                auto_renew        => $new_prod->{auto_renew},
                additional_users  => $new_prod->{additional_users},
                details           => $new_prod->{details},
                is_new            => $new_prod->{is_new} eq 'on' ? 1 : 0,
                requires_card     => $new_prod->{requires_card} eq 'on' ? 1 : 0,
                currency          => $new_prod->{currency},
            };

            my $updated_product =
              $model->resultset('Product')
              ->update_or_create($product_to_insert);
            foreach my $to_upgrade ( @{ $new_prod->{upgrade} } ) {
                my $update_to =
                  $model->resultset('ProductUpgrade')->update_or_create(
                    {
                        parent_pid   => $updated_product->pid,
                        upgraded_pid => $to_upgrade
                    }
                  );
            }
            foreach my $to_downgrade ( @{ $new_prod->{dowgrade} } ) {
                my $downgrade_to =
                  $model->resultset('ProductDowngrade')->update_or_create(
                    {
                        parent_pid     => $updated_product->pid,
                        downgraded_pid => $to_downgrade
                    }
                  );
            }
            
            foreach my $feature ( @{ $new_prod->{features} } ) {
                my $pack =
                  $model->resultset('Pack')->update_or_create(
                    {
                        pid => $updated_product->pid,
                        fid => $feature,
                    }
                  );
            }
            $self->redirect_to('/admin/product_management');
        }
    }
    else {
        $self->stash( product => $product );
    }
    my $number_of_products = $products->count();
    my $number_of_features = $features->count();
    #$self->stash(fsize => $number_of_features, features => $features->reset);
    $self->stash( products => $products->reset, size => $number_of_products, fsize => $number_of_features, features => $features->reset );
}

=head2 menu
    displays the admin menu
=cut

sub menu {
    my $self = shift;

    my $option = $self->req->params->to_hash;
    if ( defined( $option->{option} ) ) {
        if ( $option->{option} eq 'Sign Up' ) {
            $self->redirect_to('/admin/view_options');
        }
        elsif ( $option->{option} eq 'Style' ) {
            $self->redirect_to('/admin/view_styles');
        }
    }
}

=head2 view_options
    shows all columns of user table
=cut

sub view_options {
    my $self = shift;

    my $model = $self->app->model;

    my @columns = $model->resultset('User')->result_source->columns;
    $self->stash( columns => \@columns );
}

=head2 edit_signup
    Takes all options from user config and saves the ones that were chosen in the page in config.yaml
=cut

sub edit_signup {
    my $self = shift;

    my $new_details = $self->req->params->to_hash;
    my $elements    = $new_details->{column};
    my $new_values  = {};
    foreach my $element (@$elements) {
        $new_values->{$element} = $element;
    }

    my $run_yaml = YAML::Tiny->new;
    $run_yaml = YAML::Tiny->read('conf/config.yaml');
    my $yaml = YAML::Tiny->new;
    $yaml = YAML::Tiny->read('conf/user.yaml');

    foreach my $key ( sort ( keys( %{ $yaml->[0]->{user_data} } ) ) ) {

        if (
            !exists(
                $new_values->{ $yaml->[0]->{user_data}->{$key}->{value} }
            )
          )
        {
            delete $yaml->[0]->{user_data}->{$key};
        }
    }
    $yaml->[0]->{user_data}->{03} = {
        text  => 'Email address',
        value => 'email',
    };
    $yaml->[0]->{user_data}->{10} = {
        text  => 'Password',
        value => 'password',
    };

    %{ $run_yaml->[0]->{user_data} } = %{ $yaml->[0]->{user_data} };
    $run_yaml->write('conf/config.yaml');

    $self->redirect_to('/');
}

=head2 view_styles
    take all css defined in styles.yaml and displays them
=cut

sub view_styles {
    my $self = shift;

    my $yaml = YAML::Tiny->new;
    $yaml = YAML::Tiny->read('conf/styles.yaml');
    $self->stash( styles => $yaml->[0]->{styles_data} );

}


sub upload_style {
    my $self = shift;

    $self->upload_file($self->req->upload('new_style'));
    $self->redirect_to('/admin/view_styles');
}

=head2 edit_style
    thake the chosen style and save it in config.yaml and use it as the current style.
=cut

sub edit_style {
    my $self      = shift;
    my $new_style = $self->req->params->to_hash;

    my $run_yaml = YAML::Tiny->new;
    $run_yaml = YAML::Tiny->read('conf/config.yaml');

    $run_yaml->[0]->{style_info} = $new_style->{style};
    $run_yaml->write('conf/config.yaml');
    $self->app->{config}->{style_info} = $new_style->{style};

    $self->redirect_to('/');

}

sub view_features {
    my $self = shift;
    
    my $model = $self->app->model;
    my $features = $model->resultset('Feature')->search( {} );
    $self->stash(features => $features);
    
}
sub edit_feature {
    my $self = shift;
    
    my $model    = $self->app->model;
    my $new_feature = $self->req->params->to_hash;
    my $feature  = 0;
    
    if ( $self->req->body_params->param('update') ) {
        
        $feature = $model->resultset('Feature')->find( { fid => $self->req->body_params->param('update') } );
        $self->stash( feature => $feature );

    }
    elsif ( %{$new_feature} ) {
        my $updated_feature = $model->resultset('Feature')->update_or_create($new_feature);
        
        $self->redirect_to('/admin/view_features');
    }
    else {
        $self->stash( feature => $feature );
    }  
}

sub _subscription_details {
    my ( $self, $users ) = @_;

    my $model    = $self->app->model;
    my $last_sub = {};

    while ( my $user = $users->next ) {

        my $details = {};
        my $subscriptions =
          $model->resultset('Subscription')
          ->search( { uid => $user->uid }, { order_by => 'end_date DESC' } );
        my $subscription = $subscriptions->next;
        my $associates =
          $model->resultset('ExtraUser')->search( { parent_id => $user->uid, } );
        my $parent =
          $model->resultset('ExtraUser')->search( { uid => $user->uid, status =>'active' } )->first;
        if ( defined($parent) ) {
            #my $par = $parent->next;
            $details->{parent} = $parent->sid->uid->email;
        }

        if ( defined($subscription) ) {

            $details->{name}       = $subscription->pid->name;
            $details->{start_date} = $subscription->start_date;
            $details->{end_date}   = $subscription->end_date;
            $details->{renew}      = $subscription->renew;
            if ( defined($associates) ) {
                $details->{associate} = $associates->count();
            }
        }

        $last_sub->{ $user->uid } = $details;

    }

    return $last_sub;
}

1;
