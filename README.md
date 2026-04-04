# Archive Retriever

Script de restauration autonome pour récupérer des backups chiffrés stockés sur Google Cloud Storage (classe Archive).

## Principe

Les données sont stockées sur GCS dans le bucket `archives-valgui` :
- **Classe de stockage** : Archive (coût minimal, frais de récupération ~0,05 $/Go)
- **Chiffrement** : couche [rclone crypt](https://rclone.org/crypt/) (noms de fichiers et contenu chiffrés)
- **Zone** : US multi-région

Le script crée une config rclone temporaire, configure les remotes GCS + crypt, et lance le téléchargement. Il ne dépend d'aucune installation rclone existante.

## Prérequis

- [rclone](https://rclone.org/install/) installé (`sudo apt install rclone` ou équivalent)
- Les credentials Google Cloud (Client ID + Client Secret)
- Les mots de passe de chiffrement (password + salt)

## Configuration

Remplir les variables en haut de `restore.sh` :

```bash
MY_BUCKET="archives-valgui"
MY_PASS="..."        # mot de passe rclone crypt
MY_SALT="..."        # salt rclone crypt
CLIENT_ID="...apps.googleusercontent.com"
CLIENT_SECRET="..."
```

## Utilisation

```bash
chmod +x restore.sh

# Voir le contenu sans télécharger (pas de frais de récupération)
./restore.sh --dry-run

# Lancer la restauration complète
./restore.sh
```

Les fichiers sont téléchargés et déchiffrés dans `./restored_data`.
