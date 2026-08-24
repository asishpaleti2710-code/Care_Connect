// Build an `{ [id]: item }` lookup from a list of API records.
export function indexById(items) {
  return (items || []).reduce((acc, item) => {
    acc[item.id] = item;
    return acc;
  }, {});
}

// Case-insensitive "does any of these fields contain the query" check for list filters.
export function matchesQuery(query, ...fields) {
  const needle = (query || '').toLowerCase();
  if (!needle) return true;
  return fields.some((field) => field && String(field).toLowerCase().includes(needle));
}
