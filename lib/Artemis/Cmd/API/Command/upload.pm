package Artemis::Cmd::API::Command::upload;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use IO::Socket;
use Artemis::Config;
use Artemis::Model 'model';
use File::Slurp 'slurp';
use Data::Dumper;
use Moose;

sub abstract {
        'Upload and attach a file to a report'
}

sub opt_spec {
        return (
                [ "verbose",       "some more informational output" ],
                [ "reportid=s",    "INT; the testrun id to change", ],
                [ "file=s",        "STRING; the file to upload, use '-' for STDIN", ],
                [ "contenttype=s", "STRING; content-type, default 'application/octed-stream', use 'plain' for easy viewing in browser", ],
               );
}

sub usage_desc
{
        my $allowed_opts = join ' ', map { '--'.$_ } _allowed_opts();
        "artemis-api upload --reportid=s --file=s [ --contenttype=s ]";
}

sub _allowed_opts {
        my @allowed_opts = map { $_->[0] } opt_spec();
}

sub validate_args {
        my ($self, $opt, $args) = @_;

        #         print "opt  = ", Dumper($opt);
        #         print "args = ", Dumper($args);

        say "Missing argument --reportid" unless $opt->{reportid};
        say "Missing argument --file"     unless $opt->{file};

        # -- file constraints --
        my $file    = $opt->{file};
        my $file_ok = $file eq '-' || -r $file;
        say "Error: file '$file' must be readable or STDIN." unless $file_ok;

        # -- report constraints --
        my $reportid  = $opt->{reportid};
        my $report    = model('ReportsDB')->resultset('Report')->find($reportid);
        $report    = model('ReportsDB')->resultset('Report')->find($reportid);
        my $report_ok = $report;
        say "Error: report '$reportid' must exist." unless $report_ok;

        return 1 if $opt->{reportid} && $file_ok && $report_ok;
        die $self->usage->text;
}

sub run
{
        my ($self, $opt, $args) = @_;
        $self->upload ($opt, $args);
}

sub read_file
{
        my ($self, $opt, $args) = @_;

        my $file = $opt->{file};
        my $content;

        # read from file or STDIN if filename == '-'
        if ($file eq '-') {
                $content = read_file (\*STDIN);
        } else {
                $content = read_file ($file);
        }
        return $content;
}


sub upload
{
        my ($self, $opt, $args) = @_;

        my $host = Artemis::Config->subconfig->{report_server};
        my $port = Artemis::Config->subconfig->{report_api_port};

        my $reportid    = $opt->{reportid};
        my $file        = $opt->{file};
        my $contenttype = $opt->{contenttype} || '';
        my $content     = $self->read_file($opt, $args);

        my $cmdline = "#! upload $reportid $file $contenttype";
        say Dumper("UPLOAD", $opt, $args);

        my $REMOTEAPI = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port);
        my $oldfh     = select $REMOTEAPI;
        say $REMOTEAPI $cmdline;
        print $REMOTEAPI $content; # no additional \n!
        select($oldfh);
}

# perl -Ilib bin/artemis-api upload --file=/var/log/messages --report_id=552 --file ~/xyz     --contenttype plain
# perl -Ilib bin/artemis-api upload --file=/var/log/messages --report_id=552 --file=$HOME/xyz --contenttype plain

1;
