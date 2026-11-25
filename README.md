# 1440 — Ton temps, en clair

Application Next.js mobile-first pour observer la répartition de ses journées. Les périodes restent disponibles hors ligne et se synchronisent entre les appareils après connexion par lien e-mail.

## Lancer localement

Prérequis : Node.js 20.9+ et npm.

```bash
npm install
npm run dev
```

Puis ouvrir http://localhost:3000. Pour préparer un déploiement :

```bash
npm run build
npm start
```

## Installation PWA

Ouvre le site depuis Chrome ou Safari puis choisis « Ajouter à l’écran d’accueil » / « Installer l’application ». Le service worker met en cache l’écran d’accueil et ses éléments de base.

## Données et synchronisation

- Les périodes sont conservées dans le stockage local pour rester accessibles hors ligne.
- En se connectant avec un lien e-mail, l'application fusionne l'historique local avec le compte Supabase 1440, puis synchronise les modifications.
- Les données Supabase sont limitées à leur propriétaire avec Row Level Security.
- Le navigateur utilise uniquement l'URL Supabase et une clé **publishable**. Ne jamais ajouter une clé `service_role`, `secret` ou un mot de passe de base de données au préfixe `NEXT_PUBLIC_`.
- La base est dans le projet Supabase séparé `fiosofqjshsgmcnghtpy` ; ne pas remplacer ces valeurs par celles de Gravimot.

Variables d'environnement nécessaires : `NEXT_PUBLIC_SUPABASE_URL` et `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` (voir `.env.example`). Dans Supabase, ajouter l'URL de production de l'application aux URL de redirection autorisées par Auth, ainsi que `http://localhost:3000/**` pour le développement local.

Les exports JSON et CSV restent disponibles. Garde une sauvegarde JSON périodique, en particulier avant d'importer des données.
