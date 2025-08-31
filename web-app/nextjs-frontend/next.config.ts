/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'api.skillproof.me.ke',
        pathname: '/media/company_logos/**',
      },
      {
        protocol: 'https',
        hostname: 'www.skillproof.me.ke',
        pathname: '/media/company_logos/**',
      },
    ],
  },
  experimental: {
    allowedDevOrigins: [
      'http://skillproof.me.ke',
      'https://skillproof.me.ke',
      'http://www.skillproof.me.ke',
      'https://www.skillproof.me.ke',
      'https://api.skillproof.me.ke',
    ],
    webpackHMR: true, // Enable HMR explicitly
  },
};

export default nextConfig;
