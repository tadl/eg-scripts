#!/usr/bin/perl

# Copyright 2011 Traverse Area District Library
# Author: Jeff Godin

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
# 

# Script to do a mass re-calculation of system standing penalies 
# Useful for updating penalties after policy/config changes
#

# An example query to fetch patron IDs to re-calculate
# 
# -- select patron ids who have a PATRON_EXCEEDS_FINES penalty
# -- with relevant home_ou and whose fines are now acceptable
# 
# select au.id from actor.usr as au 
# join actor.usr_standing_penalty as ausp on (ausp.usr = au.id)
# left join money.materialized_billable_xact_summary as mmbxs on (mmbxs.usr = au.id)
# where au.home_ou between START_HOME_OU and END_HOME_OU
# and ausp.standing_penalty = 1
# group by au.id
# having sum(mmbxs.balance_owed) < 25;
# 

# Example usage:
# ./recalc_penalties.pl -f au_ids_to_recalc.txt
#

use strict; use warnings;

use LWP;
use Getopt::Std;
use JSON::XS;

my $auth = ""; # an evergreen session token with appropriate rights
my $gateway = "https://evergreen.example.org/osrf-gateway-v1";
my $sleep_duration = 3;

my %args;
getopt("f", \%args);

my $id_file = $args{'f'};

open(my $IDFILE, $id_file);

my $browser = LWP::UserAgent->new;

while (my $line = <$IDFILE>) {
    chomp($line);
    print "Updating penalties for user " . $line . " ... ";

    my $url = $gateway . '?service=open-ils.actor&method=open-ils.actor.user.penalties.update&param="' . $auth . '"&param=' . $line;

    my $response = $browser->get($url);

    die "Error!\n ", $response->status_line,
        "\n Aborting" unless $response->is_success;

    my $content = $response->content;

    my $decoded = decode_json($content);

    print "OK" if ($decoded->{status} == "200");

    sleep($sleep_duration);

    print "\n";
}

