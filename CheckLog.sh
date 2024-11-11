#!/bin/bash

# Script de vérification de sécurité pour Ubuntu
# Ce script analyse le système pour détecter des activités suspectes

# Vérifier les authentifications réussies et échouées
echo "==== Journaux d'authentification ===="
sudo grep -Ei "failed|accepted|failure" /var/log/auth.log | tail -n 50
echo -e "\n"

# Vérifier les nouveaux utilisateurs ajoutés au système
echo "==== Nouveaux utilisateurs ajoutés récemment ===="
sudo awk -F: '{ if ($3 >= 1000 && $3 != 65534) print $1" UID="$3" GID="$4 }' /etc/passwd
echo -e "\n"

# Vérifier les membres du groupe sudo
echo "==== Membres du groupe sudo ===="
getent group sudo
echo -e "\n"

# Examiner les processus en cours
echo "==== Processus actifs suspects ===="
sudo ps aux --sort=-%cpu | head -n 15
echo -e "\n"

# Analyser les connexions réseau actives
echo "==== Connexions réseau actives ===="
sudo netstat -tulpn
echo -e "\n"

# Vérifier les tâches planifiées pour root
echo "==== Tâches planifiées pour root ===="
sudo crontab -l
echo -e "\n"

# Vérifier les tâches planifiées pour tous les utilisateurs
echo "==== Tâches planifiées pour les autres utilisateurs ===="
for user in $(cut -f1 -d':' /etc/passwd); do
    crontab -u $user -l 2>/dev/null | grep -v "^#"
done
echo -e "\n"

# Rechercher des fichiers récemment modifiés
echo "==== Fichiers modifiés au cours des 5 derniers jours ===="
sudo find / -type f -mtime -5 2>/dev/null | head -n 50
echo -e "\n"

# Vérifier les clés SSH non autorisées
echo "==== Clés SSH autorisées pour root ===="
sudo cat /root/.ssh/authorized_keys 2>/dev/null
echo -e "\n"

echo "==== Clés SSH autorisées pour les utilisateurs ===="
for dir in /home/*; do
    if [ -d "$dir/.ssh" ]; then
        echo "Utilisateur $(basename $dir):"
        cat "$dir/.ssh/authorized_keys" 2>/dev/null
        echo -e "\n"
    fi
done

# Analyser les services qui démarrent automatiquement
echo "==== Services activés au démarrage ===="
sudo systemctl list-unit-files --type=service | grep enabled
echo -e "\n"

# Lister les paquets récemment installés ou mis à jour
echo "==== Paquets installés ou mis à jour récemment ===="
grep " install " /var/log/dpkg.log | tail -n 20
echo -e "\n"

# Analyser les logs du pare-feu UFW
echo "==== Dernières entrées du log UFW ===="
sudo tail -n 50 /var/log/ufw.log 2>/dev/null
echo -e "\n"

# Utiliser rkhunter pour détecter des rootkits
echo "==== Analyse des rootkits avec rkhunter ===="
if ! command -v rkhunter &> /dev/null; then
    echo "rkhunter n'est pas installé. Installation en cours..."
    sudo apt-get update && sudo apt-get install -y rkhunter
fi
sudo rkhunter --update
sudo rkhunter --check --skip-keypress
echo -e "\n"

echo "==== Analyse terminée ===="
