use strict;
use warnings;

package Maven::LwpAgent;

# ABSTRACT: An agent for downloading artifacts using Lwp::UserAgent
# PODNAME: Maven::LwpAgent

use parent qw(Maven::Agent);

use File::Temp;
use Log::Any;
use LWP::UserAgent;

my $logger = Log::Any->get_logger();

sub _download_remote {
    my ($self, $artifact, $file) = @_;

    $file ||= Maven::LwpAgent::DownloadedFile->new();

    $self->{agent}->get($artifact->get_uri(), ':content_file' => "$file");

    return $file;
}

sub _init {
    my $self = shift;

    $self->Maven::Agent::_init(@_);

    my %options = @_;

    if ($options{agent}) {
        $self->{agent} = $options{agent};
    }
    else {
        $self->{agent} = LWP::UserAgent->new();
        $self->{agent}->env_proxy();
    }
    
    return $self;
}

package Maven::LwpAgent::DownloadedFile;

# Wraps a temp file to hold a reference so as to keep the destructor from
# getting called.  It will provide the filename when used as a string.

use overload q{""} => 'filename', fallback => 1;

sub new {
    my $self = bless({}, shift);
    my $file = File::Temp->new();
    
    $self->{handle} = $file;
    $self->{name} = $file->filename();
    
    return $self;
}

sub filename {
    return $_[0]->{name};
}

1;
