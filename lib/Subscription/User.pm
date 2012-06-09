package Subscription::User;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';
use DateTime;
use YAML::Tiny;
use DateTime::Format::Strptime;
use Data::Dumper;



sub login {
    my $self = shift;
    
    my $email = $self->param('email') || '';
    my $pass  = $self->param('password') || '';
    #warn "params=". Dumper($self->req->params->to_hash);
    
    my $user = $self->_get_user_by_email($email, $pass);
    #warn "user======".Dumper($user);

    if ( $user ) {
        if (!$user->active){
            my $url = $self->url_for("resend_activation_mail");
            $self->redirect_to($url->query(uid => $user->uid));
            
            #$self->render('resend_activation_mail', {uid => 9});
            #$self->redirect_to('/send-activation-mail?uid='.$user->uid);
            return;
        }
        $self->session->{user} = $user;

        my $user_name  = defined $self->session->{user}->name
                    ? $self->session->{user}->name
                    : $self->session->{user}->email;
                    
        push @{ $self->session->{notice_messages} }, sprintf("You're logged in as %s.", $user_name); 

    } else {
        push @{ $self->session->{error_messages} }, 'Login failed, wrong username or password';
    }

    $self->redirect_to('user_menu');
}

sub invite {
    my $self = shift;
    my $params = $self->req->params->to_hash();
    
    my $user_id = $self->session->{user}->uid;

    my $schema = $self->app->model;
    my $user_subscriptions = $self->_get_subscription_info($user_id);

    if (!$user_subscriptions) {
        push @{$self->session->{error_messages}}, 'No subscriptions available';
        $self->redirect_to('/');
    }

    $self->stash(
        subscription_data => $user_subscriptions,
    );
}
# activate an account using the activation link
sub activate {
    my $self = shift;
    
    my $email = $self->param('ue') || '';
    my $uid = $self->param('uid') || '';
    
    my $schema = $self->app->model;
    my $user = $schema->resultset('User')->find(
                {
                    uid    => $uid,
                }
            );
    
    if (!$user){
        push @{ $self->session->{error_messages} }, 'Wrong activation link';
        $self->redirect_to('/');
        return;
    }
    my $encoded_text = $self->checksum("test123".$user->email);

    if ($email ne $encoded_text){
        push @{ $self->session->{error_messages} }, 'Wrong activation key';
        $self->redirect_to('/');
        return;
    }
    
    $self->session->{user} = $user;

    my $user_name  = defined $self->session->{user}->name
                ? $self->session->{user}->name
                : $self->session->{user}->email;
    if ($self->session->{user}->active){
            push @{ $self->session->{notice_messages} }, sprintf("Account already activated"); 
        } else {
            my $activate_user = $user->update({'active' => '1'});
            push @{ $self->session->{notice_messages} }, sprintf("Activation succesfull"); 
        }
    push @{ $self->session->{notice_messages} }, sprintf("You're logged in as %s.", $user_name); 

    $self->redirect_to('user_menu');
}


sub resend_activation_mail{
    my $self = shift;
    
    my $params = $self->req->params->to_hash();
    
    if ($params->{action} =~ /process_request/){
        $self->_send_activation_link ($self->_get_user_by_id($params->{uid}));
        push @{ $self->session->{notice_messages} }, sprintf("Activation email was sent");
        $self->redirect_to('/');
        return;
    } else {
            $self->stash(
                uid => $params->{uid},
            );
    }
    
}

sub invite_validate {
    my $self = shift;
    
    my $params = $self->req->params->to_hash();

    if (!$params->{email}) {
        push @{$self->session->{noticed_messages}}, 'Please provide at least one email address';
        $self->redirect_to('invite');
    } elsif (!$params->{sid}) {
        push @{$self->session->{noticed_messages}}, 'Please choose subscription again';
        $self->redirect_to('invite');
    } elsif ( !$self->_check_ownership( $params->{sid} )) {
        push @{$self->session->{error_messages}}, 'You do not own this subscription';
        $self->redirect_to('invite');
    } else {
            my $remaining_invites = $self->_count_remaining_invites($params->{sid});
#eliminate null elements from email list
            my @valid_emails = ();
            if ( ref($params->{email}) ne 'ARRAY' ){
                push @valid_emails, $params->{email};
            } else {
                @valid_emails = grep { $_ } map { s/\s//g; $_} @{$params->{email}};
            }
            foreach (1..$remaining_invites){
                my $possible_user = shift @valid_emails;
                if ($possible_user) {
                    if ($self->_insert_invited_user($possible_user, $params->{sid})){
                    }
                }
            }
    }
    
    $self->redirect_to('invite');
}


sub add_picture{
    my $self = shift;
    
    my $upload = $self->upload_file( $self->req->upload('avatar'), $self->session->{user}->uid );
    my $user = $self->app->model->resultset('User')->find( {uid => $self->session->{user}->uid} );
    $user = $user->update({'photo' => $upload});
    
    $self->redirect_to('account_settings')
}


sub register {
    my $self = shift;
    
    my $email = $self->param('email') || '';
    my $pass  = $self->param('password') || '';
    my $pass2 = $self->param('password2') || '';

    my $new_usr = $self->req->params->to_hash;

    my $user_exists = $self->_get_user_by_email($email);
    my @problems;
    push @problems, 'User already exists' if ($user_exists);
    push @problems, 'Username must not be null' if (!$email);
    push @problems, 'Passwords do not match' if ($pass ne $pass2);
    push @problems, 'email must be valid' if (!$self->param('email'));
    
    if (@problems) {
        push @{$self->session->{error_messages}}, @problems;
        $self->redirect_to('register');
        
    } else {

        delete $new_usr->{password2};
        $self->_insert_user($new_usr);
        $self->session->{user} = $self->_get_user_by_email($new_usr->{email});

        $self->email(
            header => [To => $new_usr->{email}],
            data => [
                template => 'email/signup_confirmation',
                activation_key => $self->checksum($new_usr->{email}),
                base_url       => $self->req->url->base,
                user           => {
                    name     => $new_usr->{name},
                    email    => $new_usr->{email},
                    password => $new_usr->{password},
                },
            ],
        );

        push @{ $self->session->{success_messages} },  'register successfull' ;
        $self->redirect_to('/');

    }
}


sub signup_step1{
    my $self = shift;
    
    my $product_options = $self->req->params->to_hash;
    my $schema = $self->app->model;
   
    my $rs = $schema->resultset('Product')->find( { 'pid' => $product_options->{pid} } );
 
    $self->redirect_to('pricing') if (!$rs);
    
    $self->session->{chosen_product} = {};
    $self->session->{chosen_product}->{pid} = $product_options->{pid};
    $self->session->{chosen_product}->{needs_cc} = $rs->requires_card;
    $self->session->{chosen_product}->{is_free} = ($rs->subscription_cost == 0) ? 1 : 0;

    $self->redirect_to('simple_register');
return;

# product is free
    if ($rs->subscription_cost == 0) {
        $self->redirect_to('simple_register');
    }

#product includes a trial period
    if ($rs->trial_period) {
            $self->redirect_to('simple_register');
    } else {
        
    }

}

sub simple_register_confirm{
    my $self = shift;

    my $email = $self->param('email') || '';
    my $pass = $self->param('password') || '';
    my $pass2= $self->param('password2') || '';

    my $new_usr = $self->req->params->to_hash;
    
    my $user_exists = $self->_get_user_by_email($email);
    my @problems;
    push @problems, 'User already exists' if ($user_exists);
    push @problems, 'Passwords do not match' if ($pass ne $pass2);
    push @problems, 'email must be valid' if (!$self->param('email'));
    
    if (@problems) {
        push @{$self->session->{error_messages}}, @problems;
        $self->redirect_to('simple_register');
        
    } else {
        delete $new_usr->{password2};
        $self->_insert_user($new_usr);
        $new_usr = $self->_get_user_by_email($email);
        
        $self->_send_activation_link($new_usr);
        push @{ $self->session->{success_messages} },  'register successful' ;
        
        if ($self->session->{chosen_product}->{is_free}){
            push @{ $self->session->{success_messages} },  'register successful, an activation email was sent ' ;
            $self->redirect_to('/');
            return;
        }
        
        if ($self->session->{chosen_product}->{needs_cc}){
            $self->redirect_to('/subscription/billing?subscription_action=subscribe&pid='.$self->{chosen_product}->{pid});
            return;
        } 

    }
}


sub display_invite {
    my $self = shift;
  
    my $euid = $self->param('euid');
    if (!$euid) {
        push @{$self->session->{error_messages}}, 'Bad invite link';
        $self->redirect_to('/');
        return;
    }

    my $schema = $self->app->model;
    my $rs = $schema->resultset('ExtraUser')->find( {'euid' => $euid});
   
    if (!$rs) {
        push @{$self->session->{error_messages}}, 'Bad invite link, no invitation foud for this email';
        $self->redirect_to('/');
        return;
    } elsif ($rs->status eq 'active'){
        $self->session->{user} = $self->_get_user_by_email($rs->uid->email);
        push @{ $self->session->{success_messages} },  'account already activated' ;
        $self->redirect_to('/');
        return;
    }
    my $register_data->{email}=$rs->uid->email;
    $register_data->{password}=$rs->uid->password;
    $register_data->{euid}=$euid;

    $self->stash(
        register_data => $register_data,
    );
}

sub activate_invite {
    my $self = shift;
    
    my $register_data = $self->req->params->to_hash;
    my $schema = $self->app->model;
    my $rs = $schema->resultset('ExtraUser')->find( {'euid' => $register_data->{euid}});
    
    if (!$rs) {
        push @{$self->session->{error_messages}}, 'Bad invite link, no invitation foud for this email';
        $self->redirect_to('display_invite?euid='.$register_data->{euid});
    }
# redirect not ok, needs to be changed...?????
    if ($register_data->{password2} && ($register_data->{password2} ne $register_data->{password})){
        push @{$self->session->{error_messages}}, 'please retype password';
        $self->redirect_to('display_invite?euid='.$register_data->{euid});
    }
    
# update password for new users   
    if ($register_data->{password}){
        my $update_password_set = $schema->resultset('User')->find({'uid' => $rs->uid->uid});
        $update_password_set->update({'password' => $register_data->{password}});
    }
    
    $rs->update({'status' => 'active', 'registered_date' => DateTime->now()->ymd()});
    $self->session->{user} = $self->_get_user_by_email($register_data->{email});
    push @{ $self->session->{success_messages} },  'activate successful' ;
    $self->redirect_to('/');
}



sub account_settings {
    my $self = shift;
        
    my $date_now = DateTime->now();
    
    my $schema = $self->app->model;
    my $current_subscription = $schema->resultset('Subscription')->find(
        {
            uid => $self->session->{user}->uid,
            active => 1,
            start_date => {"<=", $date_now->ymd},
            end_date => {">=", $date_now->ymd}
        }
    ); 
    my $future_subscriptions = $schema->resultset('Subscription')->search(
        {
           uid => $self->session->{user}->uid(),
           active => 1,
           start_date => {">", $date_now->ymd },
        }
    );
         
    $self->stash(
        subscription => $current_subscription ? $current_subscription : undef,
        future_subscriptions => defined($future_subscriptions) ? $future_subscriptions: 0,
    );

}

sub register_form{
    my $self = shift;
    
    my $yaml = YAML::Tiny->new;
    $yaml = YAML::Tiny->read('conf/config.yaml');
    
    $self->stash(
        user_config => $yaml,
    );
}

sub logout {
  my $self = shift;

  delete $self->session->{user};
  $self->redirect_to('/');
}

sub check_credentials {
    my $self = shift;
  
    if (defined $self->session->{user}) {
        return 1;
    } else {
        $self->redirect_to('login');
    }
    return;
}



sub edit_info {
    my $self = shift;
    
};

sub user_update {
    my $self = shift;

    # save new user data in hash
    my $new_usr = $self->req->params->to_hash;
    my $result_set = $self->app->model->resultset('User')->find( {
       uid => $self->session->{user}->uid
    });
    
    if( $new_usr->{birthday} ) {
        my $strp = new DateTime::Format::Strptime( pattern => '%m/%d/%Y' );
        my $dt = $strp->parse_datetime( $new_usr->{birthday} );
        $new_usr->{birthday} = $dt->ymd;
    }
   
    my $new_user = $result_set->update($new_usr);
    my %column_data = $self->session->{user}->get_columns;

    # update session with the new user data
    foreach my $column ( keys %column_data ) {
        if ($new_user->$column) {
            $self->session->{user}->set_column(
                $column => $new_user->$column
            );
        }
    }

    push @{ $self->session->{success_messages} }, 'Info succesfully updated';

    $self->redirect_to('/user/account_settings');
}

#Getter for password change
sub password_change {
    my $self = shift;
   
}

sub change_password {
    my $self = shift;
    
    my $passwords = $self->req->params->to_hash;
     
    if ($self->_password_validation($passwords) =~ /succesfully/) {
        my $result_set = $self->app->model->resultset('Schema::Result::User')->find(
            $self->session->{user}->uid
        );
        my $new_user = $result_set->update({'password' => $passwords->{new_password}});
        push @{ $self->session->{success_messages} }, $self->_password_validation($passwords) ;

        $self->email(
            header => [
                To      => $new_user->email,
                From    => $self->config->{email}->{from},
            ],
            data => [
                template => 'email/change_password',
                user     => {
                    name     => $result_set->name,
                    email    => $result_set->email,
                    password => $result_set->password,
                },
            ],
        );

        $self->redirect_to('/user/menu');
    } else {
        push @{$self->session->{error_messages}}, $self->_password_validation($passwords);
       
        $self->redirect_to('/user/password_change');
    }   
}


sub _get_subscriptions {
    my $self = shift;
    my $user_id = shift;
    
    my $date_now = DateTime->now();
    my $schema = $self->app->model;
    
    my $current_subscription = $schema->resultset('Subscription')->search({
        uid => $user_id,
        active => 1,
        end_date => {">=", $date_now->ymd},
    });
    
    my $result_hash = {};
    
    while (my $row = $current_subscription->next) {
        $result_hash->{$row->sid}->{additional_users} = $row->pid->additional_users;
        $result_hash->{$row->sid}->{price} = $row->pid->subscription_cost;
        $result_hash->{$row->sid}->{start_date} = substr($row->start_date, 0, 10);
        $result_hash->{$row->sid}->{end_date} = substr($row->end_date, 0, 10);
        $result_hash->{$row->sid}->{product_name} = $row->pid->name;
        $result_hash->{$row->sid}->{remaining_invites} = $self->_count_remaining_invites($row->sid);
    }
    return $result_hash;
}

sub _get_subscription_info {
    my $self = shift;
    my $user_id = shift;
    
    my $date_now = DateTime->now();
    my $schema = $self->app->model;
    
    my $current_subscription = $schema->resultset('Subscription')->search({
        uid => $user_id,
        active => 1,
#           start_date => {"<=", $date_now->ymd},
        end_date => {">=", $date_now->ymd},
    },
    {
        order_by => {-asc => 'end_date'}
    });
    
    my $result_hash = {};
    my $row = $current_subscription->next;
    $result_hash->{sid} = $row->sid;
    $result_hash->{start_date} = substr($row->start_date, 0, 10);
    $result_hash->{end_date} = substr($row->end_date, 0, 10);
    $result_hash->{price} = $row->pid->subscription_cost;
    $result_hash->{product_name} = $row->pid->name;
    $result_hash->{additional_users} = $row->pid->additional_users;
    $result_hash->{remaining_invites} = $self->_count_remaining_invites($row->sid);
    while (my $row = $current_subscription->next) {
        $result_hash->{end_date} = substr($row->end_date, 0, 10);
    }
    
    return $result_hash;
}


sub _count_remaining_invites{
    my $self = shift;
    my $subscription_id = shift;
    
    my $schema = $self->app->model;
    my $invited_users = $schema->resultset('ExtraUser')->search({
            sid => $subscription_id,
    });
    
    my $subscription_details = $schema->resultset('Subscription')->find({
            sid => $subscription_id,
    });
    
    return  $subscription_details->pid->additional_users - $invited_users->count() if $subscription_details->pid->additional_users;
}

sub _check_ownership {
    my $self = shift;
    my $subscription_id = shift;

    my $schema = $self->app->model;
    my $check = $schema->resultset('Subscription')->find(
        {
            uid => $self->session->{user}->uid,
            sid => $subscription_id
        }
    );
    
    if ($check){ return 1}
    return 0;
}

sub _insert_invited_user {
    my $self = shift;
    my $email = shift;
    my $sid = shift;
    
    my $schema = $self->app->model;

    my $user_exists = $self->_get_user_by_email($email);
    
    if  ($user_exists) {
         if (%{$self->_get_subscriptions($user_exists->uid)}){
            push @{$self->session->{error_messages}}, 'The following email: '.$email.' already has a subscription';
            return 0;
        };
    } else {
        $self->_insert_user({email => $email, password => ''});
        $user_exists = $self->_get_user_by_email($email);
    }
   
    my $already_added_extra_user = $schema->resultset('ExtraUser')->find({
        uid => $user_exists->uid,
        sid => $sid,
    });
    
    
    if ($already_added_extra_user) {
        push @{$self->session->{error_messages}}, 'The following email: '.$email.' was already added to this subscription';
        return 0;
    } else {
        my $date_now = DateTime->now();
        my $new_extra_user = $schema->resultset('ExtraUser')->create(
            {
                uid => $user_exists->uid,
                sid => $sid,
                invite_date => $date_now->ymd,
                parent_id => $self->session->{user}->uid,
            });
        
        $self->email(
            header => [
                To      => $user_exists->email,
                From    => $self->config->{email}->{from},
            ],
            data => [
                template => 'email/user_invite',
                user => {
                    parent_name     => $self->session->{user}->name,
                    extra_user_id    => $new_extra_user->euid,
                    base_url => $self->req->url->base,
                },
            ],
        );

    }
    
    return 1;
    }

sub _password_validation {
    my $self = shift;
    my $passwords = shift;

    return 'Wrong password name' if ($passwords->{old_password} ne $self->session->{user}->password);
    return 'New password is not consistent' if ($passwords->{new_password} ne $passwords->{repeat_new_password});
    return 'Plese insert a stronger password' if (length($passwords->{new_password}) < 3); ## !!!!! Global defined of password length..maybe in config.yaml
    
    return 'Password succesfully changed';
}

sub _send_activation_link{
    my $self = shift;
    my $user = shift;
    
            $self->email(
            header => [
                To      => $user->email,
                From    => $self->config->{email}->{from},
                Subject => "Signup Confirmation",
            ],
            data => [
                template => 'email/signup_confirmation',
                activation_key => $self->checksum("test123".$user->email),
                base_url       => $self->req->url->base,
                user           => {
                    email    => $user->email,
                    password => $user->password,
                    uid      => $user->uid
                },
            ],
        );
    return;
}

sub _get_user_by_email{
    my $self = shift;
    my ($email, $pass) = @_;
  
    my $schema = $self->app->model;
    my $res = undef;
    if ($pass){
        $res = $schema->resultset('User')->find(
            {
                email    => $email,
                password => $pass,
            }
        );
    } else {
         $res = $schema->resultset('User')->find( {email => $email} );
    }

    return $res;
}

sub _get_user_by_id{
    my $self = shift;
    my $user_id = shift;

    my $res = $self->app->model->resultset('User')->find({ uid => $user_id } );

    return $res;
}

sub _insert_user { 
    my $self = shift;
    my $user_data = shift;

    $user_data->{access}='user';
    my $schema = $self->app->model;
    my $res = $schema->resultset('User')->create($user_data);

    return ;
}


1;

