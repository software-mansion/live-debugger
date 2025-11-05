import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function getStorageValue(key: string, defaultValue: any) {
  if (typeof window !== "undefined") {
    const saved = localStorage.getItem(key);
    if (saved !== null && saved !== "undefined") {
      return saved;
    }
  }
  return defaultValue;
}
