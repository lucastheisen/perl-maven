use strict;
use warnings;

package Maven::Maven;

# ABSTRACT: The main interface to maven
# PODNAME: Maven::Maven

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
    $self->{repositories} = Maven::Repositories->new()
        ->add_local( $self->{settings}->get_localRepository() );
    
    return $self;
}

sub get_property {
    my ($self, $key) = @_;
    $logger->tracef( 'get_property(\'%s\')', $key );
    return $self->{properties}{$key} || $key;
}

sub m2_home {
    my ($self, @parts) = @_;
    return File::Spec->catdir( $self->{properties}{'env.M2_HOME'}, @parts );
}

sub repositories {
    return $_[0]->{repositories};
}

sub user_home {
    my ($self, @parts) = @_;
    return File::Spec->catdir( $self->{properties}{'user.home'}, @parts );
}

1;