// components/WavyBackground.tsx
export default function WavyBackground({ opacity = 0.3 }: { opacity?: number }) {
  return (
    <div className="absolute inset-0">
      <svg
        className="w-full h-full"
        preserveAspectRatio="none"
        viewBox="0 0 1440 200"
      >
        <path
          fill="var(--secondary)"
          fillOpacity={opacity}
          d="M0,96C240,32,480,128,720,96C960,64,1200,160,1440,96V200H0Z"
        >
          <animate
            attributeName="d"
            values="
              M0,96C240,32,480,128,720,96C960,64,1200,160,1440,96V200H0Z;
              M0,128C240,64,480,96,720,160C960,128,1200,64,1440,128V200H0Z;
              M0,96C240,32,480,128,720,96C960,64,1200,160,1440,96V200H0Z"
            dur="10s"
            repeatCount="indefinite"
          />
        </path>
      </svg>
    </div>
  );
}