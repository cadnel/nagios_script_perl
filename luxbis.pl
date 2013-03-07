#! /etc/bin/perl
use strict;
my $secondes_par_jour = 60 * 60 * 24;

my @date = localtime(time() - $secondes_par_jour);
# Le mois est code sur 0..11, et l'annee demarre a 1900, donc on adapte
my ($jour, $mois, $annee)  = ($date[3], $date[4]+1, $date[5]+1900);

if ($jour<10)
{	
			if ($mois<10)
				{
					open (F,"D:\\log\\$annee-0$mois-0$jour\\SyslogCatchAll.txt") || die "Problème d'ouverture:$!";

					while (my $ligne=<F>){
						if ($ligne =~/172.19.20./i)
							{
								open(OUT,">>D:\\log\\$annee-0$mois-0$jour\\luxbis0$mois.0$jour.txt");
								print OUT "$ligne";
							}
											}
				}
	
			else
				{		
					open (F,"D:\\log\\$annee-$mois-0$jour\\SyslogCatchAll.txt") || die "Problème d'ouverture:$!";

					while (my $ligne=<F>){
						if ($ligne =~/172.19.20./i)
							{
								open(OUT,">>D:\\log\\$annee-$mois-0$jour\\luxbis$mois.0$jour.txt");
								print OUT "$ligne";
							}
											}
				}

}

else 
{
			if ($mois<10)
				{
					open (F,"D:\\log\\$annee-0$mois-$jour\\SyslogCatchAll.txt") || die "Problème d'ouverture:$!";

					while (my $ligne=<F>){
						if ($ligne =~/172.19.20./i)
							{
								open(OUT,">>D:\\log\\$annee-0$mois-$jour\\luxbis0$mois.$jour.txt");
								print OUT "$ligne";
							}
										}
				}
	
			else
				{		
					open (F,"D:\\log\\$annee-$mois-$jour\\SyslogCatchAll.txt") || die "Problème d'ouverture:$!";

					while (my $ligne=<F>){
						if ($ligne =~/172.19.20./i)
							{
								open(OUT,">>D:\\log\\$annee-$mois-$jour\\luxbis$mois.$jour.txt");
								print OUT "$ligne";
							}
											}
				}

}

close F;

   
 
 