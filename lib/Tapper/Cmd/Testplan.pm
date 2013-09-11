package Tapper::Cmd::Testplan;

use 5.010;
use Moose;

use Cwd;
use Try::Tiny;
use YAML::Syck;
use Tapper::Model 'model';
use Tapper::Reports::DPath::TT;
use File::Slurp 'slurp';
use Perl6::Junction 'any';

extends 'Tapper::Cmd';

=head1 NAME

Tapper::Cmd::Testplan - Backend functions for manipluation of testplan instances in the database

=head1 SYNOPSIS

This project offers functions to add, delete or update testplan
instances in the database.

    use Tapper::Cmd::Testplan;

    my $cmd = Tapper::Cmd::Testplan->new();
    my $plan_id = $cmd->add($plan);
    $cmd->update($plan_id, $new_plan);
    $cmd->del($plan_id);

    ...

=head1 FUNCTIONS

=cut

=head2 get_module_for_type

Get the name of the Tapper::Cmd module that is reponsible for a given
type. The name of the module is optimized for the Tapper developer but
the type given in the testplan should be telling for the testplan user.

@param string - type

@return string - name of the responsible module

=cut

sub get_module_for_type
{
        my ($self, $type) = @_;
         given (lc($type)){
                when('multitest') { return "Tapper::Cmd::Testrun"; }
                when('scenario')  { return "Tapper::Cmd::Scenario" }
                default           { $type = ucfirst($type); return "Tapper::Cmd::$type"; }
        }
}


=head2 add

Add a new testplan instance to database and create the associated
testruns. The function expects a string containing the evaluated test
plan content and a path.

@param    string - plan content
@param    string - path
@optparam string - name

@return int - testplan instance id

@throws die()

=cut

sub add {
        my ($self, $plan_content, $path, $name) = @_;

        my @plans = YAML::Syck::Load($plan_content);
        # use Data::Dumper;
        # print STDERR "plans: ".Dumper($plan_content);
        # print STDERR "plans: ".Dumper(\@plans);

        my $instance = model('TestrunDB')->resultset('TestplanInstance')->new({evaluated_testplan => $plan_content,
                                                                               path => $path,
                                                                               name => $name,
                                                                              });
        $instance->insert;

        my @testrun_ids;
        foreach my $plan (@plans) {
                die "Missing plan type for the following testplan: \n".Dump($plan) unless $plan->{type};
                my $module = $self->get_module_for_type($plan->{type});

                try {
                        eval "use $module";
                } catch {
                        die "Can not load '$module' to handle testplan of type $plan->{type}: $!";
                };

                my $handler = "$module"->new();
                my $description = $plan->{testplan_description} || $plan->{description};
                my @new_ids = $handler->create($description, $instance->id);
                push @testrun_ids, @new_ids;
        }
        return $instance->id;
}



=head2 del

Delete testrun with given id from database. Please not that this does
not remove the associated testruns.


@param int - testplan instance id

@return success - 0
@return error - exception

@throws die()

=cut

sub del {
        my ($self, $id) = @_;
        my $testplan = model('TestrunDB')->resultset('TestplanInstance')->find($id);
        while(my $testrun = $testplan->testruns->next) {
                if ($testrun->testrun_scheduling->status eq 'running') {
                        my $message = model('TestrunDB')->resultset('Message')->new({testrun_id => $testrun->id,
                                                                                     type       => 'state',
                                                                                     message    => {
                                                                                                    state => 'quit',
                                                                                                    error => 'Testplan cancelled'
                                                                                                   }});
                        $message->insert();
                }
                $testrun->testrun_scheduling->testrun->testplan_id(undef);
                $testrun->testrun_scheduling->testrun->update;
                $testrun->testrun_scheduling->status('finished');
                $testrun->testrun_scheduling->update;
        }
        $testplan->delete();
        return 0;
}

=head2 rerun

Reapply the evaluated testplan of the given testplan instance.

@param int - testplan instance id

@return success - new testplan id
@return error   - exception

@throws die()

=cut

sub rerun
{
        my ($self, $id) = @_;

        my $testplan = model('TestrunDB')->resultset('TestplanInstance')->find($id);
        die "No testplan with ID $id\n" unless $testplan;

        return $self->add($testplan->evaluated_testplan, $testplan->path, $testplan->name);
}

=head2 parse_path

Get the test plan path from the filename. This is a little more tricky
since we do not simply want the dirname but kind of an "un-prefix".

@param string - file name

@return string - test plan path

=cut

sub parse_path
{
        my ($self, $filename) = @_;
        $filename = Cwd::abs_path($filename);
        my $basedir = Tapper::Config->subconfig->{paths}{testplan_path};
        # splitting filename at basedir returns an array with the empty
        # string before and the path after the basedir
        my $path = (split $basedir, $filename)[1];
        return $path;
}

=head2 get_shortname

Get the shortname for this testplan.

@param string - plan text

@return string - shortname

=cut

sub get_shortname{
        my ($self, $plan) = @_;

        foreach my $line (split "\n", $plan) {
                if ($line =~/^###\s*(?:short)?name\s*:\s*(.+)$/i) {
                        return $1;
                }
        }
        return;
}


=head2 guide

Get self documentation of a testplan file.

@param string - file name of testplan file

@return success - documentation text

@throws - die()

=cut

sub guide
{
        my ($self, $file, $substitutes, $include) = @_;
        my $text;
        my $guide = $self->apply_macro($file,
                                       $substitutes,
                                       $include);

        my @guide = grep { m/^###/ } split (qr/\n/, $guide);
        $text = "Self-documentation:\n";
        $text = join "\n", map { my $l = $_; $l =~ s/^###/ /; "$l" } @guide;
        return $text;
}

=head2 testplannew

Create a testplan instance from a file.

@param hash ref - options containing

required:
* file: string, path of the testplan file
* substitutes: hash ref, substitute variables for Template Toolkit

optional:
* include: array ref of strings containing include paths
* path: string, alternative path instead of real path
* name: string, overwrite shortname in plan

@return success - testplan id

@throws die

=cut

sub testplannew {
        my ($self, $opt) = @_;

        my $plan = $self->apply_macro($opt->{file}, $opt->{substitutes}, $opt->{include});
        my $path   = $opt->{path} || $self->parse_path($opt->{file});
        my $shortname = $opt->{name} || $self->get_shortname($plan);
        return $self->add($plan, $path, $shortname);
}

=head2 query

Get information of one testplan.

@param int - testplan id

@return - hash ref -
* status - one of 'schedule', 'running', 'pass', 'fail'
* complete_percentage - percentage of finished testruns
* started_percentage  - percentage of running and finished testruns
* success_percentage  - average of success rates of finished testruns

@throws - die

=cut

sub query
{
        my ($self, $id) = @_;
        my $results;
        my $testplan = model('TestrunDB')->resultset('TestplanInstance')->find($id);
        die "No testplan with id '$id'\n" if not $testplan;

        my ($started, $complete, $success_sum) = (0,0,0);
        for my $testrun ($testplan->testruns->all) {
                $started++  if $testrun->testrun_scheduling->status eq any('running', 'finished');
                if ($testrun->testrun_scheduling->status eq 'finished') {
                        $complete++ ;
                        my $success_obj = model('ReportsDB')->resultset('ReportgroupTestrunStats')->find({testrun_id => $testrun->id});
                        $success_sum+= int($success_obj->success_ratio);
                }
        }
        my $result = {
                      complete_percentage => ($complete * 100) / $testplan->testruns->count,
                      started_percentage  => ($started * 100) / $testplan->testruns->count,
                      success_percentage  => $complete ? $success_sum / $complete : undef,
                     };
        if ($started == 0) {
                $result->{status} = 'schedule';
        }
        elsif ($started > 0 and $complete < $testplan->testruns->count) {
                $result->{status} = 'running';
        }
        else {
                if ($result->{success_percentage} < 100) {
                        $result->{status} = 'fail';
                } else {
                        $result->{status} = 'pass';
                }
        }

        return $result;
}


1; # End of Tapper::Cmd::Testplan
