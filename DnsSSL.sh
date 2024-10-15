#!/bin/bash

# Fonction pour générer un certificat SSL auto-signé
generate_ssl_certificate() {
    read -p "Entrez le nom de domaine (DNS) pour le certificat SSL : " domain
    read -p "Entrez le nom du service : " service
    echo "Génération du certificat SSL de $service pour $domain..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/"$domain".key \
        -out /etc/ssl/certs/"$domain".crt \
        -subj "/C=FR/ST=France/L=Paris/O=$service/OU=IT Department/CN=$domain"
    echo "Certificat SSL généré avec succès pour $domain."
}

# Fonction pour configurer un service avec SSL et port personnalisé
configure_service_with_ssl() {
    read -p "Entrez le nom de domaine (DNS) pour configurer le service : " domain
    read -p "Entrez le port sur lequel le service doit écouter : " port
    echo "Configuration du service sur $domain avec SSL sur le port $port..."

    # Exemple pour un serveur Nginx
    echo "
    server {
        listen $port ssl;
        server_name $domain;

        ssl_certificate /etc/ssl/certs/$domain.crt;
        ssl_certificate_key /etc/ssl/private/$domain.key;

        location / {
            proxy_pass http://localhost:$port;  # Rediriger vers le service sur le port spécifié
        }
    }" > /etc/nginx/sites-available/"$domain"

    ln -s /etc/nginx/sites-available/"$domain" /etc/nginx/sites-enabled/
    systemctl reload nginx
    echo "Service configuré avec SSL sur le port $port pour le domaine $domain."
}

# Fonction pour configurer le DNS local et le port associé
configure_dns() {
    read -p "Entrez le nom de domaine (DNS) à configurer localement : " domain
    read -p "Entrez l'adresse IP associée (par défaut : 127.0.0.1) : " ip
    read -p "Entrez le port que vous souhaitez associer à ce domaine (par défaut : 80) : " port
    ip=${ip:-127.0.0.1}
    port=${port:-80}
    echo "Configuration du DNS local pour $domain sur l'adresse IP $ip et le port $port..."

    # Ajouter l'entrée dans le fichier /etc/hosts (DNS local)
    echo "$ip $domain" >> /etc/hosts

    # Exemple d'affichage pour informer de la configuration du port (à personnaliser si nécessaire)
    echo "Le domaine $domain est maintenant associé à l'IP $ip et au port $port."
}

# Menu pour le script
echo "Que souhaitez-vous faire ?"
echo "1. Générer un certificat SSL"
echo "2. Configurer un service avec SSL et un port personnalisé"
echo "3. Configurer le DNS local et associer un port"
read -p "Choisissez une option : " option

case $option in
    1)
        generate_ssl_certificate
        ;;
    2)
        configure_service_with_ssl
        ;;
    3)
        configure_dns
        ;;
    *)
        echo "Option non valide."
        ;;
esac
