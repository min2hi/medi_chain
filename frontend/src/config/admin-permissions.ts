/**
 * Admin Portal — Permission Configuration
 *
 * Defines which roles can access each admin route.
 * Single source of truth — used by both sidebar filtering and page-level guards.
 *
 * Role hierarchy (highest → lowest):
 *   ADMIN   → full access
 *   DOCTOR  → clinical knowledge only (no system config/telemetry)
 */

export type AdminRole = 'ADMIN' | 'DOCTOR';

/** Routes with no explicit entry default to ADMIN-only */
export const ADMIN_PERMISSIONS: Record<string, AdminRole[]> = {
  '/admin/clinical-rules':          ['ADMIN', 'DOCTOR'],
  '/admin/clinical-rules/keywords': ['ADMIN', 'DOCTOR'],
  '/admin/clinical-rules/combos':   ['ADMIN', 'DOCTOR'],
  '/admin/telemetry':               ['ADMIN'],
  '/admin/config':                  ['ADMIN'],
};

/**
 * Check if a role has access to a given pathname.
 * Uses prefix matching so nested routes inherit parent permissions.
 */
export function canAccess(pathname: string, role: string): boolean {
  // Find the most specific matching route
  const matchedKey = Object.keys(ADMIN_PERMISSIONS)
    .filter(k => pathname === k || pathname.startsWith(k + '/'))
    .sort((a, b) => b.length - a.length)[0]; // longest match wins

  if (!matchedKey) return role === 'ADMIN'; // default: admin-only
  return (ADMIN_PERMISSIONS[matchedKey] as string[]).includes(role);
}

/** Filter nav items a role is allowed to see */
export function getAllowedRoutes(role: string): string[] {
  return Object.entries(ADMIN_PERMISSIONS)
    .filter(([, roles]) => (roles as string[]).includes(role))
    .map(([route]) => route);
}
