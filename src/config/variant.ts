type Variant = 'full' | 'tech' | 'finance' | 'happy';

const VARIANT_STORAGE_KEY = 'worldmonitor-variant';

function readStoredVariant(): Variant | null {
  if (typeof window === 'undefined') return null;
  const stored = localStorage.getItem(VARIANT_STORAGE_KEY);
  if (stored === 'full' || stored === 'tech' || stored === 'finance' || stored === 'happy') {
    return stored;
  }
  return null;
}

function isOfficialWorldMonitorHost(hostname: string): boolean {
  return hostname === 'worldmonitor.app' || hostname.endsWith('.worldmonitor.app');
}

export function shouldUseLocalVariantSwitch(): boolean {
  if (typeof window === 'undefined') return false;

  const isTauri = '__TAURI_INTERNALS__' in window || '__TAURI__' in window;
  if (isTauri) return true;

  const host = window.location.hostname;
  if (host === 'localhost' || host === '127.0.0.1') return true;

  // Self-hosted domains/IPs should switch variants in-place instead of jumping to worldmonitor.app.
  return !isOfficialWorldMonitorHost(host);
}

export const SITE_VARIANT: string = (() => {
  const envDefault = import.meta.env.VITE_VARIANT || 'full';
  if (typeof window === 'undefined') return envDefault;

  const host = window.location.hostname;
  if (host.startsWith('tech.')) return 'tech';
  if (host.startsWith('finance.')) return 'finance';
  if (host.startsWith('happy.')) return 'happy';

  if (shouldUseLocalVariantSwitch()) {
    return readStoredVariant() ?? envDefault;
  }

  return 'full';
})();
