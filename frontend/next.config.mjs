/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: "standalone",
  allowedDevOrigins: ["*.run.app"],
  devIndicators: false,
};

export default nextConfig;
