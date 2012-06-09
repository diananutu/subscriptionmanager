package Subscription::Main;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';

use DateTime;

# This action will render a template
sub home {
  my $self = shift;

  $self->render(
    message => 'Welcome Subscription Bootstrap');
}

sub pricing {
    my $self = shift;
    
    my $schema = $self->app->model;

    my $rs = $schema->resultset('Pack')->search(
        {},
        {
           order_by =>  { -asc =>  [qw/pid fid/]}
        }
    );

    my $formated_product = undef;

    while (my $row = $rs->next){
        if (not exists ($formated_product->{$row->pid->pid})) {
            $formated_product->{$row->pid->pid}->{product_name} = $row->pid->name;
            $formated_product->{$row->pid->pid}->{description} = $row->pid->description;
            $formated_product->{$row->pid->pid}->{period_type} = $row->pid->period_type;
            $formated_product->{$row->pid->pid}->{no_periods} = $row->pid->no_periods;
            $formated_product->{$row->pid->pid}->{subscription_cost} = $row->pid->subscription_cost;
            $formated_product->{$row->pid->pid}->{currency} = $row->pid->currency;
            $formated_product->{$row->pid->pid}->{is_featured} = $row->pid->is_featured;
        }
        $formated_product->{$row->pid->pid}->{features}->{$row->fid->fid} = $row->fid->feature_name;
    }

    $self->stash(
            valid_products => $formated_product
    );
}


sub contact_us {
  my $self = shift;
  my $params = $self->req->params->to_hash;

  my $emailer = $self->email(
        header => [
            To      => $self->config->{email}->{from},
            From    => $params->{email},
        ],
        data => [
            template => 'email/contact_us',
            user     => {
                name    => $params->{name},
                email   => $params->{email},
                message => $params->{message},
            },
        ],
    );
    if ($emailer) {
      push @{ $self->session->{success_messages} }, 'Your email has been sent successfully.';
    } else {
      push @{ $self->session->{success_messages} }, 'A problem appeared, please try again later.';
    }

    $self->redirect_to('HOME');
}

sub send_recover_mail {
  my $self = shift;
  
  my $model = $self->app->model;
  my $email = $self->req->params->to_hash;
  
  my $user = $model->resultset('User')->find( { email => $email->{email} } );
  
  my $url = $self->checksum($email->{email});
  my $date = DateTime->now();
  $date = $date->add( days=> 1);
  
  if( defined ($user) ) {
    my $passwd_hash = $model->resultset('PasswordHash')->create({ uid => $user->uid,
                                          sent_url => $url,
                                          expiry_date => $date,
                                          active    =>1
                                        });
    push @{ $self->session->{success_messages} },  'Email sent. Please check you email and follow the instructions' ;
    
    $self->email(
              header => [
                  To      => $email->{email},
              ],
              data => [
                  template => 'email/forgot_password',
                  activation_key => $url,
                  base_url       => $self->req->url->base,
                  name           => $user->name,
              ],
          );
    
    $self->redirect_to('/');
  } else {
    push @{ $self->session->{error_messages} },  'Please enter a valid email' ;
    $self->redirect_to('/');
  }
  
}

sub recover_email {
  my $self = shift;
  
  my $url = $self->param('ue');
  
  my $model = $self->app->model;
  
  my $existing_url = $model->resultset('PasswordHash')->find({ sent_url => $url });
  
  if( defined($existing_url) ) {
    $self->stash( details => $existing_url );
  } else {
    push @{$self->session->{error_messages}}, 'There is no recover email with the details you provided';
        $self->redirect_to('/');
  }
}

sub recovered_password {
  my $self = shift;
  
  my $passwords = $self->req->params->to_hash;
  
  my $uid = $self->param('uid');
  my $hash = $self->param('hash');
  
  my $model = $self->app->model;
  
  if ( $passwords->{new_password} eq $passwords->{repeat_new_password} ) {
    if( length($passwords->{new_password}) > 3 ){
      my $user = $model->resultset('User')->find( { uid => $uid });
      my $url = $model->resultset('PasswordHash')->find({ uid => $uid, sent_url => $hash });
      
      $user = $user->update({password => $passwords->{new_password}});
      $url = $url->update({active => 0 });
      
      push @{ $self->session->{success_messages} }, 'Password sucessfully changed' ;
      $self->redirect_to('/');
    }
    else {
      push @{$self->session->{error_messages}}, 'Please insert a longer password';
      $self->redirect_to("/recover?ue=$hash");
    }
  } else { 
    push @{$self->session->{error_messages}}, 'Passwords did not match, please try again';
    $self->redirect_to("/recover?ue=$hash");
  }
 
}

1;
