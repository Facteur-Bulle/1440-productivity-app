import type { Metadata, Viewport } from 'next';
import './globals.css';
export const metadata: Metadata = { title: '1440 — Ton temps, en clair', description: 'Un suivi du temps personnel, calme et privé.', applicationName: '1440', manifest: '/manifest.json', appleWebApp: { capable: true, statusBarStyle: 'default', title: '1440' }, icons: { icon: '/icon.svg', apple: '/icon.svg' } };
export const viewport: Viewport = { themeColor: '#f5f3ed', width: 'device-width', initialScale: 1, maximumScale: 1 };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="fr"><body>{children}</body></html>; }
