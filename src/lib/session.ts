import type { AuthUser } from '../types';

const SESSION_KEY = 'hwang_family_user';

export function saveSession(user: AuthUser) {
  localStorage.setItem(SESSION_KEY, JSON.stringify(user));
}

export function getSession(): AuthUser | null {
  const raw = localStorage.getItem(SESSION_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as AuthUser;
  } catch {
    return null;
  }
}

export function clearSession() {
  localStorage.removeItem(SESSION_KEY);
}
