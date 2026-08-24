// Surface an API failure to the user with a consistent "<context>: <reason>" message.
export function alertError(context, err) {
  window.alert(`${context}: ${err?.message || 'Unknown error'}`);
}

// Log a non-blocking data-loading failure without interrupting the user.
export function logError(context, err) {
  console.error(`${context}:`, err);
}
