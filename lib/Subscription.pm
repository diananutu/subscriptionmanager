package Subscription;
use Mojo::Base 'Mojolicious';

use strict;
use warnings;

use Schema;
use Mojolicious::Plugin::Email;
use Mojolicious::Plugin::WWWSession;
use Email::Sender::Transport::Sendmail;

sub startup {
    my $self = shift;
  
    $self->secret("Very well hidden secret");
    
    my $config = $self->plugin( yaml_config => {
        file      => 'conf/config.yaml',
        stash_key => 'conf',
        class     => 'YAML::XS'
    });

    $self->{config} = $config;

    $self->plugin( Email => {
            transport => Email::Sender::Transport::Sendmail->new,
            from      => $config->{email}->{from},
        }
    );

    $self->plugin('Subscription::Helpers');

    if (!$self->can('model')) {
        __PACKAGE__->attr(
         'model' => sub {
                Schema->connect(
                    $config->{database}->{dsn},  
                    $config->{database}->{user},
                    $config->{database}->{password},
                );
            }
        );
    }

    $self->plugin( WWWSession => {
                        storage => [
                            Memcached => {
                                servers => [
                                    $config->{memcached}->{server}
                                ]
                            }
                        ],
                        fields => {
                            user => {
                                deflate => sub { defined $_[0] ? $_[0]->uid() : undef },
                                inflate => sub { defined $_[0] ? $self->model()->resultset('User')->find({uid => $_[0]}) : undef }
                            }
                        },
                        expires => 3600,
                    }
                );

    $self->hook(after_static_dispatch => sub {
        my $c = shift;
        $c->session->{_menu} = defined($c->session->{user})
                    ? $c->app->{config}->{app_menu}->{ $c->session->{user}->access }
                    : $c->app->{config}->{app_menu}->{anonymous};
    }); 

    # Router
    my $public = $self->routes;

    # Normal routes
    $public->get('/')->to('main#home')->name('HOME');
    $public->route('/why-us')->to('main#why_us');
    $public->route('/how-it-works')->to('main#how_it_works');
    $public->route('/faq')->to('main#faq');
    $public->route('/pricing')->to('main#pricing')->name('pricing');
    $public->route('/company')->to('main#company');
    $public->route('/team')->to('main#team');
    $public->route('/careers')->to('main#careers');
    $public->route('/about')->to('main#about');
    $public->route('/contact')->to('main#contact_us');
    $public->route('/forgot_password')->to('main#forgot_password');
    $public->route('/send_recover_mail')->to('main#send_recover_mail')->name('forgot_password');
    $public->route('/recover')->to('main#recover_email')->name('recover_email');
    $public->route('/recovered_password')->to('main#recovered_password')->name('recovered_password');


    $public->route('/logout')->to('user#logout')->name('logout');
    $public->route('/login')->via('GET')->to('user#login_form')->name('login_form');
    $public->route('/login')->via('POST')->to('user#login')->name('login');
    $public->route('/sign-up/invite/activate')->to('user#activate_invite')->name('activate_invite');
    $public->route('/sign-up/invite')->to('user#display_invite')->name('display_invite');
    $public->route('/sign-up')->via('GET')->to('user#register_form')->name('register_form');
    $public->route('/sign-up')->via('POST')->to('user#register')->name('register');
    $public->route('/sign-up/step1')->to('user#signup_step1')->name('signup_step1');
    $public->route('/sign-up/step1_register')->via('GET')->to('user#simple_register')->name('simple_register');
    $public->route('/sign-up/step1_register')->via('POST')->to('user#simple_register_confirm')->name('simple_register_confirm');
    $public->route('/activate')->to('user#activate')->name('activate');
    $public->route('/send-activation-mail')->to('user#resend_activation_mail')->name('resend_activation_mail');



    # Bridge router, we must check if user is logged in
    # to give him access into the administration area
    my $admin = $self->routes->bridge->to('user#check_credentials');

    # User routes
    $admin->route('/user/menu')->to('user#menu')->name('user_menu');
    $admin->route('/user/account_settings')->to('user#account_settings')->name('account_settings');
    $admin->route('/user/edit_info')->via('GET' )->to('user#edit_info')->name('edit_info');
    $admin->route('/user/user_update')->via('POST')->to('user#user_update')->name('user_update');
    $admin->route('/user/password_change')->via('GET' )->to('user#password_change')->name('password_change');
    $admin->route('/user/password_change')->via('POST')->to('user#change_password')->name('change_password');
    $admin->route('/user/about')->to('main#welcome');
    $admin->route('/user/add_picture')->via('POST')->to('user#add_picture')->name('add_picture');
    $admin->route('/user/invite')->to('user#invite')->name('invite');
    $admin->route('/user/invite_validate')->to('user#invite_validate')->name('invite_validate');
   


    # Admin routes
    $admin->route('/admin')->to('admin#index');
    $admin->route('/admin/user_management')->to('admin#user_management')->name('user_management');
    $admin->route('/admin/update_delete_user')->to('admin#update_delete_user')->name('update');
    $admin->route('/admin/user_details')->to('admin#user_details')->name('user_details');
    $admin->route('/admin/search')->to('admin#search')->name('search');
    
    $admin->route('/admin/product_management')->to('admin#product_management')->name('product_management');
    $admin->route('/admin/update_delete_product')->to('admin#update_delete_product')->name('update_product');
    $admin->route('/admin/view_features')->to('admin#view_features')->name('view_features');
    $admin->route('/admin/edit_feature')->to('admin#edit_feature')->name('edit_feature');
    
    $admin->route('/admin/menu')->to('admin#menu')->name('admin_menu');
    $admin->route('/admin/view_options')->to('admin#view_options')->name('view_options');
    $admin->route('/admin/edit_signup')->to('admin#edit_signup')->name('edit_signup');

    $admin->route('/admin/view_styles')->to('admin#view_styles')->name('view_styles');
    $admin->route('/admin/upload_style')->to('admin#upload_style');
    $admin->route('/admin/edit_style')->to('admin#edit_style')->name('edit_style');

    #Subscription management
    $admin->route('/subscription/new_subscription')->via('POST')->to('subscription#new_subscription')->name('new_subscription');
    $admin->route('/subscription/subscription_bill')->via('POST')->to('subscription#billing')->name('subscribe');
    $admin->route('/subscription/billing')->via('POST,GET')->to('subscription#subscribe')->name('pay_new_subscription');
    
    $admin->route('/subscription/change_subscription')->via('POST')->to('subscription#change_subscription')->name('change_subscription');
    $admin->route('/subscription/subscription_bill')->via('POST')->to('subscription#billing')->name('change'); 
    $admin->route('/subscription/billing')->via('POST')->to('subscription#subscribe')->name('pay_change_subscription');       

}

1;
