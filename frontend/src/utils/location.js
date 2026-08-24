// Fallback map location used whenever live browser geolocation is unavailable.
export const DEFAULT_LAT = 28.6139;
export const DEFAULT_LNG = 77.2090;
export const DEFAULT_CENTER = [DEFAULT_LAT, DEFAULT_LNG];

// Resolve coordinates from the geolocation hook (or a manual override) to the default center.
export function resolveCoords(...candidates) {
  const source = candidates.find((c) => c && c.lat != null && c.lng != null);
  return {
    lat: source ? source.lat : DEFAULT_LAT,
    lng: source ? source.lng : DEFAULT_LNG,
  };
}

// Deterministic marker offsets so pins without a geocode do not stack on one another.
export function scatterOffset(index, latSteps, lngSteps) {
  return {
    lat: latSteps[index % latSteps.length] * (index + 1),
    lng: lngSteps[index % lngSteps.length] * (index + 1),
  };
}
