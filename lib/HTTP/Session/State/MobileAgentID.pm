package HTTP::Session::State::MobileAgentID;
use strict;
use warnings;
use 5.00800;
our $VERSION = '0.45';

use HTTP::Session::State::Base;
use HTTP::MobileAgent 0.28;
use Net::CIDR::MobileJP;

__PACKAGE__->mk_ro_accessors(qw/mobile_agent check_ip cidr/);

sub new {
    my $class = shift;
    my %args = ref($_[0]) ? %{$_[0]} : @_;
    # check required parameters
    for (qw/mobile_agent/) {
        Carp::croak "missing parameter $_" unless $args{$_};
    }
    # set default values
    $args{check_ip} = exists($args{check_ip}) ? $args{check_ip} : 1;
    $args{permissive} = exists($args{permissive}) ? $args{permissive} : 1;
    $args{cidr}       = exists($args{cidr}) ? $args{cidr} : Net::CIDR::MobileJP->new();
    bless {%args}, $class;
}

sub get_session_id {
    my ($self, $req) = @_;

    my $ma = $self->mobile_agent;
    Carp::croak "this module only supports docomo/softbank/ezweb" unless $ma->is_docomo || $ma->is_softbank || $ma->is_ezweb;

    my $id = $ma->user_id();
    if ($id) {
        if ($self->check_ip) {
            my $ip = $ENV{REMOTE_ADDR} || (Scalar::Util::blessed($req) ? $req->address : $req->{REMOTE_ADDR}) || die "cannot get client ip address";
            if ($self->cidr->get_carrier($ip) ne $ma->carrier) {
                die "SECURITY: invalid ip($ip, $ma, $id)";
            }
        }
        return $id;
    } else {
        my $ip = $ENV{REMOTE_ADDR} || (Scalar::Util::blessed($req) ? $req->address : $req->{REMOTE_ADDR}) || 'UNKNOWN';
        my $ua = $ma->user_agent();
        die "cannot detect mobile id from: ($ua, $ip)";
    }
}

sub response_filter { }


1;
__END__

=encoding utf8

=head1 NAME

HTTP::Session::State::MobileAgentID - Maintain session IDs using mobile phone's unique id

=head1 SYNOPSIS

    HTTP::Session->new(
        state => HTTP::Session::State::MobileAgentID->new(
            mobile_agent => HTTP::MobileAgent->new($r),
        ),
        store => ...,
        request => ...,
    );

=head1 DESCRIPTION

Maintain session IDs using mobile phone's unique id

=head1 CONFIGURATION

=over 4

=item mobile_agent

instance of L<HTTP::MobileAgent>

=item check_ip

check the IP address in the carrier's cidr/ or not?
see also L<Net::CIDR::MobileJP>

=item cidr

The object have B<get_carrier($ip)> method like L<Net::CIDR::MobileJP>.

If not provided to constructor, this class create new instance of Net::CIDR::MobileJP automatically.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

L<HTTP::MobileAgent>, L<HTTP::Session>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut