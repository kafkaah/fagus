# Fagus - Un système de notification par e-mail simple et robuste

Fagus est un outil en ligne de commande conçu pour envoyer des notifications par e-mail via une API Google Apps Script. Il est pensé pour être utilisé dans des scripts d'automatisation (sauvegardes, tâches cron, etc.) de manière fiable et centralisée.

## Principes

- **Logique centralisée :** Le "moteur" du script est hébergé sur un Gist secret, permettant des mises à jour instantanées sur toutes les instances sans avoir à redéployer le script.
- **Configuration locale :** Les informations sensibles (mot de passe, URL de l'API) sont stockées dans un fichier de configuration local et ne sont jamais dans le code central.
- **Résilience :** En cas d'impossibilité de télécharger la dernière version du moteur, Fagus utilise la dernière bonne version mise en cache localement, assurant que les notifications continuent de fonctionner.
- **Robustesse :** Gère les logs très volumineux, les caractères spéciaux et inclut une limitation de débit pour éviter les tempêtes d'e-mails.

## Installation

1.  **Clonez ce dépôt :**
    ```bash
    git clone https://github.com/kafkaah/fagus.git
    cd fagus
    ```

2.  **Rendez le lanceur exécutable :**
    ```bash
    chmod u+x fagus.sh
    ```

## Configuration

Avant la première utilisation, vous devez configurer vos informations locales.

1.  **Éditez le fichier `fagus.conf` :**
    ```bash
    nano fagus.conf
    ```
2.  **Modifiez les valeurs suivantes :**
    -   `PASSWORD`: Remplacez `"CHANGEME"` par le mot de passe que vous avez défini dans votre script Google Apps.
    -   `API_URL_ID`: Remplacez `"CHANGEME"` par l'identifiant de déploiement de votre application web Google Apps Script.
    -   `ORIGIN`: Changez la valeur par défaut pour identifier la machine ou l'application (ex: `"MonServeurWeb"`).

## Utilisation

Le script `fagus.sh` peut être appelé depuis n'importe quel autre script ou directement depuis la ligne de commande.

### Syntaxe

```bash
./fagus.sh <"message" ou /chemin/vers/fichier.log> [nom_du_sous_systeme] [cooldown_en_minutes]
