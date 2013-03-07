#! /usr/bin/perl -w

##################################################################
# Auteur : Legras olivier Contact : webmaster@croc-informatique.fr
# Site : http://www.croc-informatique.fr
# Derniere modification : 16/07/09
# Version : 0.1
# Ce script permet de vérifier qu'il n'y a pas d'erreurs sur les interfaces
# de nos équipements cisco
##################################################################

#Bibliotheques
use strict;
use Tie::IxHash;
use Time::localtime;
use Net::SNMP(qw(snmp_event_loop oid_lex_sort));
use Getopt::Long;

# Declaration des variables
my @tableau; my @tableau_resultat;
my $ligne;
my $colonne; my @out; my $nom_fichier;
my $i; my $i2; my $i3;
my $nbr_lignes; my $nbr_colonnes;my $HOSTADDRESS; my $help;my @ancien;my  $contenu_fichier; my $taille_tableau;
tie my %oid, "Tie::IxHash";

#Constantes A Configurer

my $critical = 1;
my $community = "ITt1g0";
my $timeout=15;
my $ERROR =0;
my $CHEMIN_TEMP="/tmp";
my $retour=0;
my $critical_phase=0;
my $fichier_neuf=0;

#Etats Nagios

my $STATE_OK="0";
my $STATE_WARNING="1";
my $STATE_CRITICAL="2";
my $STATE_UNKNOWN="3";

#Définition des OID
%oid = (
   ifName             => "1.3.6.1.2.1.31.1.1.1.1",
   ifInDiscards       => "1.3.6.1.2.1.2.2.1.13",
   ifInErrors       => "1.3.6.1.2.1.2.2.1.14",
   ifOutDiscards    => "1.3.6.1.2.1.2.2.1.19",
   ifoutErrors      => "1.3.6.1.2.1.2.2.1.20"
   );


#Arguments :

my $USAGE = <<EOF;
usage: $0 -options
  Options:
    -help             Affiche cet écran
    -HOSTADDRESS      Adresse du serveur Vulture
    -C                Communauté

    Exemple :
    ./check_cisco_io_errors.pl -HOSTADDRESS 192.168.0.1 -C public
EOF
# Commandes optionnelles
eval{
&GetOptions("help"    => \$help,
            "HOSTADDRESS:s"    => \$HOSTADDRESS,
            "C:s"     => \$community,
            "cr:s"     => \$critical);
};
$ERROR=2 if $@;
if ($ERROR==2){print "CRITICAL: ARGUMENT INCONNU $@";exit $STATE_UNKNOWN;}

if ($help) {
    die "$USAGE";
}
unless ($HOSTADDRESS){
print "CRITICAL : PAS D'ARGUMENTS";
 exit $STATE_CRITICAL;
}

#On teste que le repertoire temp existe
unless (-d $CHEMIN_TEMP){
   print "UNKNOWN Chemin ".$CHEMIN_TEMP." existe pas";
   exit $STATE_UNKNOWN;

}

#Paramétrage SNMP
my %snmp = (
   timeout => 7,
   );
#chomp($snmp{community} = $community);
chomp($snmp{hostaddress} = $HOSTADDRESS);

my $hostname="172.18.6.15";
# Ouverture de session SNMP
($snmp{session}, $snmp{error}) = Net::SNMP -> session(
                  -hostname  => $HOSTADDRESS,
                  -community => $community,
                  -timeout   => $snmp{timeout}
);
unless(defined($snmp{session})) {
      printf("\n Error: %s\n", $snmp{error});
      exit 1;
}

# Recuperation du resultat de la requete smtp

$ligne=0;
for (keys %oid) {
   
   if (defined($snmp{response} = $snmp{session} -> get_table($oid{$_}))) {
      $colonne=0;
      for (oid_lex_sort(keys(%{$snmp{response}}))) {
         $tableau[$ligne][$colonne]=$snmp{response} -> {$_};
         $colonne=$colonne + 1;
         }
   } else {
       print($snmp{session} -> error(), ",\n");
       exit $STATE_UNKNOWN;
       }
       $ligne = $ligne + 1;
      
}


#Taille du tableau :
$nbr_lignes = @{$tableau[0]};
$nbr_colonnes = @tableau;

# Recuperation 
$colonne=0;

my $i4;
for ($i=1;$i<$nbr_colonnes;$i++){
  for ($i2=0;$i2<$nbr_lignes;$i2++){
     if (defined($tableau[$i][$i2])){
        if ($tableau[$i][$i2] > $critical){
         
         for ( $i4=0;$i4<$nbr_colonnes;$i4++){
           $tableau_resultat[$i4][$colonne]=$tableau[$i4][$i2];
           
         }
         $colonne++;
         }
      }
  }
}

#Taille du tableau :
eval{
$nbr_lignes = @{$tableau_resultat[0]};
};
$ERROR=2 if $@;
if ($ERROR==2){ print "OK : PAS DE PROBLEME"; exit $STATE_OK;}
$nbr_colonnes = @tableau_resultat;
my @descr=keys %oid;
my $nbr_descr= @descr;
#On affiche le resultat
if ($nbr_lignes!=0){

    for ($i2=0;$i2<$nbr_lignes;$i2++){
       # A modifier si plus d OID 
    
        for ($i=0;$i<$nbr_colonnes;$i++){
            $retour=0;
            if ($i==0){
               my $nom_interface = $tableau_resultat[$i][$i2];
               # On remplace les \
               $nom_interface =~ s/\//-/g; 
               
               $nom_fichier=$CHEMIN_TEMP."/tmp-nagios-io-errors-".$HOSTADDRESS."-".$nom_interface.".txt";
               
               #On verifie si un fichier correspondant est cree
               if (-f $nom_fichier){
                                
                  open (FILE2, "$nom_fichier") or die "Can't open ".$nom_fichier ;
                 while ($ligne = <FILE2>) {
                     @ancien = split(/:/, $ligne);
                  } 
                  close FILE2;          
               }
               else{
                  open FILE, "> $nom_fichier" or die "Can't open ".$nom_fichier;
                  $fichier_neuf=1;
               close FILE;
               $ancien[0]=$tableau_resultat[$i][$i2];
               
               }
            }else {
                $taille_tableau=@ancien;
                if ($taille_tableau==$nbr_colonnes){  
                     #On verifie qu'il n'y a pas d'antécedent
                     if (defined($ancien[$i])){
                       if ($tableau_resultat[$i][$i2] > $ancien[$i] ){
                          if ($retour==0){
                            if ($critical_phase==0){
                              print "**CRITICAL** :";
                              $critical_phase=1;
                            }
                            print "$tableau_resultat[0][$i2] :";
                          }
                          print $descr[$i]."=".$tableau_resultat[$i][$i2].", ";
                          $retour=1;
                       }
                     }
                }
                else {
                   $ancien[$i]=$tableau_resultat[$i][$i2];
                }
            }
        }
        # Si le fichier vient d'etre créé, il faut retirer le champ du fichier
         if ($taille_tableau>$nbr_colonnes){
              $taille_tableau=$taille_tableau-1;
        }
        # On prepare le contenu du fichier
        $contenu_fichier=$ancien[0].":"; # On affiche le titre
        for ($i=1;$i<$taille_tableau-1;$i++){
              $contenu_fichier.=$ancien[$i].":";
        }
        $contenu_fichier.=$ancien[$i]; # affiche le champ pour ne pas avoir les : après
        #Ajout d'un champ pour ne pas avoir un code critique au prochain check
        if ($fichier_neuf==1){
          $contenu_fichier.=":1";
        }
        #On rempli le fichier
        open FILE, "> $nom_fichier" or die "Can't open ".$nom_fichier;
        print FILE $contenu_fichier;
        close FILE;
        # On réinitialise la variable
    }
  if ($critical_phase==0){
    print "OK : PAS DE NOUVELLES ERREURS";
    exit $STATE_OK;
    
  }
  else{
    exit $STATE_CRITICAL;
  }
  
}
else{
print "OK : PAS D'ERREURS";
}
exit $STATE_OK;