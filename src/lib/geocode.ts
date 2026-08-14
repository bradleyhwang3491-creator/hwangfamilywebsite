export interface GeocodeResult {
  lat: number;
  lng: number;
  country: string | null;
  isDomestic: boolean;
}

const DOMESTIC_COUNTRY_NAMES = new Set(['대한민국', 'South Korea', 'Republic of Korea']);

export async function geocodeAddress(address: string): Promise<GeocodeResult | null> {
  const url = `https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&limit=1&accept-language=ko&q=${encodeURIComponent(address)}`;
  const res = await fetch(url);
  if (!res.ok) return null;

  const results = await res.json();
  const hit = results?.[0];
  if (!hit) return null;

  const country = hit.address?.country ?? null;
  return {
    lat: Number(hit.lat),
    lng: Number(hit.lon),
    country,
    isDomestic: country ? DOMESTIC_COUNTRY_NAMES.has(country) : false,
  };
}
