use strict;
use warnings;

package Maven::Maven;

use File::ShareDir;
use Maven::Xml::Pom;
use Maven::Xml::Settings;

sub new {
    return bless( {}, shift )->_init( @_ );
}

sub _init {
    my ($self, %options) = @_;
    
    $self->{m2_home} = $options{m2_home} || $ENV{M2_HOME};
    $self->{properties} = {
        'user.home' => $options{'user.home'} || $ENV{HOME} || $ENV{USERPROFILE}
    };
    
    my $settings = Maven::Xml::Settings->new( file => 
        File::ShareDir::module_file( 'Maven::Xml::Settings', 'settings.xml' ) );
}

1;