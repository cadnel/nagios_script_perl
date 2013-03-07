#!/usr/bin/perl

##################################################################################
##################################################################################
#######################  Made by Tytus Kurek on October 2012  ####################
##################################################################################
##################################################################################
####      This is a Nagios Plugin destined to check the status of IPsec       ####
####              site-to-site VPN tunnels on Cisco ASA devices.              ####
##################################################################################
##################################################################################

use strict;
use vars qw($community $IP $peerIP $peerName);

use Getopt::Long;
use Pod::Usage;

# Subroutines execution

getParameters ();
checkTunnelStatus ();

# Subroutines definition

sub checkTunnelStatus ()	# Checks IPsec site-to-site tunnel status via SNMP
{
	my $OID = '1.3.6.1.4.1.9.9.171.1.2.3.1.7';
	my $version = '2c';

	my $command = "/usr/bin/snmpwalk -v $version -c $community $IP $OID";
	my $result = `$command`;

	if ($result =~ m/^Timeout.*$/)
	{
		my $output = "UNKNOWN! No SNMP response from $IP.";
		my $code = 3;
		exitScript ($output, $code);
	}

	$command = "/usr/bin/snmpwalk -v $version -c $community $IP $OID | grep $peerIP | wc -l";
	$result = `$command`;
	
	my $peer;

	if ($peerName ne '')
	{
		$peer = "$peerIP ($peerName)";
	}

	else
	{
		$peer = $peerIP;
	}

	if ($result == 1)
	{
		my $output = "OK! VPN peer $peer available.";
		my $code = 0;
		exitScript ($output, $code);
	}

	else
	{
		my $output = "CRITICAL! VPN peer $peer unavailable.";
		my $code = 2;
		exitScript ($output, $code);
	}
}

sub exitScript ()	# Exits the script with an appropriate message and code
{
	print "$_[0]\n";
	exit $_[1];
}

sub getParameters ()	# Obtains script parameters and prints help if needed
{
	my $help = '';

	GetOptions ('help|?' => \$help,
		    'C=s' => \$community,
		    'H=s' => \$IP,
		    'I=s' => \$peerIP,
		    'N:s' => \$peerName)

	or pod2usage (1);
	pod2usage (1) if $help;
	pod2usage (1) if (($community eq '') || ($IP eq '') || ($peerIP eq ''));
	pod2usage (1) if (($IP !~ m/^\d+\.\d+\.\d+\.\d+$/) || ($peerIP !~ m/^\d+\.\d+\.\d+\.\d+$/));

=head1 SYNOPSIS

check_asa_vpn.pl [options] (-help || -?)

=head1 OPTIONS

Mandatory:

-H	IP address of monitored Cisco ASA device

-C	SNMP community

-I	IP address of peer VPN

Optional:

-N	Name of peer VPN

=cut
}
