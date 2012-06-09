package Subscription::Subscription;

use strict;
use warnings;
use feature 'switch';

use Mojo::Base 'Mojolicious::Controller';
use YAML::Tiny;
use DateTime;
use DateTime::Duration;
use Data::Dumper;

sub new_subscription {
    my $self = shift;
                  
    my $params = $self->req->params->to_hash;
    my $subscription_action = $params->{reactivate} ? 'reactivate' : 'subscribe';
    
    $self->stash(
        subscription_action => $subscription_action,
        product => $self->_all_products(),
        cust_uid => $params->{cust_uid},
    );  
}

sub change_subscription {
    my $self = shift;
    
    my $params = $self->req->params->to_hash;
    my $cust_uid = $self->param('cust_uid') || $params->{uid} || $self->session->{user}->uid;
    my $pid = $self->param('pid') || $params->{pid};
    my $product;
    my $subscription_action;
    
    if ($params->{upgrade}) {  
        $product = $self->_all_upgrade_products($pid);
        $subscription_action = 'upgrade';
# you cand downgrade or early renew if you have at most one active subscription
    } elsif ( scalar @{$self->_all_active_subscriptions($cust_uid)} > 1 ){
        push @{$self->session->{error_messages}}, 'You already have an early renew to this subscription';
        $self->redirect_to('/user/account_settings');
        return;
    } elsif($params->{downgrade}) {
        $product = $self->_all_downgrade_products($pid);
        $subscription_action = 'downgrade';
    } elsif ($params->{renew}) {
        $product = $self->_get_product_by_pid($pid);
        $subscription_action = 'renew';
    }
 
    $self->stash(
        subscription_action => $subscription_action,
        product => $product,
        cust_uid => $cust_uid,
    );
}

sub billing {
    my $self = shift;
    
    my $new_pid = $self->param('pid') || '';
    my $action = $self->param('subscription_action') || '';
    my $cust_uid = $self->param('cust_uid') || '';
    
    my $current_active_subscription = $self->_current_subscription();
    my $new_subscription_start_date = $self->_get_new_subscription_start_date($new_pid, $action);
    my $current_subscriptions = $self->_all_active_subscriptions($cust_uid);
    
    my $transformed_subscription = $self->_transform_subscription($current_active_subscription->sid,$new_pid, $new_subscription_start_date);

    my $extra_subscription_price = 0;
    if  ((scalar @$current_subscriptions == 2) && ($action =~ /upgrade/)) {
        my $second_subscription_start_date = $transformed_subscription->{end_date}->add( days =>1 );
        my $new_subscription_end_date = $self->_get_new_subscription_end_date($new_pid, $second_subscription_start_date->ymd);
        $extra_subscription_price  = $transformed_subscription->{final_price}; 
    } elsif (scalar @$current_subscriptions > 1)  {
        push @{$self->session->{error_messages}}, 'No other operations allowed until currend subscription expires';
        $self->redirect_to('/user/account_settings');
        return;
    }
#Verify if everything is ok before billing
    if ($self->_is_correct_transaction($new_pid, $action)) {
           
         $self->stash(
            pid => $new_pid,
            subscription_action => $action,
            start_date => $transformed_subscription->{start_date},
            end_date => $transformed_subscription->{end_date},
            name => $transformed_subscription->{name},
            remaining_amount => sprintf("%.2f", $transformed_subscription->{remaining_ammount}),
            total_price =>  $extra_subscription_price + $transformed_subscription->{final_price},
            cust_uid  => $cust_uid,
        );
    } else {
        $self->redirect_to('/user/account_settings');
    }
}

sub subscribe {
    my $self = shift;
   
    my $params = $self->req->params->to_hash();
      
    if ($params->{cancel}) {
        push @{$self->session->{success_messages}}, 'Action cancelled';
        $self->redirect_to('user/account_settings')
    }
    #for upgrade we must deactivate current subs
    if ($params->{subscription_action} =~ /upgrade/) {
        $self->_deactivate_current_subscription($self->_current_subscription);
    }
      
    $self->_create_subscription($params->{pid}, $params->{start_date}, $params->{end_date}, $params->{cust_uid});
    push @{$self->session->{success_messages}}, 'Subscription created';

    my $email_data = {};
    if ( $params->{subscription_action} =~ /subscribe/ ) {

        $email_data->{title} = 'New Subscription';
        $email_data->{template} = 'email/subscription_new';

    } elsif ( $params->{subscription_action} =~ /upgrade/ ) {

        $email_data->{title} = 'Upgrade Subscription';
        $email_data->{template} = 'email/subscription_upgrade';

    } elsif ( $params->{subscription_action} =~ /downgrade/ ) {

        $email_data->{title} = 'Downgrade Subscription';
        $email_data->{template} = 'email/subscription_downgrade';

    } elsif ( $params->{subscription_action} =~ /renew/ ) {

        $email_data->{title} = 'Renew Subscription';
        $email_data->{template} = 'email/subscription_renew';

    } elsif ( $params->{subscription_action} =~ /reactivate/ ) {

        $email_data->{title} = 'New Subscription';
        $email_data->{template} = 'email/subscription_new';

    }

    my $emailer = $self->email(
        header => [
            To      => $self->session->{user}->email,
            Subject => $email_data->{title},
        ],
        data => [
            template => $email_data->{template},
            user     => {
                name     => $self->session->{user}->name,
                end_date => $params->{end_date},
            },
        ],
    );

    $self->redirect_to('/user/account_settings'); 

}

#####
#### Private methods
####
sub _create_subscription {
    my $self = shift;
    my ($pid, $start_date, $end_date, $uid) = @_;
    
    $uid = $uid ? $uid : $self->session->{user}->uid;
    my $schema = $self->app->model;
    my $res = $schema->resultset('Subscription')->create({
        pid => $pid,
        uid => $uid,
        start_date => $start_date,
        end_date => $end_date,
        active => 1,
    });
}

sub _get_new_subscription_start_date {
    my $self = shift;
    my ($pid, $action) = @_;
    
    my $schema = $self->app->model;
    my $product = $self->_get_product_by_pid($pid);
   
    my $new_subscription_start_date = DateTime->now(); 
    if ($action =~ /renew|downgrade/) {
        my $last_subscription_end_date = $self->_get_last_subscription_date();
        my ($year, $month, $day) = split "-", $last_subscription_end_date. "\n";
        $new_subscription_start_date = DateTime->new(year => $year, month => $month, day => $day);
        $new_subscription_start_date->add(days => 1);
    };
    
    return $new_subscription_start_date;
}

#start_date is a DateTime object
sub _get_new_subscription_end_date {
    my $self = shift;
    my ($pid, $start_date) = @_;
  
    my $product = $self->_get_product_by_pid($pid);
   
    my ($year, $month, $day) = split ("-", $start_date);
    my $subscription_end_date = DateTime->new(year => $year, month => $month, day => $day);
    
    given ($product->period_type) {
        when ('day') {$subscription_end_date->add( days => $product->no_periods )}
        when ('week') { $subscription_end_date->add( weeks => $product->no_periods )}
        when ('month') {$subscription_end_date->add( months => $product->no_periods )}
        when ('quarter') {$subscription_end_date->add( months => ($product->no_periods * 3))}
        when ('year') {$subscription_end_date->add( years => $product->no_periods )}
    }; 

    return $subscription_end_date;
}

sub _get_product_by_pid {
    my $self = shift;
    my $pid = shift;
    
    my $schema = $self->app->model;
    my $product = $schema->resultset('Product')->find(
       {
           pid => $pid,
       }
    );
    return $product;
}

sub _get_subscription_by_sid {
    my $self = shift;
    my $pid = shift;
    
    my $schema = $self->app->model;
    my $subscription = $schema->resultset('Subscription')->find(
       {
           sid => $pid,
       }
    );
    return $subscription;
}

sub _all_products {
    my $self = shift;
   
    my $schema = $self->app->model;
    my $result_set = $schema->resultset('Product')->search({});
    
    return $result_set;
}

sub _all_upgrade_products {
    my $self = shift;
    my $pid = shift;
              
    my $schema = $self->app->model;
    my $update_products = $schema->resultset('ProductUpgrade')->search({
        parent_pid => $pid,
    });
    
    return $update_products;    
}

sub _all_downgrade_products {
    my $self = shift;
    my $pid = shift;
       
    my $schema = $self->app->model;
    my $downgrade_products = $schema->resultset('ProductDowngrade')->search({
        parent_pid => $pid,
    });
    
    return $downgrade_products;    
}

sub _current_subscription {
    my $self = shift;
    
    my $date_now = DateTime->now();
    my $schema = $self->app->model;
    
    my $current_subscription = $schema->resultset('Subscription')->search({
        uid => $self->session->{user}->uid,
        active => 1,
        start_date => {"<=", $date_now->ymd},
        end_date => {">=", $date_now->ymd},
    });
    
    return $current_subscription->first;
}

sub _deactivate_current_subscription {
    my $self = shift;
    
    my $current_subscription = $self->_current_subscription();   
    if ($current_subscription) {
        $current_subscription->update({active => 0});
    }
}

sub _get_last_subscription_date {
    my $self = shift;
    
    my $schema = $self->app->model;
    my $last_active_subscription = $schema->resultset('Subscription')->search(
        {
            uid => $self->session->{user}->uid,
            active => 1,
        },
        {
            order_by => {-desc => 'end_date'}
        }
    )->slice(0,0)->single();
    
    return $last_active_subscription ? substr($last_active_subscription->end_date, 0, 10) : undef;
}
 
sub _get_remaining_amount_from_subscription {
    my $self = shift;
    my $current_subscription = shift;

    return 0 if !$current_subscription;
    my ($start_year, $start_month, $start_day) = split "-", substr($current_subscription->start_date, 0, 10);
    my ($end_year, $end_month, $end_day) = split "-", substr($current_subscription->end_date, 0, 10);
    
    my $today = DateTime->now();
    my $start_date = DateTime->new(year => $start_year, month => $start_month, day => $start_day);
    my $end_date = DateTime->new(year => $end_year, month => $end_month, day => $end_day);

    my $total_days  = $end_date->delta_days($start_date)->in_units('days');
    my $used_days = $today->subtract_datetime($start_date)->in_units('days');
    
    # direct propertionality result
    return 0 if ($total_days == 0);
    return ($current_subscription->pid->subscription_cost * (1 - $used_days/ $total_days));
}

# Verifiy if the everything is correct
# (chosen product, subscription_action)
# before billing.
sub _is_correct_transaction {
    my $self = shift;
    my ($pid, $action) = @_;
    
    my $date_now = DateTime->now();
 
    if ($action =~ /subscribe|reactivate/) {
        my $schema = $self->app->model;
        my $current_subscription = $schema->resultset('Subscription')->find({
            uid => $self->session->{user}->uid,
            active => 1,
            start_date => {"<=", $date_now->ymd},
            end_date => {">=", $date_now->ymd},
        });
        
        if ($current_subscription) {
              push@{$self->session->{error_messages}}, 'You already have a active subscription';
              $self->redirect_to('/user/account_settings');
        }
    }
    
    if ($action =~ /upgrade|downgrade|renew/) {
        #verificam ceva?
    }

    return 1;
}

sub _all_active_subscriptions {
    my $self = shift;
    my $uid = shift;
    
    my $date_now = DateTime->now();
 
    my $schema = $self->app->model;
    my $active_subscriptions = $schema->resultset('Subscription')->search({
        uid => $uid,
        active => 1,
        end_date => {">=", $date_now->ymd},
    });
    my @result_set = ();
    while (my $row = $active_subscriptions->next){
        push @result_set, $row->sid;
    }
    return \@result_set;
}

sub _transform_subscription {
    my $self = shift;
    my ($initial_subscription_id, $final_product_pid, $start_date) = @_;
    
    my $result_set = {};
    
    my $initial_subscription = $self->_get_subscription_by_sid($initial_subscription_id);

    $result_set->{initial_pid} = $initial_subscription->pid->pid;
    $result_set->{final_pid} = $final_product_pid;
    $result_set->{initial_price} = $initial_subscription->pid->subscription_cost;
    $result_set->{remaining_ammount} = $self->_get_remaining_amount_from_subscription($initial_subscription);
    $result_set->{final_price} = $self->_get_product_by_pid($final_product_pid)->subscription_cost;
    $result_set->{name} = $self->_get_product_by_pid($final_product_pid)->name;
    $result_set->{start_date} = $start_date;
    $result_set->{end_date} = $self->_get_new_subscription_end_date($final_product_pid, $start_date->ymd);
    
    return $result_set;
}

1;

