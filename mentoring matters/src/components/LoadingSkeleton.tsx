import React from 'react';

interface LoadingSkeletonProps {
  type?: 'app' | 'dashboard' | 'compact';
}

export function LoadingSkeleton({ type = 'app' }: LoadingSkeletonProps) {
  const pulseAnimation = `
    @keyframes pulse {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.5; }
    }
  `;

  if (type === 'compact') {
    return (
      <div style={{
        display: 'flex',
        alignItems: 'center',
        gap: 8,
        padding: 16
      }}>
        <style>{pulseAnimation}</style>
        <div style={{
          width: 20,
          height: 20,
          background: '#e2e8f0',
          borderRadius: '50%',
          animation: 'pulse 1.5s ease-in-out infinite'
        }} />
        <div style={{
          width: 60,
          height: 14,
          background: '#e2e8f0',
          borderRadius: 4,
          animation: 'pulse 1.5s ease-in-out infinite'
        }} />
      </div>
    );
  }

  if (type === 'dashboard') {
    return (
      <div style={{
        minHeight: '100vh',
        display: 'flex',
        background: '#f8fafc'
      }}>
        <style>{pulseAnimation}</style>
        
        {/* Sidebar skeleton */}
        <div style={{
          width: 280,
          background: 'white',
          borderRight: '1px solid #e2e8f0',
          padding: 16
        }}>
          {/* Logo skeleton */}
          <div style={{
            height: 40,
            background: '#e2e8f0',
            borderRadius: 8,
            marginBottom: 24,
            animation: 'pulse 1.5s ease-in-out infinite'
          }} />
          
          {/* Nav items skeleton */}
          {[1, 2, 3, 4].map(i => (
            <div key={i} style={{
              height: 44,
              background: '#f1f5f9',
              borderRadius: 8,
              marginBottom: 8,
              animation: 'pulse 1.5s ease-in-out infinite',
              animationDelay: `${i * 0.1}s`
            }} />
          ))}
        </div>
        
        {/* Main content skeleton */}
        <div style={{ flex: 1, padding: 24 }}>
          {/* Header skeleton */}
          <div style={{
            height: 32,
            background: '#e2e8f0',
            borderRadius: 8,
            marginBottom: 24,
            animation: 'pulse 1.5s ease-in-out infinite'
          }} />
          
          {/* Content blocks */}
          {[1, 2, 3].map(i => (
            <div key={i} style={{
              height: 120,
              background: 'white',
              borderRadius: 12,
              marginBottom: 16,
              border: '1px solid #e2e8f0',
              animation: 'pulse 1.5s ease-in-out infinite',
              animationDelay: `${i * 0.2}s`
            }} />
          ))}
        </div>
      </div>
    );
  }

  // Default app loading skeleton
  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: '#f8fafc'
    }}>
      <style>{pulseAnimation}</style>
      <div style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 20
      }}>
        {/* Logo skeleton */}
        <div style={{
          width: 80,
          height: 80,
          background: '#e2e8f0',
          borderRadius: 16,
          animation: 'pulse 1.5s ease-in-out infinite'
        }} />
        
        {/* Text skeleton */}
        <div style={{
          width: 160,
          height: 20,
          background: '#e2e8f0',
          borderRadius: 10,
          animation: 'pulse 1.5s ease-in-out infinite',
          animationDelay: '0.2s'
        }} />
        
        {/* Subtitle skeleton */}
        <div style={{
          width: 120,
          height: 14,
          background: '#e2e8f0',
          borderRadius: 7,
          animation: 'pulse 1.5s ease-in-out infinite',
          animationDelay: '0.4s'
        }} />
      </div>
    </div>
  );
}