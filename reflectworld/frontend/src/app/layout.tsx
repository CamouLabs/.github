import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "ReflectWorld",
  description: "A compassionate world model for your inner life",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
