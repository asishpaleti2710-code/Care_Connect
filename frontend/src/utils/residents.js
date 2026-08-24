// Pick the resident linked to the signed-in account, falling back to the first record.
export function findLinkedResident(residents, matches) {
  if (!residents || residents.length === 0) return null;
  return residents.find(matches) || residents[0];
}
