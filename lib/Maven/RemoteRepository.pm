use strict;
use warnings;

package Maven::RemoteRepository;

# ABSTRACT: An repository from which to resolve artifacts
# PODNAME: Maven::RemoteRepository

use parent qw(Maven::Repository);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors( qw(agent) );

use Log::Any;
use Maven::Xml::Metadata;

my $logger = Log::Any->get_logger();

sub _detect_latest_snapshotVersion {
    my ($self, $base_url, $extension, $classifier) = @_;

    $logger->debug( 'loading metadata from ', $base_url );
    my $metadata = Maven::Xml::Metadata->new( agent => $self->{agent},
        url => "$base_url/$self->{metadata_filename}" );
    return if ( ! $metadata );

    my $latest_snapshot;
    foreach my $snapshot_version ( @{$metadata->get_versioning()->get_snapshotVersions()} ) {
        if ( $extension && $extension eq $snapshot_version->get_extension() ) {
            if ( !$classifier || $classifier eq $snapshot_version->get_classifier() ) {
                $latest_snapshot = $snapshot_version;
                last;
            }
        }
    }
    return $latest_snapshot;
}

sub _detect_latest_version {
    my ($self, $base_url) = @_;

    $logger->debug( 'loading metadata from ', $base_url );
    my $metadata = Maven::Xml::Metadata->new( agent => $self->{agent},
        url => "$base_url/$self->{metadata_filename}" );
    return if ( ! $metadata );
    return $metadata->get_versioning()->get_latest();
}

sub _has_version {
    my ($self, $url) = @_;
    my $has_version = $self->{agent}->head( $url )->is_success();
    $logger->debug(($has_version ? 'YES: ' : 'NO: '), 
        '_has_version(', $url, ')');
    return $has_version;
}

sub _init {
    my ($self, $url, %args) = @_;

    $self->Maven::Repository::_init($url);
    $self->{agent} = $args{agent};
    $self->{metadata_filename} = $args{metadata_filename} 
        || 'maven-metadata.xml';

    return $self;
}

1;
