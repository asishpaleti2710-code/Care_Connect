import React from 'react';

export default function LoadingScreen({ message }) {
  return (
    <div style={{ textAlign: 'center', padding: '60px', color: '#94a3b8' }}>
      {message}
    </div>
  );
}
