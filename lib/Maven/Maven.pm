use strict;
use warnings;

package Maven::Maven;

# ABSTRACT: The main interface to maven
# PODNAME: Maven::Maven

use Carp;
use Data::Dumper;
use File::ShareDir;
use Log::Any;
use Maven::Xml::Pom;
use Maven::Repositories;
use Maven::SettingsLoader qw(load_settings);

my $logger = Log::Any->get_logger();

sub new {
    return bless( {}, shift )->_init( @_ );
}

sub dot_m2 {
    return shift->user_home( '.m2', @_ );
}

sub _init {
    my ($self, %options) = @_;
    
    $self->{properties} = {
        'env.M2_HOME' => $options{M2_HOME} || $ENV{M2_HOME} || croak( "M2_HOME not defined" ),
        'user.home' => $options{'user.home'} || $ENV{HOME} || $ENV{USERPROFILE}
    };
    
    $self->{settings} = load_settings( 
        $self->m2_home( 'conf', 'settings.xml' ),
        $self->dot_m2( 'settings.xml' ),
        $self->{properties} );

    # some day we should load pom...
    
    $self->_load_active_profiles();

    $self->{repositories} = Maven::Repositories->new()
        ->add_local( $self->{settings}->get_localRepository() );
    foreach my $profile ( @{$self->{active_profiles}} ) {
        my $repositories = $profile->get_repositories();
        if ( $repositories && scalar( @$repositories ) ) {
            foreach my $repository ( @$repositories ) {
                $self->{repositories}->add_repository(
                    $repository->get_url() );
            }
        }
    }
    
    return $self;
}

sub get_property {
    my ($self, $key) = @_;
    $logger->tracef( 'get_property(\'%s\')', $key );
    return $self->{properties}{$key} || $key;
}

sub get_repositories {
    return $_[0]->{repositories};
}

sub _is_active_profile {
    my ($self, $profile) = @_;
}

sub _load_active_profiles {
    my ($self) = @_;

    my @active_profiles = ();

    my %settings_active_profiles = $self->{settings}->get_activeProfiles()
        ? map {$_=>1} @{$self->{settings}->get_activeProfiles()}
        : ();
    foreach my $profile ( @{$self->{settings}->{profiles}} ) {
        if ( $settings_active_profiles{$profile->get_id()} ) {
            push( @active_profiles, $profile );
            next;
        }

        # add support for other ways of being active...
        my $activation = $profile->get_activation();
        if ( $activation ) {
            my $activeByDefault = $activation->get_activeByDefault();
            if ( $activeByDefault && $activeByDefault =~ /^true$/i ) {
                push( @active_profiles, $profile );
                next;
            }
            # not using jdk, so lets ignore it
            # OS is complicated by cygwin, so we bow out for now...
            my $property = $activation->get_property();
            if ( $property && $property->get_name() && $property->get_value()
                && $self->{properties}{$property->get_name()}
                && $self->{properties}{$property->get_name()} eq $property->get_value() ) {
                push( @active_profiles, $profile );
                next;
            }
            my $file = $activation->get_file();
            if ( $file ) {
                my $missing = $file->get_missing();
                if ( $missing && !-f $missing ) {
                    push( @active_profiles, $profile );
                    next;
                }
                my $exists = $file->get_exists();
                if ( $exists && -f $exists ) {
                    push( @active_profiles, $profile );
                    next;
                }
            }
        }
    }
    
    $self->{active_profiles} = \@active_profiles;
}

sub m2_home {
    my ($self, @parts) = @_;
    return File::Spec->catdir( $self->{properties}{'env.M2_HOME'}, @parts );
}

sub user_home {
    my ($self, @parts) = @_;
    return File::Spec->catdir( $self->{properties}{'user.home'}, @parts );
}

1;
