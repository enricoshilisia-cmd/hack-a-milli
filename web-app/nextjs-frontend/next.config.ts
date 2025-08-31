/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'http',
        hostname: '172.166.222.31',
        port: '8000',
        pathname: '/media/company_logos/**',
      },
      {
        protocol: 'https',
        hostname: '172.166.222.31',
        port: '8000',
        pathname: '/media/company_logos/**',
      },
      {
        protocol: 'http',
        hostname: 'localhost',
        port: '8000',
        pathname: '/media/company_logos/**',
      },
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
      'http://localhost:3000',
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